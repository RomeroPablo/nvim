local perfanno_status = function()
	return require("config.perfanno").statusline_parts()
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
						color = "#b4b4b4",
						name = "Slang",
					},
				},
			},
		},
	},
	event = "VeryLazy",
	opts = {
		options = {
			theme = "auto",
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
					separator = { left = "", right = "" },
				},
				{
					function()
						return ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
				},
				{
					function()
						local status = perfanno_status()
						return status and ("L " .. status.line .. "/" .. status.total) or ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
				},
				{
					function()
						return ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
				},
				{
					function()
						local status = perfanno_status()
						return status and ("F " .. status.func) or ""
					end,
					cond = function()
						return perfanno_status() ~= nil
					end,
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
