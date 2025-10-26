# nvim-trzsz

A Neovim plugin for [trzsz](https://trzsz.github.io/) (trz / tsz) support, which is similar to rz/sz, but with more terminals support.

You can find detailed documentation [here](https://github.com/trzsz/trzsz#supported-terminals).

## Features
- Upload and download files in your ssh session.
- Open file manager in local environment.
- nvim-tree integration.
- Works with tmux sessions.
- Directory support.

Demo Upload File:
![Demo Upload File](https://i.ibb.co/ThXnGyG/2025-01-14-16-49-14-2025-01-14-16-57-25.gif)

## Pre-requisites
- Make sure your terminal supports trzsz. You can check the supported terminals [here](https://github.com/trzsz/trzsz#supported-terminals).
- Make sure you are working in a ssh session. trzsz does not work in local terminals.
- Install trzsz-ssh on your local machine. You can find the installation instructions [here](https://github.com/trzsz/trzsz-ssh).
- Install trzsz on your remote machine. [trzsz installation guide](https://github.com/trzsz/trzsz-ssh/blob/main/README.en.md#support-trzsz)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
    "BrightXiaohan/nvim-trzsz",
    dependencies = {
        {"nvim-tree/nvim-tree.lua"}
    },
}
```

## Basic Usage
Map the commands to your preferred keybindings:
```lua
vim.keymap.set("n", "<leader>r", "<cmd>require('nvim-trzsz').nvim_tree_trz()<cr>", {noremap = true, silent = true})
vim.keymap.set("n", "<leader>s", "<cmd>require('nvim-trzsz').nvim_tree_tsz()<cr>", {noremap = true, silent = true})
vim.keymap.set("n", "<leader>o", "<cmd>require('nvim-trzsz').nvim_tree_open()<cr>", {noremap = true, silent = true})
```

### Remote Environment (SSH Session)
- `<leader>r` - Upload files from local to remote (trz)
- `<leader>s` - Download files from remote to local (tsz)

### Local Environment
- `<leader>r` - Copy current file/directory to destination directory
- `<leader>s` - Select file/directory to copy to current location
- `<leader>o` - Open file manager at current directory

### Usage Examples

**Remote Environment:**
- ssh into a remote server
- Open neovim and nvim-tree
- Navigate to the file you want to upload in nvim-tree
- Press `<leader>r` to upload the file (trz)

or
- Navigate to the directory you want to download files to in nvim-tree
- Press `<leader>s`, and the file explorer will open
- Select the files you want to download (tsz)

**Local Environment:**
- **Copy current file/directory**: Navigate to a file or directory in nvim-tree, press `<leader>r`, then enter destination directory
- **Copy file to current location**: Navigate to destination directory in nvim-tree, press `<leader>s`, then select source file/directory
- **Open file manager**: Navigate to any directory in nvim-tree, press `<leader>o` to open system file manager

## TODO
- [ ] Automatically install trzsz on the remote machine.
- [ ] Lua API for more customization.

## License
MIT
