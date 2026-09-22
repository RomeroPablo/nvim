local function grep_previewer(opts)
	local previewer = require("telescope.previewers").vim_buffer_vimgrep.new(opts)
	local preview = previewer.preview_fn

	previewer.preview_fn = function(self, entry, status)
		-- Ripgrep's vimgrep output includes the start column, but not the end
		-- column Telescope needs to highlight the actual match in its preview.
		entry.colend = nil
		local query = require("telescope.actions.state").get_current_line()
		local text = entry.text or ""
		local start_col = entry.col and entry.col - 1

		if start_col and query ~= "" then
			local candidate = text:sub(start_col + 1, start_col + #query)
			local case_sensitive = query:find("%u") ~= nil
			local literal_match = case_sensitive and candidate == query
				or not case_sensitive and candidate:lower() == query:lower()

			if literal_match then
				entry.colend = start_col + #query + 1
			else
				-- This also handles common regular-expression searches. If a
				-- ripgrep expression is not valid Vim regex, Telescope retains
				-- its normal whole-line preview highlight as a fallback.
				local ok, regex = pcall(vim.regex, query)
				if ok then
					local match_start, match_end = regex:match_str(text:sub(start_col + 1))
					if match_start == 0 then
						entry.colend = start_col + match_end + 1
					end
				end
			end
		end

		return preview(self, entry, status)
	end

	return previewer
end

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
	opts = {
		defaults = {
			grep_previewer = grep_previewer,
			prompt_prefix = "  ",
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
		},
	},
}
