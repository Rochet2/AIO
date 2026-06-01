#!/usr/bin/env lua
-- Local luacheck runner (no luarocks/lfs): uses vendored luacheck under .tmp/luacheck.
local root = arg[0]:match("^(.*)[/\\]") or "."
root = root .. "/../"
package.path = root .. ".tmp/luacheck/src/?.lua;" .. package.path

package.preload["lfs"] = function()
    return {
        attributes = function(path, attr)
            local f = io.open(path, "r")
            if not f then
                return nil
            end
            f:close()
            if attr == "mode" then
                return "file"
            end
            if attr == "modification" then
                return 0
            end
            return {}
        end,
        dir = function(path)
            return function()
                return nil
            end
        end,
        currentdir = function()
            return (os.getenv("CD") or "."):gsub("\\", "/")
        end,
        mkdir = function()
            return true
        end,
    }
end

local config = require("luacheck.config")
local format = require("luacheck.format")
local luacheck = require("luacheck")

local cfg, err = config.load_config(root .. ".luacheckrc", root:sub(1, -2))
if not cfg then
    io.stderr:write("config: " .. tostring(err) .. "\n")
    os.exit(2)
end

local files = {
    "AIO_Server/queue.lua",
    "AIO_Client/queue.lua",
    "AIO_Server/aio_util.lua",
    "AIO_Client/aio_util.lua",
    "AIO_Server/aio_framing.lua",
    "AIO_Client/aio_framing.lua",
    "AIO_Server/aio_reassembler.lua",
    "AIO_Client/aio_reassembler.lua",
    "AIO_Server/aio_rpc.lua",
    "AIO_Client/aio_rpc.lua",
    "AIO_Server/aio_core.lua",
    "AIO_Client/aio_core.lua",
    "AIO_Server/aio_server_pipeline.lua",
    "AIO_Client/aio_client_ui.lua",
    "AIO_Server/AIO.lua",
    "AIO_Client/AIO.lua",
    "tests/run.lua",
    "tests/test_queue.lua",
    "tests/test_smallfolk.lua",
    "tests/test_framing.lua",
    "tests/test_util.lua",
    "tests/test_stored.lua",
    "tests/test_path_legacy.lua",
    "tests/test_reassembler.lua",
    "tests/test_lualzw.lua",
    "tests/test_aio_rpc.lua",
    "tests/test_aio_core.lua",
    "tests/wow_stub.lua",
    "tests/aio_integration_util.lua",
    "tests/test_aio_integration_server.lua",
    "tests/test_aio_integration_client.lua",
}

local paths = {}
for i = 1, #files do
    paths[i] = root .. files[i]
end

local report = luacheck.check_files(paths, cfg.options)
local out = format.format(report, paths, { formatter = "default", color = false, codes = true })
if out ~= "" then
    io.stdout:write(out, "\n")
end

local failed = false
for _, file_report in ipairs(report) do
    if file_report.fatal or #file_report > 0 then
        failed = true
        break
    end
end

os.exit(failed and 1 or 0)
