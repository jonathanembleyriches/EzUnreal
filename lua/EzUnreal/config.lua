local M = {}

M.defaults = {
    keymaps = {
        build = '<leader>bue', -- Default keybinding for build
        run = '<leader>rue', -- Default keybinding for running built project
        run2 = '<leader>ru', -- Default keybinding for running built project
    }
}

function M.set(user_config)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, user_config or {})
end

function M.get()
    return M.options
end

return M
