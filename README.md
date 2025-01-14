# nvim-trzsz

A Neovim plugin for [trzsz](https://trzsz.github.io/) (trz / tsz) support, which is similar to rz/sz, but with more terminals support.

You can find detailed documentation [here](https://github.com/trzsz/trzsz#supported-terminals).

## Features
- Upload and download files in your ssh session.
- nvim-tree integration.
- Works with tmux sessions.
- Directory support.

Demo:


## Pre-requisites
- Make sure your terminal supports trzsz. You can check the supported terminals [here](https://github.com/trzsz/trzsz#supported-terminals).
- Make sure you are working in a ssh session. trzsz does not work in local terminals.
- Install trzsz-ssh on your local machine. You can find the installation instructions [here](https://github.com/trzsz/trzsz-ssh).

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
vim.keymap.set("n", "t", "<cmd>require('nvim-trzsz').nvim_tree_trz()<cr>", {noremap = true, silent = true})
vim.keymap.set("n", "s", "<cmd>require('nvim-trzsz').nvim_tree_tsz()<cr>", {noremap = true, silent = true})
```
Here `t` is for uploading files and `s` is for downloading files.

- ssh into a remote server
- Open neovim and nvim-tree
- Navigate to the file you want to download in nvim-tree
- Press `t` to upload the file or `s` to download the file

or 
- Navigate to the directory you want to upload files to in nvim-tree
- Press `s`, and the file explorer will open
- Select the files you want to upload

## License
MIT
