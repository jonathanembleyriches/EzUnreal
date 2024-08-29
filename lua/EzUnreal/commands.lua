local Job = require('plenary.job')
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

-- Utility function to append logs to a file
local function append_to_log(file_path, output)
    local log_file = io.open(file_path, "a")
    if log_file then
        log_file:write(output .. "\n")
        log_file:close()
    end
end

local function run_build_command(callback)
    local log_file_path = build_params.project_path .. "\\build_log.txt"
    local cmd = string.format(
        'dotnet "%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.dll" %s Win64 Development -Project="%s" -WaitMutex',
        engine_path,
        target,
        u_project_path
    )

    local job = Job:new({
        command = 'cmd.exe',
        args = { '/C', cmd },
        on_stdout = function(_, output)
            append_to_log(log_file_path, output)
        end,
        on_stderr = function(_, output)
            append_to_log(log_file_path, output)
            notify("Build Error: " .. output, "error", { title = "Build Error" })
        end,
        on_exit = function(j, return_val)
            if return_val == 0 then
                notify("Build process completed successfully", "info", { title = "Build Status" })
            else
                notify("Build process failed with errors", "error", { title = "Build Status" })
            end
            if callback then callback() end
        end,
    })

    notify("Starting build process...", "info", { title = "Build Status" })
    job:start()
end

local function run_clang_database_command()
    local log_file_path = build_params.project_path .. "\\clang_database_log.txt"
    local cmd = string.format(
        '"%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe" -mode=GenerateClangDatabase -Project="%s" -game -engine "%s" Development Win64',
        engine_path,
        u_project_path,
        target
    )

    local job = Job:new({
        command = 'cmd.exe',
        args = { '/C', cmd },
        on_stdout = function(_, output)
            append_to_log(log_file_path, output)
        end,
        on_stderr = function(_, output)
            append_to_log(log_file_path, output)
            notify("Clang Database Error: " .. output, "error", { title = "Clang Database Error" })
        end,
        on_exit = function(j, return_val)
            if return_val == 0 then
                notify("Clang database generation completed", "info", { title = "Clang Database" })
                local generated_file_path = engine_path .. "\\compile_commands.json"
                local target_file_path = build_params.project_path .. "\\compile_commands.json"

                -- Check if the target file exists and remove it before renaming
                if vim.fn.filereadable(target_file_path) == 1 then
                    local remove_ok, remove_err = os.remove(target_file_path)
                    if not remove_ok then
                        notify("Error removing existing file: " .. remove_err, "error", { title = "File Operation Error" })
                        append_to_log(log_file_path, "Error removing existing file: " .. remove_err)
                        return
                    end
                end

                local ok, err = os.rename(generated_file_path, target_file_path)
                if not ok then
                    notify("Error copying file: " .. err, "error", { title = "File Operation Error" })
                    append_to_log(log_file_path, "Error copying file: " .. err)
                else
                    notify("File copied successfully", "info", { title = "File Operation" })
                    append_to_log(log_file_path, "File copied successfully")
                end
            else
                notify("Clang database generation failed with errors", "error", { title = "Clang Database" })
            end
        end,
    })

    notify("Starting Clang database generation...", "info", { title = "Clang Database" })
    job:start()
end

function M.unreal_build_toggle()
    run_build_command(run_clang_database_command)
end

function M.unreal_run()
    local log_file_path = build_params.project_path .. "\\unreal_editor_log.txt"
    local cmd = string.format(
        '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
        engine_path,
        u_project_path
    )

    local job = Job:new({
        command = 'cmd.exe',
        args = { '/C', cmd },
        on_stdout = function(_, output)
            append_to_log(log_file_path, output)
        end,
        on_stderr = function(_, output)
            append_to_log(log_file_path, output)
        end,
        on_exit = function(j, return_val)
            if return_val == 0 then
                notify("Unreal Editor exited successfully", "info", { title = "Unreal Editor" })
            else
                notify("Unreal Editor exited with errors", "error", { title = "Unreal Editor" })
            end
        end,
    })

    notify("Launching Unreal Editor...", "info", { title = "Unreal Editor" })
    job:start()
end

local dap = require('dap')

function M.unreal_run2()
    local log_file_path = build_params.project_path .. "\\unreal_editor_dap_log.txt"
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

    dap.listeners.after.event_initialized["log"] = function()
        dap.repl.open()
        dap.repl.run_command("source " .. log_file_path)
    end

    notify("Launching Unreal Editor with DAP...", "info", { title = "Unreal Editor DAP" })
    dap.run(configuration)
end

return M
