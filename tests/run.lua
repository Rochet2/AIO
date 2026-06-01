#!/usr/bin/env lua

local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])") or "./"
local root = script_path .. "../"

local function add_path(dir)
    package.path = dir .. "?.lua;" .. package.path
end

add_path(root .. "AIO_Server/Dep_Smallfolk/")
add_path(root .. "AIO_Server/lualzw-zeros/")
add_path(root .. "AIO_Server/")

local passed, failed = 0, 0

function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("  ok: " .. name)
    else
        failed = failed + 1
        print("FAIL: " .. name)
        print("      " .. tostring(err))
    end
end

function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "assert_eq failed") .. ": got " .. tostring(a) .. ", expected " .. tostring(b))
    end
end

function assert_true(v, msg)
    if not v then
        error(msg or "assert_true failed")
    end
end

dofile(script_path .. "test_queue.lua")
dofile(script_path .. "test_smallfolk.lua")
dofile(script_path .. "test_framing.lua")
dofile(script_path .. "test_util.lua")
dofile(script_path .. "test_stored.lua")
dofile(script_path .. "test_path_legacy.lua")
dofile(script_path .. "test_reassembler.lua")
dofile(script_path .. "test_lualzw.lua")
dofile(script_path .. "test_aio_rpc.lua")
dofile(script_path .. "test_aio_core.lua")

print(string.format("\n%d passed, %d failed", passed, failed))
os.exit(failed > 0 and 1 or 0)
