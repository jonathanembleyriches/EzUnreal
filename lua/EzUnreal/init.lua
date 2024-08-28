local M = {}

function M.setup(user_config)
    local config = require('EzUnreal.config')
    config.set(user_config)

    -- Set up keybindings
    vim.api.nvim_set_keymap('n', config.keymaps.build, ':lua require("EzUnreal.commands").unreal_build_toggle()<CR>', { noremap = true, silent = true })
end

return M
