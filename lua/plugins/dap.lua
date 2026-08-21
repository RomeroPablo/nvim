local function conditional_breakpoint()
	local condition = vim.fn.input("Breakpoint condition: ")
	if condition ~= "" then
		require("dap").set_breakpoint(condition)
	end
end

local function log_point()
	local message = vim.fn.input("Log point message: ")
	if message ~= "" then
		require("dap").set_breakpoint(nil, nil, message)
	end
end

local function artifact_dirs()
	local cwd = vim.fn.getcwd()

	return {
		vim.fs.joinpath(cwd, ".artifacts"),
		vim.fs.joinpath(vim.fs.dirname(cwd), ".artifacts"),
		cwd,
	}
end

local function newest_executable()
	local newest

	for _, dir in ipairs(artifact_dirs()) do
		local handle = vim.uv.fs_scandir(dir)
		if handle then
			while true do
				local name, kind = vim.uv.fs_scandir_next(handle)
				if not name then
					break
				end

				local path = vim.fs.joinpath(dir, name)
				local stat = kind == "file" and vim.uv.fs_stat(path) or nil
				if stat and vim.fn.executable(path) == 1 and (not newest or stat.mtime.sec > newest.mtime) then
					newest = { path = path, mtime = stat.mtime.sec }
				end
			end
		end

		if newest then
			return newest.path
		end
	end
end

local function debug_program()
	local executable = newest_executable()
	local default = executable or vim.fs.joinpath(vim.fn.getcwd(), "")

	return vim.fn.input("Executable: ", default, "file")
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
		},
	},
	cmd = {
		"DapContinue",
		"DapNew",
		"DapPause",
		"DapRestartFrame",
		"DapStepInto",
		"DapStepOut",
		"DapStepOver",
		"DapTerminate",
		"DapToggleBreakpoint",
	},
	keys = {
		{ "<F5>", function() require("dap").continue() end, desc = "Debug: start/continue" },
		{ "<S-F5>", function() require("dap").terminate() end, desc = "Debug: stop" },
		{ "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
		{ "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
		{ "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
		{ "<S-F11>", function() require("dap").step_out() end, desc = "Debug: step out" },
		{ "<Leader>dc", function() require("dap").continue() end, desc = "Debug: start/continue" },
		{ "<Leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
		{ "<Leader>dB", conditional_breakpoint, desc = "Debug: conditional breakpoint" },
		{ "<Leader>dl", log_point, desc = "Debug: log point" },
		{ "<Leader>di", function() require("dap").step_into() end, desc = "Debug: step into" },
		{ "<Leader>do", function() require("dap").step_over() end, desc = "Debug: step over" },
		{ "<Leader>dO", function() require("dap").step_out() end, desc = "Debug: step out" },
		{ "<Leader>dp", function() require("dap").pause() end, desc = "Debug: pause" },
		{ "<Leader>dt", function() require("dap").terminate() end, desc = "Debug: terminate" },
		{ "<Leader>dr", function() require("dap").restart() end, desc = "Debug: restart" },
		{ "<Leader>dL", function() require("dap").run_last() end, desc = "Debug: run last" },
		{ "<Leader>df", function() require("dap").run_to_cursor() end, desc = "Debug: run to cursor" },
		{ "<Leader>dk", function() require("dap").up() end, desc = "Debug: stack frame up" },
		{ "<Leader>dj", function() require("dap").down() end, desc = "Debug: stack frame down" },
		{ "<Leader>du", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
		{ "<Leader>dR", function() require("dap").repl.toggle() end, desc = "Debug: toggle REPL" },
		{
			"<Leader>de",
			function() require("dapui").eval() end,
			mode = { "n", "v" },
			desc = "Debug: evaluate expression",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		dap.adapters.gdb = {
			type = "executable",
			command = vim.fn.exepath("gdb"),
			args = {
				"--interpreter=dap",
				"--eval-command",
				"set print pretty on",
			},
		}

		local configurations = {
			{
				name = "Launch newest executable",
				type = "gdb",
				request = "launch",
				program = debug_program,
				cwd = "${workspaceFolder}",
				stopAtBeginningOfMainSubprogram = false,
			},
			{
				name = "Attach to process",
				type = "gdb",
				request = "attach",
				program = debug_program,
				pid = function()
					return require("dap.utils").pick_process()
				end,
				cwd = "${workspaceFolder}",
			},
			{
				name = "Attach to gdbserver :1234",
				type = "gdb",
				request = "attach",
				target = "localhost:1234",
				program = debug_program,
				cwd = "${workspaceFolder}",
			},
		}

		dap.configurations.c = configurations
		dap.configurations.cpp = configurations

		dapui.setup({
			icons = {
				expanded = "▾",
				collapsed = "▸",
				current_frame = "▸",
			},
			controls = {
				enabled = true,
			},
			floating = {
				border = "rounded",
			},
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.35 },
						{ id = "stacks", size = 0.25 },
						{ id = "watches", size = 0.20 },
						{ id = "breakpoints", size = 0.20 },
					},
					position = "left",
					size = 42,
				},
				{
					elements = {
						{ id = "repl", size = 0.50 },
						{ id = "console", size = 0.50 },
					},
					position = "bottom",
					size = 12,
				},
			},
		})

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		vim.api.nvim_set_hl(0, "DapBreakpoint", { link = "DiagnosticError" })
		vim.api.nvim_set_hl(0, "DapBreakpointCondition", { link = "DiagnosticWarn" })
		vim.api.nvim_set_hl(0, "DapLogPoint", { link = "DiagnosticInfo" })
		vim.api.nvim_set_hl(0, "DapStopped", { link = "Visual" })
		vim.api.nvim_set_hl(0, "DapBreakpointRejected", { link = "Comment" })

		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition" })
		vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
		vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStopped" })
		vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected" })
	end,
}
