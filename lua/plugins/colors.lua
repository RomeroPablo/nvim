local palettes

local function apply_adjustments()
	local oxocarbon = require("oxocarbon").oxocarbon
	local dark = palettes.dark
	local light = palettes.light
	local syntax = {
		structure = light.base05,
		identifier = dark.base04,
		annotation = dark.base14,
		modifier = dark.base06,
		declaration = dark.base14,
		control = dark.base08,
		type = dark.base09,
		callable = dark.base12,
		property = dark.base07,
		namespace = dark.base15,
		number = dark.base15,
		literal = dark.base15,
		directive = dark.base11,
	}

	local groups = {
		-- Accessibility fixes, using only Oxocarbon's own neutral layers.
		Comment = { fg = syntax.structure, italic = true },
		Visual = { bg = oxocarbon.base03 },
		VisualNOS = { bg = oxocarbon.base03 },
		NormalFloat = { fg = oxocarbon.base05, bg = oxocarbon.base01 },
		FloatBorder = { fg = oxocarbon.base03, bg = oxocarbon.base01 },
		FloatTitle = { fg = oxocarbon.base09, bg = oxocarbon.base01, bold = true },
		LspInlayHint = { fg = oxocarbon.base03, bg = oxocarbon.base01, italic = true },

		-- Keep Telescope opaque while retaining Oxocarbon's native surface layers.
		TelescopeNormal = { fg = oxocarbon.base04, bg = oxocarbon.base01 },
		TelescopeBorder = { fg = oxocarbon.base03, bg = oxocarbon.base01 },
		TelescopePromptNormal = { fg = oxocarbon.base05, bg = oxocarbon.base02 },
		TelescopePromptBorder = { fg = oxocarbon.base02, bg = oxocarbon.base02 },
		TelescopePromptPrefix = { fg = oxocarbon.base08, bg = oxocarbon.base02 },
		TelescopeResultsNormal = { fg = oxocarbon.base04, bg = oxocarbon.base01 },
		TelescopePreviewNormal = { fg = oxocarbon.base04, bg = oxocarbon.base01 },
		TelescopeSelection = { bg = oxocarbon.base02 },
		TelescopeMatching = { fg = oxocarbon.base08, bold = true, italic = true },

		-- Semantic syntax roles. Every value comes from an installed Oxocarbon
		-- palette; the categories apply across languages and highlighting layers.
		Statement = { fg = syntax.control },
		Conditional = { fg = syntax.control },
		Repeat = { fg = syntax.control },
		Exception = { fg = syntax.control },
		Keyword = { fg = syntax.control },
		Label = { fg = syntax.control },
		StorageClass = { fg = syntax.modifier },
		Type = { fg = syntax.type },
		Structure = { fg = syntax.type },
		Typedef = { fg = syntax.type },
		Function = { fg = syntax.callable },
		Identifier = { fg = syntax.identifier },
		Operator = { fg = syntax.structure },
		Delimiter = { fg = syntax.structure },
		Number = { fg = syntax.number },
		Float = { fg = syntax.number },
		Constant = { fg = syntax.literal },
		Boolean = { fg = syntax.literal },
		Character = { fg = syntax.literal },
		String = { fg = syntax.literal },
		PreProc = { fg = syntax.directive },
		Include = { fg = syntax.directive },
		Macro = { fg = syntax.directive },
		Decorator = { fg = syntax.annotation },

		["@operator"] = { fg = syntax.structure },
		["@punctuation.bracket"] = { fg = syntax.structure },
		["@punctuation.delimiter"] = { fg = syntax.structure },
		["@punctuation.special"] = { fg = syntax.structure },

		["@keyword"] = { fg = syntax.control },
		["@keyword.return"] = { fg = syntax.control },
		["@keyword.conditional"] = { fg = syntax.control },
		["@keyword.repeat"] = { fg = syntax.control },
		["@keyword.exception"] = { fg = syntax.control },
		["@keyword.operator"] = { fg = syntax.control },
		["@keyword.modifier"] = { fg = syntax.modifier },
		["@keyword.type"] = { fg = syntax.declaration },
		["@keyword.function"] = { fg = syntax.declaration },
		["@keyword.coroutine"] = { fg = syntax.control },
		["@keyword.directive"] = { fg = syntax.directive },
		["@keyword.directive.define"] = { fg = syntax.directive },
		["@keyword.import"] = { fg = syntax.directive },
		["@keyword.assert"] = { fg = syntax.control },
		["@attribute"] = { fg = syntax.annotation },

		["@type"] = { fg = syntax.type },
		["@type.builtin"] = { fg = syntax.type },
		["@type.definition"] = { fg = syntax.type },
		["@module"] = { fg = syntax.namespace },
		["@namespace"] = { fg = syntax.namespace },

		["@variable"] = { fg = syntax.identifier },
		["@variable.parameter"] = { fg = syntax.identifier },
		["@variable.builtin"] = { fg = syntax.identifier },
		["@variable.member"] = { fg = syntax.property },
		["@property"] = { fg = syntax.property },
		["@field"] = { fg = syntax.property },
		["@parameter"] = { fg = syntax.identifier },

		["@function"] = { fg = syntax.callable },
		["@function.call"] = { fg = syntax.callable },
		["@function.method"] = { fg = syntax.callable },
		["@function.method.call"] = { fg = syntax.callable },
		["@function.builtin"] = { fg = syntax.callable },
		["@function.macro"] = { fg = syntax.directive },
		["@method"] = { fg = syntax.callable },
		["@constructor"] = { fg = syntax.callable },

		["@number"] = { fg = syntax.number },
		["@number.float"] = { fg = syntax.number },
		["@constant"] = { fg = syntax.literal },
		["@constant.builtin"] = { fg = syntax.literal },
		["@constant.macro"] = { fg = syntax.directive },
		["@boolean"] = { fg = syntax.literal },
		["@character"] = { fg = syntax.literal },
		["@string"] = { fg = syntax.literal },

		-- clangd mirrors the same roles and cannot repaint readonly/global tokens.
		["@lsp.type.bracket"] = { link = "@punctuation.bracket" },
		["@lsp.type.operator"] = { link = "@operator" },
		["@lsp.type.modifier"] = { link = "@keyword.modifier" },
		["@lsp.type.namespace"] = { link = "@module" },
		["@lsp.type.type"] = { link = "@type" },
		["@lsp.type.class"] = { link = "@type" },
		["@lsp.type.struct"] = { link = "@type" },
		["@lsp.type.interface"] = { link = "@type" },
		["@lsp.type.enum"] = { link = "@type" },
		["@lsp.type.typeParameter"] = { link = "@type" },
		["@lsp.type.concept"] = { link = "@type.definition" },
		["@lsp.type.function"] = { link = "@function" },
		["@lsp.type.method"] = { link = "@function.method" },
		["@lsp.type.parameter"] = { link = "@variable.parameter" },
		["@lsp.type.property"] = { link = "@property" },
		["@lsp.type.variable"] = { link = "@variable" },
		["@lsp.type.enumMember"] = { link = "@constant" },
		["@lsp.type.macro"] = { link = "@constant.macro" },
		["@lsp.mod.readonly"] = {},
		["@lsp.typemod.variable.global"] = { link = "@variable" },
		["@lsp.typemod.variable.static"] = { link = "@variable" },
		["@lsp.typemod.function.readonly"] = { link = "@function" },
		["@lsp.typemod.method.readonly"] = { link = "@function.method" },
	}

	for name, opts in pairs(groups) do
		vim.api.nvim_set_hl(0, name, opts)
	end
end

local palette_keys = {
	"base00",
	"base01",
	"base02",
	"base03",
	"base04",
	"base05",
	"base06",
	"base07",
	"base08",
	"base09",
	"base10",
	"base11",
	"base12",
	"base13",
	"base14",
	"base15",
	"blend",
}

local function read_palette(background)
	vim.opt.background = background
	package.loaded.oxocarbon = nil
	return vim.deepcopy(require("oxocarbon").oxocarbon)
end

local function show_palettes()
	local dark = palettes.dark
	local light = palettes.light

	vim.cmd("botright new")
	local bufnr = vim.api.nvim_get_current_buf()
	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].modifiable = true
	vim.bo[bufnr].filetype = "oxocarbon-palette"

	local lines = {
		"Oxocarbon palettes (queried from the installed theme)",
		"",
		"        slot    dark             light",
	}
	for _, key in ipairs(palette_keys) do
		table.insert(lines, ("        %-7s %-9s        %s"):format(key, dark[key], light[key]))
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	for index, key in ipairs(palette_keys) do
		local dark_group = "OxocarbonPaletteDark" .. key
		local light_group = "OxocarbonPaletteLight" .. key
		vim.api.nvim_set_hl(0, dark_group, { bg = dark[key] })
		vim.api.nvim_set_hl(0, light_group, { bg = light[key] })
		local row = index + 2
		vim.api.nvim_buf_add_highlight(bufnr, -1, dark_group, row, 0, 8)
		vim.api.nvim_buf_add_highlight(bufnr, -1, light_group, row, 25, 33)
	end

	vim.bo[bufnr].modifiable = false
	vim.bo[bufnr].modified = false
end

return {
	"nyoom-engineering/oxocarbon.nvim",
	build = false,
	lazy = false,
	priority = 1000,
	config = function()
		palettes = {
			dark = read_palette("dark"),
			light = read_palette("light"),
		}
		vim.opt.background = "dark"
		package.loaded.oxocarbon = nil
		vim.cmd.colorscheme("oxocarbon")
		apply_adjustments()

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("oxocarbon-adjustments", { clear = true }),
			pattern = "oxocarbon",
			callback = apply_adjustments,
		})

		vim.api.nvim_create_user_command("OxocarbonPalette", show_palettes, {
			desc = "Show the installed Oxocarbon Dark and Light palettes",
		})
	end,
}
