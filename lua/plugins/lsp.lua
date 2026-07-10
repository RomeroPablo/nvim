return {
	{
		"mason-org/mason.nvim",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = {
				"lua_ls",
				"clangd",
				"rust_analyzer",
				"pyright",
			},
			automatic_enable = true,
		},
		config = function(_, opts)
			vim.diagnostic.config({
				virtual_text = true,
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			local clangd_executable = vim.fn.has("win32") == 1 and vim.fn.exepath("clangd") or "/usr/bin/clangd"
			if clangd_executable == "" then
				clangd_executable = "clangd"
			end

			local clangd_cmd = function(dispatchers, config)
				return vim.lsp.rpc.start({
					clangd_executable,
					"--clang-tidy",
					"--completion-style=detailed",
					"--header-insertion=iwyu",
					"--compile-commands-dir=.artifacts",
				}, dispatchers, {
					cwd = config.root_dir or vim.uv.cwd(),
					env = config.cmd_env,
					detached = config.detached,
				})
			end

			local clangd_defaults = vim.deepcopy(vim.lsp.config.clangd or {})
			local clangd_config = function(filetypes, fallback_flag)
				local config = vim.deepcopy(clangd_defaults)
				config.filetypes = filetypes
				config.cmd = clangd_cmd
				config.init_options = vim.tbl_deep_extend("force", config.init_options or {}, {
					fallbackFlags = { fallback_flag },
				})
				return config
			end

			vim.lsp.config("clangd", clangd_config({ "cpp", "objcpp", "cuda" }, "-std=c++23"))
			vim.lsp.config("clangd_c", clangd_config({ "c", "objc" }, "-std=c23"))
			vim.lsp.enable("clangd_c")

			vim.lsp.config("cmake", {
				cmd = { "cmake-language-server" },
				filetypes = { "cmake" },
			})

			vim.lsp.config("rust_analyzer", {
				cmd_env = {
					RUSTUP_TOOLCHAIN = "stable",
				},
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
						},
						checkOnSave = true,
						check = {
							command = "clippy",
						},
					},
				},
			})

			vim.lsp.config("pyright", {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
						},
					},
				},
			})

			vim.lsp.config("hls", {
				cmd = { "haskell-language-server-wrapper", "--lsp" },
				filetypes = { "haskell", "lhaskell", "cabal" },
			})
			vim.lsp.enable("hls")

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
					},
				},
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, command, desc)
						vim.keymap.set("n", keys, command, {
							buffer = event.buf,
							desc = desc,
						})
					end

					local diagnostic_jump = function(count)
						if vim.diagnostic.jump then
							vim.diagnostic.jump({
								count = count,
								severity = vim.diagnostic.severity.ERROR,
								float = true,
							})
							return
						end

						local jump = count > 0 and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
						jump({
							severity = vim.diagnostic.severity.ERROR,
							float = true,
						})
					end

					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("gD", vim.lsp.buf.declaration, "Go to declaration")
					map("gr", vim.lsp.buf.references, "Go to references")
					map("gi", vim.lsp.buf.implementation, "Go to implementation")
					map("K", vim.lsp.buf.hover, "Hover documentation")
					map("]e", function()
						diagnostic_jump(1)
					end, "Next error")
					map("[e", function()
						diagnostic_jump(-1)
					end, "Previous error")
					map("<Leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<Leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<Leader>f", function()
						vim.lsp.buf.format({ async = true })
					end, "Format buffer")
				end,
			})

			require("mason-lspconfig").setup(opts)
		end,
	},
}
