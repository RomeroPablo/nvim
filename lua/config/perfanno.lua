local M = {}

local state = {
	status = "idle",
	data_file = nil,
	load_running = false,
	watchers = {},
	reload_timer = nil,
	cursor_cache = nil,
	last_error = nil,
}

local function candidate_paths()
	local cwd = vim.fn.getcwd()

	return {
		vim.fs.joinpath(cwd, ".artifacts", "perf.data"),
		vim.fs.joinpath(cwd, "perf.data"),
		vim.fs.joinpath(vim.fs.dirname(cwd), ".artifacts", "perf.data"),
	}
end

local function find_perf_data()
	for _, path in ipairs(candidate_paths()) do
		if vim.uv.fs_stat(path) then
			return path
		end
	end

	return nil
end

local flamegraph_image_extensions = {
	avif = true,
	gif = true,
	jpeg = true,
	jpg = true,
	png = true,
	svg = true,
	webp = true,
}

local flamegraph_browser_extensions = {
	htm = true,
	html = true,
}

local function artifact_dirs()
	local cwd = vim.fn.getcwd()
	local roots = {
		cwd,
		vim.fs.dirname(cwd),
		vim.fs.root(0, { ".git", "CMakeLists.txt", "Makefile" }),
	}
	local dirs = {}
	local seen = {}

	for _, root in ipairs(roots) do
		if root then
			local dir = vim.fs.joinpath(root, ".artifacts")
			if not seen[dir] then
				seen[dir] = true
				table.insert(dirs, dir)
			end
		end
	end

	return dirs
end

local function flamegraph_extension(path)
	return path:lower():match("%.([^.]+)$")
end

local function find_flamegraph(extensions)
	local matches = {}
	extensions = extensions or vim.tbl_extend("force", flamegraph_image_extensions, flamegraph_browser_extensions)

	for _, dir in ipairs(artifact_dirs()) do
		if vim.uv.fs_stat(dir) then
			vim.list_extend(matches, vim.fs.find(function(name, path)
				local extension = flamegraph_extension(name)
				local stat = vim.uv.fs_stat(vim.fs.joinpath(path, name))
				return name:lower():find("flame", 1, true)
					and extensions[extension]
					and stat
					and stat.type == "file"
			end, { path = dir, type = "file", limit = math.huge }))
		end
	end

	table.sort(matches, function(left, right)
		local left_stat = vim.uv.fs_stat(left)
		local right_stat = vim.uv.fs_stat(right)
		return (left_stat and left_stat.mtime.sec or 0) > (right_stat and right_stat.mtime.sec or 0)
	end)

	return matches[1]
end

local function missing_flamegraph_message()
	return "No flamegraph image or HTML file found in " .. table.concat(artifact_dirs(), ", ")
end

local function prompt_perf_data()
	local default_path = candidate_paths()[1]
	return vim.fn.input("Path to perf.data: ", default_path, "file")
end

local function parse_callgraph_output(output)
	local traces = {}
	local current_event

	for _, line in ipairs(vim.split(output, "\n")) do
		local _, event = line:match("# Samples: (%d+[KMB]?)%s+of event '(.*)'")

		if event then
			traces[event] = {}
			current_event = event
		else
			local count, traceline = line:match("^(%d+) (.*)$")

			if current_event and count and traceline and tonumber(count) > 0 then
				local tracedata = { count = tonumber(count), frames = {} }

				for func in traceline:gmatch("[^;]+") do
					local symbol, file, linenr = func:match("^(.-)%s*(/.*):(%d+)")

					if file and linenr then
						if symbol == "" then
							symbol = nil
						end

						table.insert(tracedata.frames, {
							symbol = symbol,
							file = file,
							linenr = tonumber(linenr),
						})
					else
						table.insert(tracedata.frames, { symbol = func })
					end
				end

				table.insert(traces[current_event], tracedata)
			end
		end
	end

	return traces
end

local function redraw_statusline()
	vim.cmd.redrawstatus()
end

local function clear_cursor_cache()
	state.cursor_cache = nil
end

local function set_status(status)
	state.status = status
	clear_cursor_cache()
	redraw_statusline()
end

local function close_watchers()
	for _, watcher in ipairs(state.watchers) do
		watcher:stop()
		watcher:close()
	end

	state.watchers = {}
end

local function schedule_auto_load()
	if state.reload_timer then
		state.reload_timer:stop()
		state.reload_timer:close()
	end

	state.reload_timer = vim.uv.new_timer()
	state.reload_timer:start(750, 0, function()
		vim.schedule(function()
			M.ensure_plugin_loaded(true)
			if package.loaded["perfanno"] then
				M.load_callgraph_async({ silent = true, prompt = false })
			end
		end)
	end)
end

local function watch_dirs()
	close_watchers()

	local watched = {}
	for _, path in ipairs(candidate_paths()) do
		local dir = vim.fs.dirname(path)
		local basename = vim.fs.basename(path)

		if dir and basename and not watched[dir] and vim.uv.fs_stat(dir) then
			watched[dir] = true

			local watcher = vim.uv.new_fs_event()
			watcher:start(dir, {}, function(err, filename)
				if err or filename ~= basename then
					return
				end

				schedule_auto_load()
			end)

			table.insert(state.watchers, watcher)
		end
	end
end

local default_event

local function current_callgraph()
	local callgraph = package.loaded["perfanno.callgraph"]
	local config = package.loaded["perfanno.config"]

	if not callgraph or not config or not callgraph.is_loaded() then
		return nil, nil, nil
	end

	local event = config.selected_event
	if not event or not callgraph.callgraphs[event] then
		event = default_event(callgraph.events)
		config.selected_event = event
	end

	return callgraph.callgraphs[event], config, event
end

local function normalized_event(event)
	return event
		:gsub("^cpu/", "")
		:gsub("/.*$", "")
		:gsub(":[%w_%-]+$", "")
end

default_event = function(events)
	local fallback = vim.deepcopy(events)
	table.sort(fallback)

	for _, event in ipairs(fallback) do
		if normalized_event(event) == "cycles" then
			return event
		end
	end

	for _, event in ipairs(fallback) do
		if normalized_event(event):match("cycles") then
			return event
		end
	end

	return fallback[1]
end

local function buffer_file(bufnr)
	local file = vim.api.nvim_buf_get_name(bufnr)
	return vim.uv.fs_realpath(file) or file
end

local function current_function_range()
	local treesitter = package.loaded["perfanno.treesitter"]
	if not treesitter then
		return nil, nil
	end

	local ok, start_line, end_line = pcall(treesitter.get_function_lines)
	if not ok then
		return nil, nil
	end

	return start_line, end_line
end

local function event_label(event)
	if not event then
		return "none"
	end

	return normalized_event(event):gsub("[-_]", " ")
end

function M.find_perf_data()
	return find_perf_data()
end

function M.find_flamegraph()
	return find_flamegraph()
end

function M.open_flamegraph()
	local path = find_flamegraph(flamegraph_image_extensions) or find_flamegraph(flamegraph_browser_extensions)
	if not path then
		vim.notify(missing_flamegraph_message(), vim.log.levels.WARN)
		return
	end

	local extension = flamegraph_extension(path)
	if flamegraph_browser_extensions[extension] then
		vim.notify("HTML flamegraphs require a browser; opening " .. path, vim.log.levels.INFO)
		vim.ui.open(path)
		return
	end

	local ok, lazy = pcall(require, "lazy")
	if ok then
		lazy.load({ plugins = { "image.nvim" } })
	end

	if not pcall(require, "image") then
		vim.notify("image.nvim is unavailable; cannot preview " .. path, vim.log.levels.ERROR)
		return
	end

	vim.cmd.tabedit(vim.fn.fnameescape(path))
end

function M.open_flamegraph_external()
	local path = find_flamegraph()
	if not path then
		vim.notify(missing_flamegraph_message(), vim.log.levels.WARN)
		return
	end

	vim.ui.open(path)
end

function M.ensure_plugin_loaded(silent)
	if package.loaded["perfanno"] then
		return
	end

	local ok, lazy = pcall(require, "lazy")
	if not ok then
		return
	end

	local loaded = pcall(lazy.load, { plugins = { "perfanno.nvim" } })
	if not loaded and not silent then
		vim.notify("Could not load perfanno.nvim", vim.log.levels.WARN)
	end
end

function M.start_auto_load()
	watch_dirs()

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "DirChanged" }, {
		group = vim.api.nvim_create_augroup("perfanno-auto-load", { clear = true }),
		callback = function()
			watch_dirs()

			local data_file = find_perf_data()
			if not data_file then
				return
			end

			if vim.g.perfanno_auto_load_started and vim.g.perfanno_auto_data_file == data_file then
				return
			end

			vim.g.perfanno_auto_load_started = true
			vim.g.perfanno_auto_data_file = data_file
			vim.g.perfanno_auto_load_requested = true

			vim.schedule(function()
				M.ensure_plugin_loaded(true)
				if package.loaded["perfanno"] then
					M.load_callgraph_async({ silent = true, prompt = false })
				end
			end)
		end,
	})
end

function M.load_callgraph_async(opts)
	opts = opts or {}

	if state.load_running then
		if not opts.silent then
			vim.notify("Perf callgraph load is already running.", vim.log.levels.INFO)
		end
		return
	end

	local data_file = find_perf_data()
	if not data_file and opts.prompt ~= false then
		data_file = prompt_perf_data()
	end

	if not data_file or data_file == "" then
		return
	end

	state.data_file = data_file
	state.load_running = true
	set_status(state.status == "loaded" and "reloading" or "loading")

	if not opts.silent then
		vim.notify("Loading perf callgraph in background: " .. data_file)
	end

	vim.system({
		"perf",
		"report",
		"-g",
		"folded,0,caller,srcline,branch,count",
		"--no-children",
		"--full-source-path",
		"--stdio",
		"-i",
		data_file,
	}, { text = true }, function(result)
		vim.schedule(function()
			state.load_running = false

			if result.code ~= 0 then
				state.last_error = result.stderr ~= "" and result.stderr or "perf report failed"
				set_status("error")

				if not opts.silent then
					vim.notify(state.last_error, vim.log.levels.ERROR)
				end
				return
			end

			local traces = parse_callgraph_output(result.stdout or "")
			if vim.tbl_isempty(traces) then
				state.last_error = "No perf callgraph traces were parsed."
				set_status("error")

				if not opts.silent then
					vim.notify(state.last_error, vim.log.levels.WARN)
				end
				return
			end

			local callgraph = require("perfanno.callgraph")
			local config = require("perfanno.config")

			callgraph.load_traces(traces)
			if callgraph.is_loaded() then
				config.selected_event = default_event(callgraph.events)

				if config.values.annotate_after_load then
					require("perfanno.annotate").annotate(config.selected_event)
				end
			end

			state.last_error = nil
			set_status("loaded")

			if not opts.silent then
				vim.notify("Perf callgraph has been loaded.")
			end
		end)
	end)
end

function M.toggle_annotations()
	local annotate = require("perfanno.annotate")
	if annotate.is_toggled() then
		annotate.clear()
		clear_cursor_cache()
		redraw_statusline()
		return
	end

	local callgraph, config, event = current_callgraph()
	if not callgraph then
		vim.notify("No perfanno callgraph loaded.", vim.log.levels.WARN)
		return
	end

	annotate.annotate(event)
	clear_cursor_cache()
	redraw_statusline()
end

function M.setup(perfanno, util)
	perfanno.setup({
		line_highlights = util.make_bg_highlights(nil, "#cc3300", 10),
		vt_highlight = util.make_fg_highlight("#cc3300"),
		formats = {
			{ percent = true, format = "%.2f%%", minimum = 0.1 },
			{ percent = false, format = "%d", minimum = 1 },
		},
		annotate_after_load = true,
		annotate_on_open = true,
		telescope = {
			enabled = pcall(require, "telescope"),
			annotate = true,
		},
		fzf_lua = {
			enabled = false,
			annotate = false,
		},
		get_path_callback = function()
			return find_perf_data() or prompt_perf_data()
		end,
		thread_support = false,
	})

	pcall(vim.api.nvim_del_user_command, "PerfLoadCallGraph")
	vim.api.nvim_create_user_command("PerfLoadCallGraph", function()
		M.load_callgraph_async({ silent = false, prompt = true })
	end, {})

	pcall(vim.api.nvim_del_user_command, "PerfCycleFormat")
	vim.api.nvim_create_user_command("PerfCycleFormat", function()
		perfanno.cycle_format()
		clear_cursor_cache()
		redraw_statusline()
	end, {})

	if vim.g.perfanno_auto_load_requested or find_perf_data() then
		vim.schedule(function()
			M.load_callgraph_async({ silent = true, prompt = false })
		end)
	end
end

function M.statusline()
	if state.status ~= "loaded" then
		return ""
	end

	local callgraph, config, event = current_callgraph()
	if not callgraph then
		return ""
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local cache_key = table.concat({
		bufnr,
		line,
		event,
		vim.api.nvim_buf_get_changedtick(bufnr),
	}, ":")

	if state.cursor_cache and state.cursor_cache.key == cache_key then
		return state.cursor_cache.text
	end

	local file = buffer_file(bufnr)
	local file_info = callgraph.node_info[file]
	local line_count = file_info and file_info[line] and file_info[line].count or 0
	local fn_count = 0
	local start_line, end_line = current_function_range()

	if file_info and start_line and end_line then
		for linenr = start_line, end_line do
			local info = file_info[linenr]
			if info then
				fn_count = fn_count + info.count
			end
		end
	end

	local text = string.format(
		"%s  Line %d/%d  Function %d",
		event_label(event),
		line_count,
		callgraph.total_count or 0,
		fn_count
	)

	state.cursor_cache = {
		key = cache_key,
		text = text,
	}

	return text
end

function M.statusline_parts()
	local text = M.statusline()
	if text == "" then
		return nil
	end

	local event, line, total, func = text:match("^(.-)  Line (%d+)/(%d+)  Function (%d+)$")
	if not event then
		return nil
	end

	return {
		event = event,
		line = line,
		total = total,
		func = func,
	}
end

return M
