local M = {}

function M.setup(user_config)
    local config = require('unreal_builder.config')
    config.set(user_config)

    -- Set up keybindings
    vim.api.nvim_set_keymap('n', config.keymaps.build, ':lua require("unreal_builder.commands").unreal_build_toggle()<CR>', { noremap = true, silent = true })
end

return M
