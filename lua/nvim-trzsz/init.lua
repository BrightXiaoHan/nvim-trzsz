local M = {}

-- Default configuration
M.config = {
	-- Add your default configuration options here
}

local function check()
	-- Check if nvim-tree is installed
	local status, api = pcall(require, "nvim-tree.api")
	if not status then
		vim.notify("nvim-trzsz: nvim-tree is not installed", vim.log.levels.ERROR)
		return nil
	end
	return api
end

local function is_remote()
	return vim.env.SSH_TTY ~= nil
end

local function normalize_path(path)
	if not path or path == "" then
		return path
	end

	local ok, resolved = pcall(vim.loop.fs_realpath, path)
	if ok and resolved then
		return resolved
	end

	local sep = package.config:sub(1, 1)
	local normalized = path
	if sep == "\\" then
		normalized = normalized:gsub("[/\\]+$", "")
		if normalized:match("^%a:$") then
			normalized = normalized .. "\\"
		end
	else
		normalized = normalized:gsub("/+$", "")
		if normalized == "" then
			normalized = "/"
		end
	end

	return normalized
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
			vim.notify("nvim-trzsz: No supported file manager found", vim.log.levels.ERROR)
		end
	elseif os_name == "windows" or os_name == "windows_nt" then
		-- Windows: use explorer
		vim.cmd("!explorer " .. path)
	else
		vim.notify("nvim-trzsz: Unsupported operating system: " .. os_name, vim.log.levels.ERROR)
	end
end

local function select_file_dialog(title, mode)
	mode = mode or "file" -- "file" or "directory"
	title = title or "Select file"

	local os_name = vim.loop.os_uname().sysname:lower()
	local cmd = ""

	if os_name == "darwin" then
		-- macOS: use osascript
		if mode == "directory" then
			cmd = 'osascript -e \'tell application "Finder" to set theFolder to choose folder with prompt "'
				.. title
				.. "\"' -e 'POSIX path of theFolder' 2>/dev/null"
		else
			cmd = 'osascript -e \'tell application "Finder" to set theFile to choose file with prompt "'
				.. title
				.. "\"' -e 'POSIX path of theFile' 2>/dev/null"
		end
	elseif os_name == "linux" then
		-- Linux: use zenity or kdialog
		if vim.fn.executable("zenity") == 1 then
			if mode == "directory" then
				cmd = 'zenity --file-selection --directory --title="' .. title .. '" 2>/dev/null'
			else
				cmd = 'zenity --file-selection --title="' .. title .. '" 2>/dev/null'
			end
		elseif vim.fn.executable("kdialog") == 1 then
			if mode == "directory" then
				cmd = 'kdialog --getexistingdirectory --title="' .. title .. '" 2>/dev/null'
			else
				cmd = 'kdialog --getopenfilename --title="' .. title .. '" 2>/dev/null'
			end
		else
			vim.notify("nvim-trzsz: No supported file dialog found (zenity or kdialog required)", vim.log.levels.ERROR)
			return nil
		end
	elseif os_name == "windows" or os_name == "windows_nt" then
		-- Windows: use PowerShell
		if mode == "directory" then
			cmd = "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; $folder = New-Object System.Windows.Forms.FolderBrowserDialog; $folder.Description = '"
				.. title
				.. "'; $folder.ShowDialog() | Out-Null; $folder.SelectedPath\" 2>/dev/null"
		else
			cmd = "powershell -Command \"Add-Type -AssemblyName System.Windows.Forms; $file = New-Object System.Windows.Forms.OpenFileDialog; $file.Title = '"
				.. title
				.. "'; $file.ShowDialog() | Out-Null; $file.FileName\" 2>/dev/null"
		end
	else
		vim.notify("nvim-trzsz: Unsupported operating system for file dialog: " .. os_name, vim.log.levels.ERROR)
		return nil
	end

	-- Execute the command and capture output
	local result = vim.fn.system(cmd)

	-- Check if command succeeded
	if vim.v.shell_error ~= 0 or result == "" then
		return nil
	end

	-- Trim whitespace and newlines
	return vim.fn.trim(result)
end

local function copy_file_to_destination(source_path)
	source_path = normalize_path(source_path)
	-- Get the current directory as default destination
	local current_dir = vim.fn.getcwd()

	-- Try to use directory dialog first, fallback to manual input
	local destination = select_file_dialog("Select destination directory", "directory")

	if not destination then
		-- Fallback to manual input if directory dialog fails or is cancelled
		destination = vim.fn.input("Copy to directory (default: " .. current_dir .. "): ", current_dir)

		if destination == "" then
			destination = current_dir
		end
	end

	destination = normalize_path(destination)
	if vim.fn.isdirectory(destination) == 0 then
		vim.notify("nvim-trzsz: Destination directory does not exist: " .. destination, vim.log.levels.ERROR)
		return
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
		vim.notify("nvim-trzsz: Unsupported operating system for file copy", vim.log.levels.ERROR)
		return
	end

	-- Execute copy command
	local result = vim.fn.system(copy_cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("nvim-trzsz: Failed to copy file: " .. result, vim.log.levels.ERROR)
	else
		vim.api.nvim_echo({ { source_type .. " copied successfully to: " .. destination, "MoreMsg" } }, false, {})
	end
end

local function select_file_to_copy(destination_dir)
	destination_dir = normalize_path(destination_dir)
	if vim.fn.isdirectory(destination_dir) == 0 then
		vim.notify("nvim-trzsz: Destination directory does not exist: " .. destination_dir, vim.log.levels.ERROR)
		return
	end

	local selection = vim.fn.confirm("Copy &file or &directory?", "&File\n&Directory", 1)
	if selection == 0 then
		vim.api.nvim_echo({ { "Operation cancelled", "WarningMsg" } }, false, {})
		return
	end

	local mode = selection == 2 and "directory" or "file"
	local item_label = mode == "directory" and "directory" or "file"
	local prompt = "Select " .. item_label .. " to copy"

	-- Try to use file/directory dialog first, fallback to manual input
	local source_path = select_file_dialog(prompt, mode)

	if not source_path then
		-- Fallback to manual input if dialog fails or is cancelled
		source_path = vim.fn.input(prompt .. ": ")

		if source_path == "" then
			vim.api.nvim_echo({ { "Operation cancelled", "WarningMsg" } }, false, {})
			return
		end
	end

	-- Expand ~ and resolve relative paths
	source_path = vim.fn.expand(source_path)
	source_path = normalize_path(source_path)

	-- Check if source exists
	if vim.fn.filereadable(source_path) == 0 and vim.fn.isdirectory(source_path) == 0 then
		vim.notify("nvim-trzsz: Source file or directory does not exist: " .. source_path, vim.log.levels.ERROR)
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
		vim.notify("nvim-trzsz: Unsupported operating system for file copy", vim.log.levels.ERROR)
		return
	end

	-- Execute copy command
	local result = vim.fn.system(copy_cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("nvim-trzsz: Failed to copy file: " .. result, vim.log.levels.ERROR)
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
	local path = normalize_path(node.absolute_path)
	local destination_path = path
	if node.type == "file" then
		destination_path = vim.fn.fnamemodify(path, ":h")
		destination_path = normalize_path(destination_path)
	end

	if is_remote() then
		-- Remote environment: use tsz to download (from remote to local)
		if vim.fn.executable("tsz") == 0 then
			vim.notify("nvim-trzsz: tsz command not found", vim.log.levels.ERROR)
			return
		end
		local download_dir = node.type ~= "file"
		local args = "!tsz -q -y -d -b "
			.. (download_dir and "-r " or "")
			.. vim.fn.shellescape(path)
		vim.cmd(args)
		-- refresh the tree
		api.tree.reload()
	else
		-- Local environment: select file to copy to current location
		select_file_to_copy(destination_path)
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
	local node_path = normalize_path(node.absolute_path)
	local remote_target = node_path
	if node.type == "file" then
		remote_target = vim.fn.fnamemodify(node_path, ":h")
		remote_target = normalize_path(remote_target)
	end

	if is_remote() then
		-- Remote environment: use trz to upload (from local to remote)
		if vim.fn.executable("trz") == 0 then
			vim.notify("nvim-trzsz: trz command not found", vim.log.levels.ERROR)
			return
		end
		local cmd = "!trz -q -y -b " .. vim.fn.shellescape(remote_target)
		vim.cmd(cmd)
		-- refresh the tree
		api.tree.reload()
	else
		-- Local environment: copy current file to destination
		copy_file_to_destination(node_path)
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
