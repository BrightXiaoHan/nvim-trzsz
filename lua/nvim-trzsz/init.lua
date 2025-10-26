local M = {}

-- Default configuration
M.config = {
	-- Add your default configuration options here
}

local function check()
	-- Check if nvim-tree is installed
	local status, api = pcall(require, "nvim-tree.api")
	if not status then
		vim.api.nvim_err_writeln("nvim-trzsz: nvim-tree is not installed")
		return nil
	end
	return api
end

local function is_remote()
	return vim.env.SSH_TTY ~= nil
end

local function open_file_manager(path)
	local os_name = vim.loop.os_uname().sysname:lower()

	if os_name == "darwin" then
		-- macOS: use open command
		vim.cmd("!open " .. path)
	elseif os_name == "linux" then
		-- Linux: try different file managers
		if vim.fn.executable("nautilus") == 1 then
			vim.cmd("!nautilus " .. path)
		elseif vim.fn.executable("dolphin") == 1 then
			vim.cmd("!dolphin " .. path)
		elseif vim.fn.executable("thunar") == 1 then
			vim.cmd("!thunar " .. path)
		elseif vim.fn.executable("pcmanfm") == 1 then
			vim.cmd("!pcmanfm " .. path)
		elseif vim.fn.executable("xdg-open") == 1 then
			vim.cmd("!xdg-open " .. path)
		else
			vim.api.nvim_err_writeln("nvim-trzsz: No supported file manager found")
		end
	elseif os_name == "windows" or os_name == "windows_nt" then
		-- Windows: use explorer
		vim.cmd("!explorer " .. path)
	else
		vim.api.nvim_err_writeln("nvim-trzsz: Unsupported operating system: " .. os_name)
	end
end

local function copy_file_to_destination(source_path)
	-- Get the current directory as default destination
	local current_dir = vim.fn.getcwd()

	-- Ask user for destination directory
	local destination = vim.fn.input("Copy to directory (default: " .. current_dir .. "): ", current_dir)

	if destination == "" then
		destination = current_dir
	end

	-- Check if source is a file or directory
	local source_type = ""
	if vim.fn.isdirectory(source_path) == 1 then
		source_type = "directory"
	else
		source_type = "file"
	end

	-- Copy command based on OS
	local os_name = vim.loop.os_uname().sysname:lower()
	local copy_cmd = ""

	if os_name == "darwin" or os_name == "linux" then
		-- Unix-like systems: use cp -r for directories, cp for files
		if source_type == "directory" then
			copy_cmd = 'cp -r "' .. source_path .. '" "' .. destination .. '"'
		else
			copy_cmd = 'cp "' .. source_path .. '" "' .. destination .. '"'
		end
	elseif os_name == "windows" or os_name == "windows_nt" then
		-- Windows: use xcopy or robocopy
		if vim.fn.executable("robocopy") == 1 then
			if source_type == "directory" then
				copy_cmd = 'robocopy "' .. source_path .. '" "' .. destination .. '" /E'
			else
				copy_cmd = 'robocopy "'
					.. vim.fn.fnamemodify(source_path, ":h")
					.. '" "'
					.. destination
					.. '" "'
					.. vim.fn.fnamemodify(source_path, ":t")
					.. '"'
			end
		else
			-- Fallback to xcopy
			if source_type == "directory" then
				copy_cmd = 'xcopy "' .. source_path .. '" "' .. destination .. '" /E /I /H'
			else
				copy_cmd = 'copy "' .. source_path .. '" "' .. destination .. '"'
			end
		end
	else
		vim.api.nvim_err_writeln("nvim-trzsz: Unsupported operating system for file copy")
		return
	end

	-- Execute copy command
	local result = vim.fn.system(copy_cmd)
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_err_writeln("nvim-trzsz: Failed to copy file: " .. result)
	else
		vim.api.nvim_echo({ { source_type .. " copied successfully to: " .. destination, "MoreMsg" } }, false, {})
	end
end

local function select_file_to_copy(destination_dir)
	-- Ask user to select source file
	local source_path = vim.fn.input("Select file or directory to copy: ")

	if source_path == "" then
		vim.api.nvim_echo({ { "Operation cancelled", "WarningMsg" } }, false, {})
		return
	end

	-- Expand ~ and resolve relative paths
	source_path = vim.fn.expand(source_path)

	-- Check if source exists
	if vim.fn.filereadable(source_path) == 0 and vim.fn.isdirectory(source_path) == 0 then
		vim.api.nvim_err_writeln("nvim-trzsz: Source file or directory does not exist: " .. source_path)
		return
	end

	-- Copy command based on OS
	local os_name = vim.loop.os_uname().sysname:lower()
	local copy_cmd = ""
	local source_type = vim.fn.isdirectory(source_path) == 1 and "directory" or "file"

	if os_name == "darwin" or os_name == "linux" then
		-- Unix-like systems: use cp -r for directories, cp for files
		if source_type == "directory" then
			copy_cmd = 'cp -r "' .. source_path .. '" "' .. destination_dir .. '"'
		else
			copy_cmd = 'cp "' .. source_path .. '" "' .. destination_dir .. '"'
		end
	elseif os_name == "windows" or os_name == "windows_nt" then
		-- Windows: use xcopy or robocopy
		if vim.fn.executable("robocopy") == 1 then
			if source_type == "directory" then
				copy_cmd = 'robocopy "' .. source_path .. '" "' .. destination_dir .. '" /E'
			else
				copy_cmd = 'robocopy "'
					.. vim.fn.fnamemodify(source_path, ":h")
					.. '" "'
					.. destination_dir
					.. '" "'
					.. vim.fn.fnamemodify(source_path, ":t")
					.. '"'
			end
		else
			-- Fallback to xcopy
			if source_type == "directory" then
				copy_cmd = 'xcopy "' .. source_path .. '" "' .. destination_dir .. '" /E /I /H'
			else
				copy_cmd = 'copy "' .. source_path .. '" "' .. destination_dir .. '"'
			end
		end
	else
		vim.api.nvim_err_writeln("nvim-trzsz: Unsupported operating system for file copy")
		return
	end

	-- Execute copy command
	local result = vim.fn.system(copy_cmd)
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_err_writeln("nvim-trzsz: Failed to copy file: " .. result)
	else
		vim.api.nvim_echo({ { source_type .. " copied successfully to: " .. destination_dir, "MoreMsg" } }, false, {})
	end
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

	if is_remote() then
		-- Remote environment: use tsz to download (from remote to local)
		if vim.fn.executable("tsz") == 0 then
			vim.api.nvim_err_writeln("nvim-trzsz: tsz command not found")
			return
		end
		vim.cmd("!tsz -q -y -d -b " .. path)
		-- refresh the tree
		api.tree.reload()
	else
		-- Local environment: select file to copy to current location
		select_file_to_copy(path)
	end
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

	if is_remote() then
		-- Remote environment: use trz to upload (from local to remote)
		if vim.fn.executable("trz") == 0 then
			vim.api.nvim_err_writeln("nvim-trzsz: trz command not found")
			return
		end
		vim.cmd("!trz -q -y -b " .. path)
		-- refresh the tree
		api.tree.reload()
	else
		-- Local environment: copy current file to destination
		copy_file_to_destination(path)
	end
end

-- Setup function
function M.nvim_tree_open()
	local api = check()
	if not api then
		return
	end

  if is_remote() then
    return
  end

	local node = api.tree.get_node_under_cursor()
	if not node then
		return
	end

	local path = node.absolute_path
	-- if current node is a file, get the parent directory of the file
	if node.type == "file" then
		path = vim.fn.fnamemodify(path, ":h")
	end

	open_file_manager(path)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
