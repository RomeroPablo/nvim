local capabilities = require('cmp_nvim_lsp').default_capabilities()
local util = require('lspconfig.util')

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls" },
})

local function existing_dirs(paths)
  local dirs = {}
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 then
      table.insert(dirs, path)
    end
  end
  return dirs
end

local lua_workspace_library = vim.api.nvim_get_runtime_file("", true)
vim.list_extend(lua_workspace_library, existing_dirs({
  "/usr/lib/lua-language-server/meta/3rd/love2d/library",
  vim.fn.stdpath("data") .. "/mason/packages/lua-language-server/libexec/meta/3rd/love2d/library",
}))
 
local function root_with_git_fallback(fname)
  local path = fname
  if type(path) == "number" then
    path = vim.api.nvim_buf_get_name(path)
  end
  if not path or path == "" then
    return vim.loop.cwd()
  end
  return util.find_git_ancestor(path) or vim.fs.dirname(path) or vim.loop.cwd()
end

vim.filetype.add({
  extension = {
    vert = "glsl",
    frag = "glsl",
    geom = "glsl",
    comp = "glsl",
    tesc = "glsl",
    tese = "glsl",
  },
})

-- Apply cmp capabilities everywhere unless overridden explicitly.
vim.lsp.config('*', {
  capabilities = capabilities,
})

-- C/C++
vim.lsp.config('clangd', {
  cmd = {
    "clangd",
    "--clang-tidy",
    "--clang-tidy-checks=*",
    "--completion-style=detailed",
    "--header-insertion=iwyu",
    "--compile-commands-dir=.artifacts",
  },
})

vim.lsp.config('rust_analyzer', {
  root_dir = root_with_git_fallback,
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

vim.lsp.config('ocamllsp', {
  cmd = { "ocamllsp" },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
      diagnostics = {
        globals = { "vim" },
      },
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        checkThirdParty = false,
        library = lua_workspace_library,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- Go
local gopls_bin = vim.fn.exepath("gopls")
if gopls_bin == "" and vim.fn.executable("/usr/bin/gopls") == 1 then
  gopls_bin = "/usr/bin/gopls"
end

if gopls_bin ~= "" then
  vim.lsp.config('gopls', {
    cmd = { gopls_bin },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = root_with_git_fallback,
    settings = {
      gopls = {
        gofumpt = true,
        staticcheck = true,
      },
    },
  })
  vim.lsp.enable('gopls')
end

-- TCL
vim.lsp.config('tcl_ls', {
  cmd = { "tcl-language-server" },
  filetypes = { "tcl" },
  root_dir = root_with_git_fallback,
})

-- Verilog / SystemVerilog
vim.lsp.config('svlangserver', {
  cmd = { "svlangserver" },
  settings = {
    systemverilog = {
      includeIndexing = { "*.{v,vh,sv,svh}", "**/*.{v,vh,sv,svh}" },
    },
  },
})

-- Pascal / Free Pascal
do
  local pascal_cmd = nil
  if vim.fn.executable("pasls") == 1 then
    pascal_cmd = { "pasls" }
  elseif vim.fn.executable("fpclsp") == 1 then
    pascal_cmd = { "fpclsp" }
  end

  if pascal_cmd then
    vim.lsp.config('pasls', {
      cmd = pascal_cmd,
      filetypes = { "pascal", "objectpascal" },
      root_dir = root_with_git_fallback,
    })
  end
end

-- Ada
local enabled_servers = {
  'clangd',
  'hls',
  'lua_ls',
  'ocamllsp',
  'tcl_ls',
  'pyright',
  'glsl_analyzer',
  'ts_ls',
  'cssls',
  'julials',
  'svlangserver',
}

local function add_if_executable(name, cmd)
  if vim.fn.executable(cmd) == 1 then
    table.insert(enabled_servers, name)
    return true
  end
  return false
end

if add_if_executable('pasls', 'pasls') or add_if_executable('pasls', 'fpclsp') then
  -- already configured above
end

-- Ada
local ada_cmd = nil
if vim.fn.executable("als") == 1 then
  ada_cmd = { "als" }
elseif vim.fn.executable("ada_language_server") == 1 then
  ada_cmd = { "ada_language_server" }
end

if ada_cmd and add_if_executable('als', ada_cmd[1]) then
  vim.lsp.config('als', {
    cmd = ada_cmd,
    filetypes = { "ada" },
    root_dir = root_with_git_fallback,
    single_file_support = true,
  })
end

-- Enable the language servers we rely on.
pcall(vim.lsp.enable, enabled_servers)
