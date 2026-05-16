return {
    "nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = "Telescope",
	keys = {
		{ "<Leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
		{ "<Leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
		{ "<Leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
		{ "<Leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
	},
	config = function()
		require("telescope").setup({
			defaults = {
				prompt_prefix = "🔍 ",
				selection_caret = " ",
				path_display = { "smart" },
				layout_strategy = "horizontal",
				layout_config = {
					prompt_position = "top",
					preview_width = 0.6,
				},
				sorting_strategy = "ascending",
			},
			pickers = {
				find_files = {
					hidden = false,
				},
				live_grep = {
					additional_args = function()
						return { "--hidden" }
					end,
				},
			},
		})
	end,
}
