return {
	"slugbyte/lackluster.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local lackluster = require("lackluster")

		lackluster.setup({
			tweak_background = {
				normal = "none",
				telescope = "none",
			},
		})

		vim.cmd.colorscheme("lackluster-night")
	end,
}
