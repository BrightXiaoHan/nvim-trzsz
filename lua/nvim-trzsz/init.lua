local M = {}

-- Default configuration
M.config = {
    -- Add your default configuration options here
}

function M.nvim_tree_tsz()
    if vim.env.SSH_TTY == nil then
      return
    end
    -- check if tsz command exists
    if vim.fn.executable("tsz -h") == 0 then
      print("tsz command not found")
      return
    end

    local api = require "nvim-tree.api"
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
    if vim.env.SSH_TTY == nil then
      return
    end
    -- check if trz command exists
    if vim.fn.executable("trz -h") == 0 then
      print("trz command not found")
      return
    end
    local api = require "nvim-tree.api"
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

-- create user commands
vim.cmd [[
command! NvimTreeTsz lua require'nvim-trzsz'.nvim_tree_tsz()
command! NvimTreeTrz lua require'nvim-trzsz'.nvim_tree_trz()
]]

-- Setup function
function M.setup(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
