local filetypes = {
	c = true,
	cpp = true,
	cuda = true,
	haskell = true,
	lhaskell = true,
	lua = true,
	objc = true,
	objcpp = true,
	python = true,
	rust = true,
}

local function start_highlighting(bufnr)
	if filetypes[vim.bo[bufnr].filetype] then
		pcall(vim.treesitter.start, bufnr)
	end
end

return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		local treesitter = require("nvim-treesitter")
		treesitter.setup({})

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-highlighting", { clear = true }),
			pattern = vim.tbl_keys(filetypes),
			callback = function(event)
				start_highlighting(event.buf)
			end,
		})
	end,
}
