-- hs: run local build script from the file's directory
local function run_local_build()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    vim.notify("No file directory found for build", vim.log.levels.WARN)
    return
  end

  local cabal_path = vim.fn.globpath(dir, "*.cabal")
  if cabal_path == "" then
    vim.notify("cabal file not found in: " .. dir, vim.log.levels.WARN)
    return
  end

  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.fn.termopen({ "cabal", "run" }, { cwd = dir })
  vim.cmd("startinsert")
end

vim.keymap.set("n", "<Leader>r", run_local_build, {
  buffer = true,
  noremap = true,
  silent = true,
  desc = "Run 'cabal run' ",
})
