local function diagnostic_float()
	local width = vim.api.nvim_win_get_width(0)
	local max_width = math.min(100, width - 4)

	return {
		border = "rounded",
		source = "if_many",
		max_width = max_width,
		wrap = true,
		wrap_at = max_width,
	}
end

local function clangd_command()
	local executable = vim.fn.exepath("clangd")
	if executable == "" then
		executable = "clangd"
	end

	return function(dispatchers, config)
		return vim.lsp.rpc.start({
			executable,
			"--clang-tidy",
			"--completion-style=detailed",
			"--header-insertion=iwyu",
			"--compile-commands-dir=.artifacts",
			"--experimental-modules-support",
		}, dispatchers, {
			cwd = config.root_dir or vim.uv.cwd(),
			env = config.cmd_env,
			detached = config.detached,
		})
	end
end

local function clangd_config(defaults, command, filetypes, fallback_flag)
	local config = vim.deepcopy(defaults)
	config.filetypes = filetypes
	config.cmd = command
	config.init_options = vim.tbl_deep_extend("force", config.init_options or {}, {
		fallbackFlags = { fallback_flag },
	})
	return config
end

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
				virtual_lines = false,
				float = diagnostic_float,
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
			})

			local defaults = vim.deepcopy(vim.lsp.config.clangd or {})
			local command = clangd_command()
			vim.lsp.config("clangd", clangd_config(defaults, command, { "cpp", "objcpp", "cuda" }, "-std=c++26"))
			vim.lsp.config("clangd_c", clangd_config(defaults, command, { "c", "objc" }, "-std=c23"))
			vim.lsp.enable("clangd_c")

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

			vim.filetype.add({
				extension = {
					slang = "slang",
				},
			})

			vim.lsp.config("slangd", {
				cmd = { "slangd" },
				filetypes = { "slang" },
				on_attach = function(client)
					local semantic_tokens = client.server_capabilities.semanticTokensProvider
					if semantic_tokens and type(semantic_tokens.full) == "table" then
						semantic_tokens.full.delta = false
					end

					local request = client.request
					client.request = function(self, method, params, handler, bufnr)
						if
							method ~= "textDocument/semanticTokens/full"
							and method ~= "textDocument/semanticTokens/full/delta"
							and method ~= "textDocument/semanticTokens/range"
						then
							return request(self, method, params, handler, bufnr)
						end

						local wrapped_handler = function(err, result, ctx)
							if result and not result.data and not result.edits then
								result.data = {}
							end

							return handler(err, result, ctx)
						end

						return request(self, method, params, wrapped_handler, bufnr)
					end
				end,
			})
			vim.lsp.enable("slangd")

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
					local function map(keys, command, desc)
						vim.keymap.set("n", keys, command, {
							buffer = event.buf,
							desc = desc,
						})
					end

					local function diagnostic_jump(count)
						vim.diagnostic.jump({
							count = count,
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
					map("<Leader>e", function()
						vim.diagnostic.open_float(nil, { scope = "line" })
					end, "Line diagnostics")
					map("<Leader>f", function()
						vim.lsp.buf.format({ async = true })
					end, "Format buffer")
				end,
			})

			require("mason-lspconfig").setup(opts)
		end,
	},
}
