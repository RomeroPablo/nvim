return {
	"t-troebst/perfanno.nvim",
	init = function()
		require("config.perfanno").start_auto_load()
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
		{ "<Leader>plo", require("config.perfanno").open_flamegraph, desc = "Open flamegraph in Neovim" },
		{ "<Leader>plO", require("config.perfanno").open_flamegraph_external, desc = "Open interactive flamegraph" },
		{ "<Leader>pe", "<cmd>PerfPickEvent<CR>", desc = "Pick perf event" },
		{ "<Leader>pF", "<cmd>PerfCycleFormat<CR>", desc = "Cycle perf format" },
		{ "<Leader>pa", "<cmd>PerfAnnotate<CR>", desc = "Annotate perf data" },
		{ "<Leader>pf", "<cmd>PerfAnnotateFunction<CR>", desc = "Annotate perf function" },
		{ "<Leader>pa", "<cmd>PerfAnnotateSelection<CR>", mode = "v", desc = "Annotate perf selection" },
		{ "<Leader>pt", require("config.perfanno").toggle_annotations, desc = "Toggle perf annotations" },
		{ "<Leader>ph", "<cmd>PerfHottestLines<CR>", desc = "Perf hottest lines" },
		{ "<Leader>ps", "<cmd>PerfHottestSymbols<CR>", desc = "Perf hottest symbols" },
		{ "<Leader>pc", "<cmd>PerfHottestCallersFunction<CR>", desc = "Perf hottest callers" },
		{ "<Leader>pc", "<cmd>PerfHottestCallersSelection<CR>", mode = "v", desc = "Perf selection callers" },
	},
	config = function()
		local perfanno = require("perfanno")

		require("config.perfanno").setup(perfanno)

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
