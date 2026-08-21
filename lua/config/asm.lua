local M = {}

local state = {
	bufnr = nil,
	winid = nil,
	source_winid = nil,
	binary = nil,
	binary_mtime = nil,
	loading = false,
	index = {},
	row_to_source = {},
	sorted_lines = {},
	source_snapshots = {},
	ood = false,
	ood_reason = nil,
	syncing = false,
	source_highlight_bufnr = nil,
}

local asm_namespace = vim.api.nvim_create_namespace("asm-view-current-line")
local source_namespace = vim.api.nvim_create_namespace("asm-view-source-line")

local function artifact_dirs()
	local cwd = vim.fn.getcwd()

	return {
		vim.fs.joinpath(cwd, ".artifacts"),
		cwd,
		vim.fs.joinpath(vim.fs.dirname(cwd), ".artifacts"),
	}
end

local function executable_in_dir(dir)
	local handle = vim.uv.fs_scandir(dir)
	if not handle then
		return nil
	end

	local best
	while true do
		local name, kind = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end

		local path = vim.fs.joinpath(dir, name)
		local stat = vim.uv.fs_stat(path)
		if kind == "file" and stat and vim.fn.executable(path) == 1 then
			if not best or stat.mtime.sec > best.mtime then
				best = { path = path, mtime = stat.mtime.sec }
			end
		end
	end

	return best
end

local function find_binary()
	for _, dir in ipairs(artifact_dirs()) do
		local stat = vim.uv.fs_stat(dir)
		if stat and stat.type == "directory" then
			local executable = executable_in_dir(dir)
			if executable then
				return executable.path, executable.mtime
			end
		end
	end

	return nil, nil
end

local function ensure_buffer()
	if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
		return state.bufnr
	end

	state.bufnr = vim.api.nvim_create_buf(false, true)
	vim.bo[state.bufnr].bufhidden = "hide"
	vim.bo[state.bufnr].buftype = "nofile"
	vim.bo[state.bufnr].filetype = "asm"
	vim.bo[state.bufnr].modifiable = false
	vim.api.nvim_buf_set_name(state.bufnr, "asm://objdump")

	return state.bufnr
end

local function set_buffer_lines(lines)
	local bufnr = ensure_buffer()
	vim.bo[bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
end

local function source_snapshot(file)
	local stat = vim.uv.fs_stat(file)
	if not stat then
		return nil
	end

	local ok, lines = pcall(io.lines, file)
	if not ok then
		return nil
	end

	local line_count = 0
	for _ in lines do
		line_count = line_count + 1
	end

	return {
		mtime = stat.mtime.sec,
		size = stat.size,
		line_count = line_count,
	}
end

local function snapshot_source(file)
	if not state.source_snapshots[file] then
		state.source_snapshots[file] = source_snapshot(file)
		if
			state.source_snapshots[file]
			and state.binary_mtime
			and state.source_snapshots[file].mtime > state.binary_mtime
		then
			state.ood = true
			state.ood_reason = "source file is newer than the binary"
		end
	end
end

local function out_of_date_lines(reason)
	return {
		"; OUT OF DATE: " .. reason,
		"; Rebuild and reopen <Leader>aa for exact source-to-assembly sync.",
		"",
	}
end

local function is_source_stale(bufnr, file)
	if vim.bo[bufnr].modified then
		return true
	end

	local loaded = state.source_snapshots[file]
	local current = source_snapshot(file)
	if not loaded or not current then
		return false
	end

	return loaded.mtime ~= current.mtime
		or loaded.size ~= current.size
		or loaded.line_count ~= current.line_count
end

local function mark_out_of_date(reason)
	if state.ood then
		return
	end

	state.ood = true
	state.ood_reason = reason
	local bufnr = ensure_buffer()
	vim.bo[bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, out_of_date_lines(reason))
	vim.bo[bufnr].modifiable = false
end

local function build_display(lines)
	state.index = {}
	state.row_to_source = {}
	state.sorted_lines = {}
	state.source_snapshots = {}
	state.ood = false
	state.ood_reason = nil

	local display_lines = {}
	local pending_locations = {}
	local current_location

	local function map_pending_locations(row)
		for _, location in ipairs(pending_locations) do
			state.index[location.file] = state.index[location.file] or {}
			state.sorted_lines[location.file] = state.sorted_lines[location.file] or {}

			if not state.index[location.file][location.line] then
				state.index[location.file][location.line] = row
				table.insert(state.sorted_lines[location.file], location.line)
			end
		end

		pending_locations = {}
	end

	for _, text in ipairs(lines) do
		local file, line = text:match("^;%s+(.+):(%d+)$")
		if file and vim.startswith(file, "/") then
			local real_file = vim.uv.fs_realpath(file) or file
			local linenr = tonumber(line)
			snapshot_source(real_file)
			table.insert(pending_locations, { file = real_file, line = linenr })
		elseif text:match("^;") then
			-- Source interleave comments are useful for indexing, but too noisy to display.
		else
			table.insert(display_lines, text)
			if text:match("^%s*[%da-fA-F]+:") then
				if #pending_locations > 0 then
					current_location = pending_locations[#pending_locations]
				end
				map_pending_locations(#display_lines)
				if current_location then
					state.row_to_source[#display_lines] = current_location
				end
			end
		end
	end

	for _, linenrs in pairs(state.sorted_lines) do
		table.sort(linenrs)
	end

	if state.ood then
		local prefixed_lines = out_of_date_lines(state.ood_reason or "source differs from compiled code")
		vim.list_extend(prefixed_lines, display_lines)
		display_lines = prefixed_lines
	end

	return display_lines
end

local function asm_row_for_source(file, line)
	local by_line = state.index[file]
	if not by_line then
		return nil
	end

	local row = by_line[line]
	local best_line
	if not row then
		for _, linenr in ipairs(state.sorted_lines[file] or {}) do
			if linenr <= line then
				best_line = linenr
			else
				break
			end
		end

		if not best_line then
			best_line = (state.sorted_lines[file] or {})[1]
		end

		row = best_line and by_line[best_line] or nil
	end

	if row and state.ood then
		row = row + 3
	end

	return row
end

local function source_for_asm_row(row)
	if state.ood then
		row = row - 3
	end

	if state.row_to_source[row] then
		return state.row_to_source[row]
	end

	for candidate = row - 1, 1, -1 do
		if state.row_to_source[candidate] then
			return state.row_to_source[candidate]
		end
	end

	return nil
end

local function highlight_asm_row(row)
	vim.api.nvim_buf_clear_namespace(state.bufnr, asm_namespace, 0, -1)

	vim.api.nvim_buf_set_extmark(state.bufnr, asm_namespace, row - 1, 0, {
		hl_group = "AsmViewCurrentLine",
		hl_eol = true,
	})
end

local function highlight_source_line(bufnr, line)
	if
		state.source_highlight_bufnr
		and state.source_highlight_bufnr ~= bufnr
		and vim.api.nvim_buf_is_valid(state.source_highlight_bufnr)
	then
		vim.api.nvim_buf_clear_namespace(state.source_highlight_bufnr, source_namespace, 0, -1)
	end

	state.source_highlight_bufnr = bufnr
	vim.api.nvim_buf_clear_namespace(bufnr, source_namespace, 0, -1)

	vim.api.nvim_buf_set_extmark(bufnr, source_namespace, line - 1, 0, {
		hl_group = "AsmViewSourceLine",
		hl_eol = true,
	})
end

local function source_window()
	if state.source_winid and vim.api.nvim_win_is_valid(state.source_winid) then
		return state.source_winid
	end

	for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(winid) ~= state.bufnr then
			state.source_winid = winid
			return winid
		end
	end

	return nil
end

local function ensure_window()
	local bufnr = ensure_buffer()

	if state.winid and vim.api.nvim_win_is_valid(state.winid) then
		return state.winid
	end

	local source_winid = vim.api.nvim_get_current_win()
	state.source_winid = source_winid

	vim.cmd("botright vertical 80split")
	state.winid = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.winid, bufnr)
	vim.wo[state.winid].wrap = false
	vim.wo[state.winid].number = false
	vim.wo[state.winid].relativenumber = false
	vim.wo[state.winid].cursorline = true
	vim.wo[state.winid].signcolumn = "no"
	vim.bo[bufnr].buflisted = false

	vim.api.nvim_set_current_win(source_winid)
	return state.winid
end

local function follow_asm_from_source()
	if state.syncing then
		return
	end

	if not state.winid or not vim.api.nvim_win_is_valid(state.winid) then
		return
	end

	local source_bufnr = vim.api.nvim_get_current_buf()
	if source_bufnr == state.bufnr then
		return
	end

	state.source_winid = vim.api.nvim_get_current_win()

	local source_file = vim.api.nvim_buf_get_name(source_bufnr)
	if source_file == "" then
		return
	end

	local real_file = vim.uv.fs_realpath(source_file) or source_file
	if is_source_stale(source_bufnr, real_file) then
		mark_out_of_date("source buffer differs from the binary debug line info")
	end

	local source_line = vim.api.nvim_win_get_cursor(0)[1]
	local row = asm_row_for_source(real_file, source_line)
	if not row then
		return
	end

	highlight_source_line(source_bufnr, source_line)
	highlight_asm_row(row)

	state.syncing = true
	vim.api.nvim_win_set_cursor(state.winid, { row, 0 })
	vim.api.nvim_win_call(state.winid, function()
		vim.cmd("normal! zz")
	end)
	state.syncing = false
end

local function follow_source_from_asm()
	if state.syncing then
		return
	end

	if not state.winid or not vim.api.nvim_win_is_valid(state.winid) then
		return
	end

	if vim.api.nvim_get_current_buf() ~= state.bufnr then
		return
	end

	local row = vim.api.nvim_win_get_cursor(state.winid)[1]
	local location = source_for_asm_row(row)
	if not location then
		return
	end

	local winid = source_window()
	if not winid then
		return
	end

	state.syncing = true
	vim.api.nvim_win_call(winid, function()
		local current_file = vim.api.nvim_buf_get_name(0)
		local real_current = current_file ~= "" and (vim.uv.fs_realpath(current_file) or current_file) or ""
		if real_current ~= location.file then
			vim.cmd.edit(vim.fn.fnameescape(location.file))
		end

		local bufnr = vim.api.nvim_get_current_buf()
		if is_source_stale(bufnr, location.file) then
			mark_out_of_date("source file differs from the binary debug line info")
		end

		local line_count = vim.api.nvim_buf_line_count(bufnr)
		local line = math.min(location.line, line_count)
		vim.api.nvim_win_set_cursor(0, { line, 0 })
		highlight_source_line(bufnr, line)
		vim.cmd("normal! zz")
	end)
	highlight_asm_row(row)
	state.syncing = false
end

local function load_disassembly()
	local binary, mtime = find_binary()
	if not binary then
		set_buffer_lines({ "No executable found in .artifacts/ or cwd." })
		return
	end

	if state.binary == binary and state.binary_mtime == mtime and next(state.index) ~= nil then
		follow_asm_from_source()
		return
	end

	if state.loading then
		return
	end

	state.loading = true
	state.binary = binary
	state.binary_mtime = mtime
	set_buffer_lines({ "Loading assembly for " .. binary .. " ..." })

	vim.system({
		"llvm-objdump",
		"-d",
		"-S",
		"--line-numbers",
		"--demangle",
		binary,
	}, { text = true }, function(result)
		vim.schedule(function()
			state.loading = false

			if result.code ~= 0 then
				local message = result.stderr ~= "" and result.stderr or "llvm-objdump failed"
				set_buffer_lines(vim.split(message, "\n"))
				return
			end

			local lines = vim.split(result.stdout or "", "\n")
			local display_lines = build_display(lines)
			set_buffer_lines(display_lines)
			follow_asm_from_source()
		end)
	end)
end

function M.toggle()
	if state.winid and vim.api.nvim_win_is_valid(state.winid) then
		vim.api.nvim_win_close(state.winid, true)
		state.winid = nil
		if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
			vim.api.nvim_buf_clear_namespace(state.bufnr, asm_namespace, 0, -1)
		end
		if state.source_highlight_bufnr and vim.api.nvim_buf_is_valid(state.source_highlight_bufnr) then
			vim.api.nvim_buf_clear_namespace(state.source_highlight_bufnr, source_namespace, 0, -1)
		end
		return
	end

	ensure_window()
	load_disassembly()
end

vim.api.nvim_set_hl(0, "AsmViewCurrentLine", { link = "Visual" })
vim.api.nvim_set_hl(0, "AsmViewSourceLine", { link = "Visual" })

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("asm-view-follow", { clear = true }),
	callback = function()
		if state.winid and vim.api.nvim_win_is_valid(state.winid) then
			if vim.api.nvim_get_current_buf() == state.bufnr then
				follow_source_from_asm()
			else
				follow_asm_from_source()
			end
		end
	end,
})

return M
