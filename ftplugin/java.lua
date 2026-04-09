local jdtls = require("jdtls")
local root_dir = require("jdtls.setup").find_root({ "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" }) or vim.loop.cwd()

-- Create a dedicated workspace per project root so JDT LS has a persistent cache.
local workspace_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "jdtls-workspace", vim.fs.basename(root_dir))
vim.fn.mkdir(workspace_dir, "p")

local config = {
  cmd = { "jdtls", "-data", workspace_dir },
  root_dir = root_dir,
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
}

jdtls.start_or_attach(config)
