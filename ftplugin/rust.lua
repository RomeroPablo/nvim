local util = require("lspconfig.util")

if vim.fn.executable("rust-analyzer") ~= 1 then
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
  return util.root_pattern("Cargo.toml", "rust-project.json", ".git")(path)
    or vim.fs.dirname(path)
    or vim.loop.cwd()
end

if #vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" }) == 0 then
  local resolved_root = root_dir(0)
  vim.lsp.start({
    name = "rust_analyzer",
    cmd = { "rust-analyzer" },
    root_dir = resolved_root,
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
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })
end
