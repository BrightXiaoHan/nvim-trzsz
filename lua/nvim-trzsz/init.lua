local M = {}

-- Default configuration
M.config = {
	-- Add your default configuration options here
}

local function check()
	if vim.env.SSH_TTY == nil then
		vim.api.nvim_err_writeln("nvim-trzsz: SSH_TTY is not set")
		return nil
	end
	-- check if tsz command exists
	if vim.fn.executable("tsz") == 0 or vim.fn.executable("trz") == 0 then
		vim.api.nvim_err_writeln("nvim-trzsz: trz or tsz command not found")
		return nil
	end
	local status, api = pcall(require, "nvim-tree.api")
	if not status then
		vim.api.nvim_err_writeln("nvim-trzsz: nvim-tree is not installed")
		return nil
	end
	return api
end

function M.nvim_tree_tsz()
	local api = check()
	if not api then
		return
	end
	-- if current node is a folder, open it
	local node = api.tree.get_node_under_cursor()
	-- nil check
	if not node then
		return
	end
	-- get absolute path of the current node
	local path = node.absolute_path
	-- run tsz command
	vim.cmd("!tsz -q -y -d -b " .. path)
	-- refresh the tree
	api.tree.reload()
end

function M.nvim_tree_trz()
	local api = check()

	if not api then
		return
	end
	-- if current node is a folder, open it
	local node = api.tree.get_node_under_cursor()
	-- nil check
	if not node then
		return
	end
	-- get absolute path of the current node
	local path = node.absolute_path
	-- if current node is a file, get the parent directory of the file
	if node.type == "file" then
		path = vim.fn.fnamemodify(path, ":h")
	end
	-- run trz command
	vim.cmd("!trz -q -y -b " .. path)
	-- refresh the tree
	api.tree.reload()
end

-- Setup function
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
