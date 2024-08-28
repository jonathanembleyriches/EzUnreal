-- lua/ezunreal/init.lua
local M = {}

function M.setup(user_config)
    local config = require('EzUnreal.config')
    config.set(user_config)

    local options = config.get()
    if options and options.keymaps and options.keymaps.build then
        -- Set up keybindings
        vim.api.nvim_set_keymap('n', options.keymaps.build, ':lua require("EzUnreal.commands").unreal_build_toggle()<CR>', { noremap = true, silent = true })
    else
        error("EzUnreal: keymaps configuration is missing or incorrect")
    end
end

return M
