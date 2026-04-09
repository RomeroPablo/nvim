local null_ls = require("null-ls")

local diagnostics = null_ls.builtins.diagnostics

null_ls.setup({
    sources = {
        -- GLSL diagnostics via glslangValidator
        diagnostics.shellcheck, -- optional if you want Shell diagnostics
        diagnostics.glslang.with({
            filetypes = { "glsl", "vert", "frag", "geom", "comp" }, -- GLSL shader types
        }),
    },
})
