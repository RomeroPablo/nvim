vim.g.mapleader = " "

local function map(mode, keys, command, description)
	vim.keymap.set(mode, keys, command, {
		silent = true,
		desc = description,
	})
end

map("n", "<Leader>w", "<cmd>write<CR>", "Write buffer")
map("n", "<Leader>q", "<cmd>quit<CR>", "Quit window")

-- Use the system clipboard without changing unnamed registers.
map("v", "<C-c>", '"+y', "Copy to system clipboard")
map("i", "<C-v>", '<C-r>+', "Paste from system clipboard")
map("n", "<C-v>", '"+p', "Paste from system clipboard")
map("v", "<C-v>", '"+p', "Paste from system clipboard")

local function toggle_terminal()
	for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local bufnr = vim.api.nvim_win_get_buf(winid)
		if vim.bo[bufnr].buftype == "terminal" then
			vim.api.nvim_win_close(winid, true)
			return
		end
	end

	local height = math.max(5, math.floor(vim.o.lines * 0.2))
	vim.cmd("botright " .. height .. "split | terminal")
	vim.cmd.startinsert()
end

map("n", "<Leader>t", toggle_terminal, "Toggle terminal")
map("t", "<Esc>", [[<C-\><C-n>]], "Leave terminal mode")

map("n", "<C-s>", "<cmd>LspClangdSwitchSourceHeader<CR>", "Switch source/header")
map("n", "<Leader>aa", function()
	require("config.asm").toggle()
end, "Toggle assembly view")
