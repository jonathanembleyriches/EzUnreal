
local M = {}

M.defaults = {
    keymaps = {
        build = '<leader>bue', -- Default keybinding for build and create cc.json
    }
}

function M.set(user_config)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, user_config or {})
end

function M.get()
    return M.options
end

return M
