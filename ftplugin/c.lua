-- C: run local build script from the file's directory
local function run_local_build()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    vim.notify("No file directory found for build", vim.log.levels.WARN)
    return
  end

  local build_path = dir .. "/build"
  if vim.fn.filereadable(build_path) == 0 then
    vim.notify("build script not found: " .. build_path, vim.log.levels.WARN)
    return
  end

  local prev_dir = vim.fn.getcwd()
  vim.cmd("lcd " .. vim.fn.fnameescape(dir))
  vim.cmd("!./build")
  vim.cmd("lcd " .. vim.fn.fnameescape(prev_dir))
end

vim.keymap.set("n", "<Leader>r", run_local_build, {
  buffer = true,
  noremap = true,
  silent = true,
  desc = "Run local build script",
})
