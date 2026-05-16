local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Leader Key
vim.g.mapleader = " "

-- Quick save & quit
map("n", "<Leader>w", ":w<CR>", opts)
map("n", "<Leader>q", ":q<CR>", opts)

-- Copy to system clipboard without affecting Vim registers
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, silent = true })

-- Paste from system clipboard without affecting Vim registers
vim.keymap.set("i", "<C-v>", '<C-r>+', { noremap = true, silent = true })
vim.keymap.set("n", "<C-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("v", "<C-v>", '"+p', { noremap = true, silent = true })

local opts = { noremap = true, silent = true }

-- Terminal toggle function
function _G.toggle_terminal()
  -- Look for an existing terminal buffer in current tab
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end

  -- No terminal visible, open a bottom split terminal at ~20% editor height
  local term_height = math.max(5, math.floor(vim.o.lines * 0.2))
  vim.cmd("botright " .. term_height .. "split | terminal")
  vim.cmd("startinsert")
end

-- Keymap to toggle terminal
vim.keymap.set("n", "<Leader>t", toggle_terminal, opts)

-- <Esc> to exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)

-- <CTRL> + <s> to go Source <--> Header (C/C++)
vim.keymap.set('n', '<C-s>', '<cmd>LspClangdSwitchSourceHeader<CR>', { noremap = true, silent = true })
