
local Job = require('plenary.job')
local Terminal = require('toggleterm.terminal').Terminal

local M = {}

local function load_build_params()
    local params_file = vim.fn.getcwd() .. '/build_params.lua'
    local params = loadfile(params_file)
    if params then
        return params()
    else
        error("Could not load build parameters from " .. params_file)
    end
end

local build_params = load_build_params()
local engine_path = build_params.engine_path
local target = build_params.project_name .. "Editor"
local u_project_path = build_params.project_path .. "\\" .. build_params.project_name .. ".uproject"

local function run_build_command(callback)
    local build_terminal = Terminal:new({
        cmd = string.format(
            'dotnet "%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.dll" %s Win64 Development -Project="%s" -WaitMutex',
            engine_path,
            target,
            u_project_path
        ),
        direction = "horizontal",
        close_on_exit = true,
        on_close = function()
            print("Build process completed")
            if callback then callback() end
        end,
    })
    build_terminal:toggle()
end

local function run_clang_database_command()
    local clang_terminal = Terminal:new({
        cmd = string.format(
            '"%s\\Engine\\Binaries\\DotNET\\UnrealBuildTool\\UnrealBuildTool.exe" -mode=GenerateClangDatabase -Project="%s" -game -engine "%s" Development Win64',
            engine_path,
            u_project_path,
            target
        ),
        direction = "horizontal",
        close_on_exit = true,
        on_close = function(term)
            print("Clang database generation completed")
            local generated_file_path = engine_path .. "\\compile_commands.json"
            local target_file_path = build_params.project_path .. "\\compile_commands.json"

            local ok, err = os.rename(generated_file_path, target_file_path)
            if not ok then
                print("Error copying file: " .. err)
            else
                print("File copied successfully")
            end
        end,
    })
    clang_terminal:toggle()
end

function M.unreal_build_toggle()
    run_build_command(run_clang_database_command)
end
function M.unreal_run()
    local run_term = Terminal:new({
        cmd = string.format(
            '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
            engine_path,
            u_project_path
        ),
        direction = "horizontal",
        close_on_exit = true,
    })
    run_term:toggle()
end


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

    dap.configurations.unreal = {
        {
            name = "Launch Unreal Editor",
            type = "unreal_editor",
            request = "launch",
            program = function()
                return string.format(
                    '"%s\\Engine\\Binaries\\Win64\\UnrealEditor.exe" "%s"',
                    engine_path,
                    u_project_path
                )
            end,
            cwd = vim.fn.getcwd(),
            stopOnEntry = false,
        },
    }

    dap.continue()
end


return M
