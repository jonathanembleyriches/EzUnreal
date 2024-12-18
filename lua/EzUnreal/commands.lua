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

-- Singleton terminal instance for build
local build_terminal

local function run_build_command(callback)
    if not build_terminal then
        build_terminal = Terminal:new({
            direction = "horizontal",
            close_on_exit = true,
            on_close = function()
                notify("Build process completed", "info", { title = "Build Status" })
                if callback then callback() end
            end,
            on_stdout = function(_, output)
                if string.find(output, "error") then
                    notify("Build Error: " .. output, "error", { title = "Build Error" })
                end
            end,
            on_stderr = function(_, output)
                notify("Build Error: " .. output, "error", { title = "Build Error" })
            end,
        })
    end

    build_terminal.cmd = string.format(
        'dotnet "%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.dll" %s Win64 Development -Project="%s" -WaitMutex',
        engine_path,
        target,
        u_project_path
    )
    notify("Starting build process...", "info", { title = "Build Status" })
    build_terminal:toggle()
end

local function run_clang_database_command()
    notify("Starting Clang database generation...", "info", { title = "Clang Database" })
    local clang_cmd = string.format(
        '"%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe" -mode=GenerateClangDatabase -Project="%s" -game -engine "%s" Development Win64',
        engine_path,
        u_project_path,
        target
    )

    Job:new({
        command = clang_cmd,
        on_exit = function()
            notify("Clang database generation completed", "info", { title = "Clang Database" })
            local generated_file_path = engine_path .. "\\compile_commands.json"
            local target_file_path = build_params.project_path .. "\\compile_commands.json"

            if vim.fn.filereadable(target_file_path) == 1 then
                local remove_ok, remove_err = os.remove(target_file_path)
                if not remove_ok then
                    notify("Error removing existing file: " .. remove_err, "error", { title = "File Operation Error" })
                    return
                end
            end

            local ok, err = os.rename(generated_file_path, target_file_path)
            if not ok then
                notify("Error copying file: " .. err, "error", { title = "File Operation Error" })
            else
                notify("File copied successfully", "info", { title = "File Operation" })
            end
        end,
    }):start()
end

function M.unreal_build_toggle()
    run_build_command(run_clang_database_command)
end

local run_terminal

function M.unreal_run()
    if not run_terminal then
        run_terminal = Terminal:new({
            direction = "horizontal",
            close_on_exit = true,
        })
    end

    run_terminal.cmd = string.format(
        '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
        engine_path,
        u_project_path
    )
    notify("Launching Unreal Editor...", "info", { title = "Unreal Editor" })
    run_terminal:toggle()
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
