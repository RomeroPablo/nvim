-- Bootstrap Lazy.nvim
vim.opt.rtp:prepend("~/.config/nvim/lua/lazy")

require("lazy").setup({ {"neovim/nvim-lspconfig"},
                        {"williamboman/mason.nvim"},
                        {"williamboman/mason-lspconfig.nvim"},
                        {"hrsh7th/nvim-cmp"}, 
                        {"hrsh7th/cmp-nvim-lsp"}, 
                        {"L3MON4D3/LuaSnip"}, 
                        {"saadparwaiz1/cmp_luasnip"},
                        {"mfussenegger/nvim-jdtls", ft = "java"},
                        {"mfussenegger/nvim-dap"},
                        {"rcarriga/nvim-dap-ui"},
                        {"catppuccin/nvim", name = "catppuccin"},
                        {"nvim-telescope/telescope.nvim", tag = "0.1.5", dependencies = {"nvim-lua/plenary.nvim"} }, 
                        {
                            "edluffy/hologram.nvim",
                            config = function()
                                require("hologram").setup({
                                    auto_display = true,
                                })
                            end,
                        },
                        {
                            "echasnovski/mini.animate",
                            version = false,
                            enabled = false,
                            config = function()
                                local animate = require("mini.animate")
                                local fast = animate.gen_timing.linear({ duration = 50 })
                                animate.setup({
                                    cursor = { timing = fast },
                                    scroll = { timing = fast },
                                })
                            end,
                        },

                        {
  "kawre/leetcode.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("leetcode").setup({
      lang = "cpp", -- or "python3", etc.
    })
  end
},
                    {
                        "nvimtools/none-ls.nvim", 
                        dependencies = { "nvim-lua/plenary.nvim" },
                    },
                    {
                        "preservim/vim-markdown",
                        ft = "markdown",
                        config = function()
                            vim.g.vim_markdown_folding_disabled = 1
                            vim.g.vim_markdown_conceal = 0
                            vim.g.vim_markdown_follow_anchor = 1
		    	end
                    },
                    {
  "jakewvincent/mkdnflow.nvim",
  ft = "markdown",
  config = function()
    require("mkdnflow").setup({
      modules = {
        bib = false,
        buffers = true,
        conceal = false,
        cursor = true,
        folds = false,
        links = true,
        lists = true,
        maps = true,
        paths = true,
        tables = false,
        yaml = false
      },
      filetypes = { md = true, markdown = true },
      links = {
        style = "markdown", -- or "wiki"
        conceal = false,
        context = 0,
        implicit_extension = ".md",
        transform_implicit = function(input) return input:lower():gsub(" ", "-") end,
        transform_explicit = function(text, link) return link end,
      },
      mappings = {
        MkdnEnter = { { "n", "v" }, "<CR>" }, -- follow link under cursor
        MkdnTab = false,
        MkdnTableNextCell = false,
        MkdnTablePrevCell = false,
      },
    })
  end,
},
{
  "lervag/vimtex", -- main LaTeX plugin
  ft = { "tex" },
  config = function()
    vim.g.vimtex_view_method = "zathura"   -- or skim, sumatrapdf, etc.
    vim.g.vimtex_compiler_method = "latexmk"
  end
},

                    })

require("options")
require("keymaps")
require("lsp")
require("completion")
require("colors")
require("telescope_setup")
require("cpprepl")
vim.opt.shortmess:append("I")
vim.g.vim_markdown_checkbox_checked = 1
vim.g.vim_markdown_checkbox_unchecked = 0
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
