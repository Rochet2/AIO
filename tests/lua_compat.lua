--[[
    Lua version policy for AIO tests (see tests/run.lua):
    - Server AIO integration: Lua 5.1 through 5.4
    - Client AIO integration: Lua 5.1 only
]]

local M = {}

function M.version_number()
    local maj, min = _VERSION:match("^Lua (%d+)%.(%d+)")
    if not maj then
        return nil
    end
    return tonumber(maj) * 100 + tonumber(min)
end

function M.supports_server_aio_tests()
    local v = M.version_number()
    return v ~= nil and v >= 501 and v <= 504
end

function M.supports_client_aio_tests()
    return M.version_number() == 501
end

return M
