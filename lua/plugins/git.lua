return {
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		cmd = "Neogit",
		keys = {
			{ "<Leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
			{ "<Leader>gc", "<cmd>Neogit commit<CR>", desc = "Git commit" },
			{ "<Leader>gl", "<cmd>Neogit log<CR>", desc = "Git log" },
		},
		opts = {
			integrations = {
				telescope = true,
				diffview = true,
			},
			commit_editor = {
				show_staged_diff = true,
				staged_diff_split_kind = "split",
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,
			current_line_blame = false,
			current_line_blame_opts = {
				delay = 500,
				virt_text_pos = "eol",
			},
			preview_config = {
				border = "rounded",
			},
			on_attach = function(buffer)
				local gitsigns = require("gitsigns")
				local map = function(mode, keys, command, desc)
					vim.keymap.set(mode, keys, command, {
						buffer = buffer,
						desc = desc,
					})
				end

				map("n", "]c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end, "Next git hunk")

				map("n", "[c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end, "Previous git hunk")

				map("n", "<Leader>gs", gitsigns.stage_hunk, "Stage hunk")
				map("n", "<Leader>gr", gitsigns.reset_hunk, "Reset hunk")
				map("v", "<Leader>gs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage selection")
				map("v", "<Leader>gr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Reset selection")

				map("n", "<Leader>gS", gitsigns.stage_buffer, "Stage buffer")
				map("n", "<Leader>gR", gitsigns.reset_buffer, "Reset buffer")
				map("n", "<Leader>gp", gitsigns.preview_hunk, "Preview hunk")
				map("n", "<Leader>gi", gitsigns.preview_hunk_inline, "Preview hunk inline")
				map("n", "<Leader>gb", function()
					gitsigns.blame_line({ full = true })
				end, "Blame line")
				map("n", "<Leader>gd", gitsigns.diffthis, "Diff buffer")
				map("n", "<Leader>gD", function()
					gitsigns.diffthis("~")
				end, "Diff buffer against previous")
				map("n", "<Leader>gq", gitsigns.setqflist, "Send hunks to quickfix")
				map("n", "<Leader>gB", gitsigns.toggle_current_line_blame, "Toggle line blame")
				map("n", "<Leader>gw", gitsigns.toggle_word_diff, "Toggle word diff")
				map({ "o", "x" }, "ih", gitsigns.select_hunk, "Select git hunk")
			end,
		},
	},
}
