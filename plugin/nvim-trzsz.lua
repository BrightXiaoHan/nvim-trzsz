-- Register commands
vim.api.nvim_create_user_command("NvimTreeTsz", require('nvim-trzsz').nvim_tree_tsz, {})
vim.api.nvim_create_user_command("NvimTreeTrz", require('nvim-trzsz').nvim_tree_trz, {})
vim.api.nvim_create_user_command("NvimTreeOpen", require('nvim-trzsz').nvim_tree_open, {})