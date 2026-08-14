local perfanno_status = function()
	return require("config.perfanno").statusline_parts()
end

local lackluster_status_color = function(fg, gui)
	return function()
		local color = require("lackluster").color
		local theme = require("lualine.themes.lackluster")

		return {
			fg = color[fg],
			bg = theme.normal.c.bg,
			gui = gui,
		}
	end
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{
			"nvim-tree/nvim-web-devicons",
			opts = {
				override_by_extension = {
					slang = {
						icon = "∿",
						color = "#28b8c7",
						name = "Slang",
					},
				},
			},
		},
	},
	event = "VeryLazy",
	opts = {
		options = {
			theme = "lackluster",
			icons_enabled = true,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			globalstatus = true,
			disabled_filetypes = {
				statusline = { "lazy" },
				winbar = {},
			},
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = {
				"branch",
				{
					"diff",
					colored = true,
					symbols = {
						added = " ",
						modified = " ",
						removed = " ",
					},
				},
			},
			lualine_c = {
				{
					"filename",
					path = 1,
					symbols = {
						modified = "●",
						readonly = "",
						unnamed = "[No Name]",
					},
				},
			},
			lualine_x = {
				{
					function()
						local status = perfanno_status()
						return status and status.event or ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
					color = lackluster_status_color("yellow", "bold"),
					separator = { left = "", right = "" },
				},
				{
					function()
						return ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
					color = lackluster_status_color("gray6"),
				},
				{
					function()
						local status = perfanno_status()
						return status and ("L " .. status.line .. "/" .. status.total) or ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
					color = lackluster_status_color("luster"),
				},
				{
					function()
						return ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
					color = lackluster_status_color("gray6"),
				},
				{
					function()
						local status = perfanno_status()
						return status and ("F " .. status.func) or ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
					color = lackluster_status_color("green", "bold"),
					separator = { left = "", right = "" },
				},
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = {
						error = " ",
						warn = " ",
						info = " ",
						hint = "󰌵 ",
					},
				},
				"encoding",
				"filetype",
			},
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{
					"filename",
					path = 1,
				},
			},
			lualine_x = { "location" },
			lualine_y = {},
			lualine_z = {},
		},
		extensions = {
			"lazy",
			"mason",
			"quickfix",
		},
	},
}
