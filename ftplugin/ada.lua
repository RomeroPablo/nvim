local util = require("lspconfig.util")

local cmd
if vim.fn.executable("ada_language_server") == 1 then
  cmd = { "ada_language_server" }
elseif vim.fn.executable("als") == 1 then
  cmd = { "als" }
else
  return
end

local function root_dir(fname)
  local path = fname
  if type(path) == "number" then
    path = vim.api.nvim_buf_get_name(path)
  end
  if not path or path == "" then
    return vim.loop.cwd()
  end
  return util.find_git_ancestor(path) or vim.fs.dirname(path) or vim.loop.cwd()
end

if #vim.lsp.get_clients({ bufnr = 0, name = "als" }) == 0 then
  local resolved_root = root_dir(0)
  vim.lsp.start({
    name = "als",
    cmd = cmd,
    root_dir = resolved_root,
    single_file_support = true,
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })
end
