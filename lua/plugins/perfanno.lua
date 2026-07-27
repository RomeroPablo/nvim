return {
	"t-troebst/perfanno.nvim",
	init = function()
		local function has_perf_data()
			local cwd = vim.fn.getcwd()
			local candidates = {
				vim.fs.joinpath(cwd, ".artifacts", "perf.data"),
				vim.fs.joinpath(cwd, "perf.data"),
				vim.fs.joinpath(vim.fs.dirname(cwd), ".artifacts", "perf.data"),
			}

			for _, path in ipairs(candidates) do
				if vim.uv.fs_stat(path) then
					return true
				end
			end

			return false
		end

		vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
			group = vim.api.nvim_create_augroup("perfanno-auto-load", { clear = true }),
			callback = function()
				if vim.g.perfanno_auto_load_started or not has_perf_data() then
					return
				end

				vim.g.perfanno_auto_load_started = true
				vim.g.perfanno_auto_load_requested = true

				vim.schedule(function()
					require("lazy").load({ plugins = { "perfanno.nvim" } })
				end)
			end,
		})
	end,
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	cmd = {
		"PerfLoadFlat",
		"PerfLoadCallGraph",
		"PerfLoadFlameGraph",
		"PerfLuaProfileStart",
		"PerfLuaProfileStop",
		"PerfPickEvent",
		"PerfCycleFormat",
		"PerfAnnotate",
		"PerfAnnotateFunction",
		"PerfAnnotateSelection",
		"PerfToggleAnnotations",
		"PerfHottestLines",
		"PerfHottestSymbols",
		"PerfHottestCallersFunction",
		"PerfHottestCallersSelection",
		"PerfCacheSave",
		"PerfCacheLoad",
		"PerfCacheDelete",
	},
	keys = {
		{ "<Leader>plf", "<cmd>PerfLoadFlat<CR>", desc = "Load flat perf data" },
		{ "<Leader>plg", "<cmd>PerfLoadCallGraph<CR>", desc = "Load perf call graph" },
		{ "<Leader>plo", "<cmd>PerfLoadFlameGraph<CR>", desc = "Load flame graph data" },
		{ "<Leader>pe", "<cmd>PerfPickEvent<CR>", desc = "Pick perf event" },
		{ "<Leader>pF", "<cmd>PerfCycleFormat<CR>", desc = "Cycle perf format" },
		{ "<Leader>pa", "<cmd>PerfAnnotate<CR>", desc = "Annotate perf data" },
		{ "<Leader>pf", "<cmd>PerfAnnotateFunction<CR>", desc = "Annotate perf function" },
		{ "<Leader>pa", "<cmd>PerfAnnotateSelection<CR>", mode = "v", desc = "Annotate perf selection" },
		{
			"<Leader>pt",
			function()
				local annotate = require("perfanno.annotate")
				if annotate.is_toggled() then
					annotate.clear()
					return
				end

				local callgraph = require("perfanno.callgraph")
				if not callgraph.is_loaded() then
					vim.notify("No perfanno callgraph loaded. Run :PerfLoadCallGraph first.", vim.log.levels.WARN)
					return
				end

				local config = require("perfanno.config")
				if not config.selected_event or not callgraph.callgraphs[config.selected_event] then
					config.selected_event = callgraph.events[1]
				end

				annotate.annotate(config.selected_event)
			end,
			desc = "Toggle perf annotations",
		},
		{ "<Leader>ph", "<cmd>PerfHottestLines<CR>", desc = "Perf hottest lines" },
		{ "<Leader>ps", "<cmd>PerfHottestSymbols<CR>", desc = "Perf hottest symbols" },
		{ "<Leader>pc", "<cmd>PerfHottestCallersFunction<CR>", desc = "Perf hottest callers" },
		{ "<Leader>pc", "<cmd>PerfHottestCallersSelection<CR>", mode = "v", desc = "Perf selection callers" },
	},
	config = function()
		local perfanno = require("perfanno")
		local util = require("perfanno.util")

		local function perf_data_path(opts)
			opts = opts or {}

			local cwd = vim.fn.getcwd()
			local candidates = {
				vim.fs.joinpath(cwd, ".artifacts", "perf.data"),
				vim.fs.joinpath(cwd, "perf.data"),
				vim.fs.joinpath(vim.fs.dirname(cwd), ".artifacts", "perf.data"),
			}

			for _, path in ipairs(candidates) do
				if vim.uv.fs_stat(path) then
					return path
				end
			end

			if opts.prompt == false then
				return nil
			end

			return vim.fn.input("Path to perf.data: ", candidates[1], "file")
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

		local perf_load_running = false
		local function finish_load(traces, opts)
			opts = opts or {}

			if opts.silent then
				local callgraph = require("perfanno.callgraph")
				local config = require("perfanno.config")

				callgraph.load_traces(traces)
				if callgraph.is_loaded() then
					config.selected_event = callgraph.events[1]

					if config.values.annotate_after_load then
						require("perfanno.annotate").annotate(config.selected_event)
					end
				end
				return
			end

			perfanno.load_traces(traces)
		end

		local function load_callgraph_async(opts)
			opts = opts or {}

			if perf_load_running then
				if not opts.silent then
					vim.notify("Perf callgraph load is already running.", vim.log.levels.INFO)
				end
				return
			end

			local data_file = perf_data_path({ prompt = not opts.silent })
			if not data_file or data_file == "" then
				return
			end

			perf_load_running = true
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
					perf_load_running = false

					if result.code ~= 0 then
						if not opts.silent then
							local message = result.stderr ~= "" and result.stderr or "perf report failed"
							vim.notify(message, vim.log.levels.ERROR)
						end
						return
					end

					local traces = parse_callgraph_output(result.stdout or "")
					if vim.tbl_isempty(traces) then
						if not opts.silent then
							vim.notify("No perf callgraph traces were parsed.", vim.log.levels.WARN)
						end
						return
					end

					finish_load(traces, opts)
				end)
			end)
		end

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
				return perf_data_path()
			end,
			thread_support = false,
		})

		pcall(vim.api.nvim_del_user_command, "PerfLoadCallGraph")
		vim.api.nvim_create_user_command("PerfLoadCallGraph", load_callgraph_async, {})

		if vim.g.perfanno_auto_load_requested then
			vim.schedule(function()
				load_callgraph_async({ silent = true })
			end)
		end

		local has_telescope, telescope = pcall(require, "telescope")
		if has_telescope then
			local actions = require("telescope").extensions.perfanno.actions

			telescope.setup({
				extensions = {
					perfanno = {
						mappings = {
							i = {
								["<C-h>"] = actions.hottest_callers,
								["<C-l>"] = actions.hottest_callees,
							},
							n = {
								gu = actions.hottest_callers,
								gd = actions.hottest_callees,
							},
						},
					},
				},
			})
		end
	end,
}
