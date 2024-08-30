# EzUnreal - Neovim Plugin for Unreal Engine

**EzUnreal** is a Neovim plugin designed to streamline the process of building Unreal Engine projects and generating Clang databases. With customizable keybindings and easy setup, EzUnreal helps you integrate Unreal Engine development seamlessly into your Neovim workflow.

## Features

- **Build Unreal Engine Projects**: Easily trigger the build process for your Unreal Engine projects directly from Neovim.
- **Generate Clang Databases**: Automate the generation of Clang databases for code completion and navigation.
- **Customizable Keybindings**: Configure keybindings to suit your workflow.

## Installation

Use your favorite Neovim plugin manager to install **EzUnreal**.

### Using `packer.nvim`

```lua
use {
  'jonathanembleyriches/EzUnreal',
  config = function()
    require('EzUnreal').setup({
      keymaps = {
        build = '<leader>ub', -- Customize your keybinding here
      }
    })
  end,
  lazy = true,
  cmd = "EzUnrealBuild", -- Command to lazy load the plugin
}
```

