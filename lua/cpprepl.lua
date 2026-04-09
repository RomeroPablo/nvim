vim.api.nvim_create_user_command("CppRepl", function()
    require("cpprepl.workspace").open()
end, {})
