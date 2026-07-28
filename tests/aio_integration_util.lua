local M = {}

M.wow_stub = dofile((debug.getinfo(1, "S").source:match("@?(.*[/\\])") or "./") .. "wow_stub.lua")

local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])") or "./"
M.root = script_path .. "../"
M.base_package_path = package.path

function M.add_path(dir)
    package.path = dir .. "?.lua;" .. package.path
end

function M.aio_prefixes()
    local p = string.sub("AIO", 1, 16)
    return string.sub("S" .. p, 1, 16), string.sub("C" .. p, 1, 16)
end

function M.short_wire(wire)
    local framing = require("aio_framing")
    return framing.SHORT_TAG .. wire
end

function M.load_aio_from(side_dir, deps_fn, install_env)
    M.wow_stub.clear_packages()
    package.path = M.base_package_path
    if install_env then
        install_env()
    end
    M.add_path(M.root .. side_dir)
    M.add_path(M.root .. side_dir .. "Dep_Smallfolk/")
    M.add_path(M.root .. side_dir .. "lualzw-zeros/")
    if deps_fn then
        deps_fn(function(dir)
            M.add_path(M.root .. dir)
        end)
    end
    return require("AIO")
end

function M.last_addon_msg(dir)
    for i = #M.wow_stub.addon_messages, 1, -1 do
        local m = M.wow_stub.addon_messages[i]
        if m.dir == dir then
            return m
        end
    end
    return nil
end

-- Count calls to the built-in print without replacing _G.print (Lua 5.4-safe).
function M.count_builtin_print_calls(fn)
    local builtin_print = print
    local n = 0
    local old_hook, old_mask, old_count = debug.gethook()
    debug.sethook(function(event)
        if event == "call" then
            local info = debug.getinfo(2, "f")
            if info and info.func == builtin_print then
                n = n + 1
            end
        end
    end, "c")
    local ok, err = pcall(fn)
    if old_hook then
        debug.sethook(old_hook, old_mask, old_count)
    else
        debug.sethook()
    end
    if not ok then
        error(err)
    end
    return n
end

return M
