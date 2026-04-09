local telescope = require("telescope")

telescope.setup({
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
            hidden = false
        },
        live_grep = {
            additional_args = function()
                return { "--hidden" }
            end
        },
    },
})

-- Keybindings
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<Leader>ff", builtin.find_files, { desc = "Find Files" })
vim.keymap.set("n", "<Leader>fg", builtin.live_grep, { desc = "Live Grep" })
vim.keymap.set("n", "<Leader>fb", builtin.buffers, { desc = "Find Buffers" })
vim.keymap.set("n", "<Leader>fh", builtin.help_tags, { desc = "Help Tags" })
