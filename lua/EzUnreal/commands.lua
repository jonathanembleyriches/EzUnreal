local Job = require('plenary.job')
local Terminal = require('toggleterm.terminal').Terminal
local notify = require("notify")

local M = {}

local function load_build_params()
    local params_file = vim.fn.getcwd() .. '/build_params.lua'
    local params = loadfile(params_file)
    if params then
        return params()
    else
        notify("Could not load build parameters from " .. params_file, "error", { title = "Build Error" })
        error("Could not load build parameters from " .. params_file)
    end
end

local build_params = load_build_params()
local engine_path = build_params.engine_path
local target = build_params.project_name .. "Editor"
local u_project_path = build_params.project_path .. "\\" .. build_params.project_name .. ".uproject"

local function run_in_buffer(cmd, title)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(bufnr, "filetype", "log")

    local win_id = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        row = math.floor(vim.o.lines * 0.1),
        col = math.floor(vim.o.columns * 0.1),
        style = "minimal",
        border = "single",
    })

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Running: " .. title, "" })

    local job = Job:new({
        command = "cmd.exe",
        args = { "/C", cmd },
        on_stdout = function(_, line)
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
            end)
        end,
        on_stderr = function(_, line)
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "[ERROR] " .. line })
            end)
        end,
        on_exit = function()
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "", "Process completed." })
            end)
        end,
    })

    job:start()
end

local function run_build_command(callback)
    local cmd = string.format(
        'dotnet "%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.dll" %s Win64 Development -Project="%s" -WaitMutex',
        engine_path,
        target,
        u_project_path
    )

    notify("Starting build process...", "info", { title = "Build Status" })
    run_in_buffer(cmd, "Unreal Build Process")
    if callback then callback() end
end

local function run_clang_database_command()
    local cmd = string.format(
        '"%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe" -mode=GenerateClangDatabase -Project="%s" -game -engine "%s" Development Win64',
        engine_path,
        u_project_path,
        target
    )

    notify("Clang database generation started", "info", { title = "Clang Database" })
    -- Do not display output in a buffer for this command.
    Job:new({
        command = "cmd.exe",
        args = { "/C", cmd },
        on_exit = function()
            notify("Clang database generation completed", "info", { title = "Clang Database" })
        end,
    }):start()
end

function M.unreal_build_toggle()
    run_build_command(run_clang_database_command)
end

function M.unreal_run()
    local cmd = string.format(
        '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
        engine_path,
        u_project_path
    )
    notify("Launching Unreal Editor...", "info", { title = "Unreal Editor" })
    run_in_buffer(cmd, "Unreal Editor")
end

local dap = require('dap')

function M.unreal_run2()
    dap.adapters.unreal_editor = {
        type = 'executable',
        command = 'cmd.exe',
        args = { '/C', string.format(
                '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
                engine_path,
                u_project_path)
        },
    }

    local configuration = {
        name = "Launch Unreal Editor",
        type = "unreal_editor",
        request = "launch",
        program = string.format(
            '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
            engine_path,
            u_project_path
        ),
        cwd = vim.fn.getcwd(),
        stopOnEntry = false,
    }

    notify("Launching Unreal Editor with DAP...", "info", { title = "Unreal Editor DAP" })
    dap.run(configuration)
end

return M
