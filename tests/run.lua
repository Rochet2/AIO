#!/usr/bin/env lua

local script_path = debug.getinfo(1, "S").source:match("@?(.*[/\\])") or "./"
local root = script_path .. "../"
local compat = dofile(script_path .. "lua_compat.lua")

local function add_path(dir)
    package.path = dir .. "?.lua;" .. package.path
end

add_path(root .. "AIO_Server/Dep_Smallfolk/")
add_path(root .. "AIO_Server/lualzw-zeros/")
add_path(root .. "AIO_Server/")

local passed, failed, skipped = 0, 0, 0

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

function skip(name, reason)
    skipped = skipped + 1
    print("  skip: " .. name .. " (" .. reason .. ")")
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

if compat.supports_server_aio_tests() then
    dofile(script_path .. "test_aio_integration_server.lua")
else
    skip("server AIO integration suite", "requires Lua 5.1-5.4, got " .. _VERSION)
end

if compat.supports_client_aio_tests() then
    dofile(script_path .. "test_aio_integration_client.lua")
else
    skip("client AIO integration suite", "requires Lua 5.1, got " .. _VERSION)
end

print(string.format("\n%d passed, %d failed, %d skipped (%s)", passed, failed, skipped, _VERSION))
os.exit(failed > 0 and 1 or 0)
