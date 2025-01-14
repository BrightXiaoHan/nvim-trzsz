if vim.g.loaded_nvim_trzsz then
	return
end
vim.g.loaded_nvim_trzsz = true

-- Add any vim commands or autocommands here
vim.api.nvim_create_user_command("NvimTreeTsz", "lua require'nvim-trzsz'.nvim_tree_tsz()", { nargs = 0 })
vim.api.nvim_create_user_command("NvimTreeTrz", "lua require'nvim-trzsz'.nvim_tree_trz()", { nargs = 0 })