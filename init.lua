vim.env.NVIM_LOG_FILE = "/dev/null"
if vim.loader then
	vim.loader.enable()
end

require("config.controls")
require("config.options")
require("config.lazy")
