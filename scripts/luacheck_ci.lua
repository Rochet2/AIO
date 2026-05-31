#!/usr/bin/env lua
-- CI runner: use luarocks-installed luacheck (Lua 5.1) with .luacheckrc.
local check = require("luacheck.check")
local config = require("luacheck.config")
local format = require("luacheck.format")

local root = table.remove(arg, 1) or "."
local cfg, err = config.load_config(root .. "/.luacheckrc", root)
if not cfg then
    io.stderr:write("failed to load .luacheckrc: " .. tostring(err) .. "\n")
    os.exit(2)
end

local failed = false
for i = 1, #arg do
    local path = arg[i]
    local report = check(path, cfg)
    if #report > 0 then
        failed = true
        io.stdout:write(format.report(report, {}, {}))
    end
end

os.exit(failed and 1 or 0)
