if vim.g.loaded_nvim_trzsz then
	return
end
vim.g.loaded_nvim_trzsz = true

-- Register commands
vim.api.nvim_create_user_command("NvimTreeTsz", require'nvim-trzsz'.nvim_tree_tsz, {})
vim.api.nvim_create_user_command("NvimTreeTrz", require'nvim-trzsz'.nvim_tree_trz, {})