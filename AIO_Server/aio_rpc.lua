--[[
    Block-oriented RPC over a serialized message blob (Smallfolk by default).
]]

local unpack = _G.unpack or table.unpack

local M = {}

function M.new(opts)
    assert(opts["dumps"], "dumps required")
    assert(opts["loads"], "loads required")
    assert(opts["pcall"], "pcall required")
    assert(opts["get_handlers"], "get_handlers required")

    local dumps = opts["dumps"]
    local loads = opts["loads"]
    local pcall_fn = opts["pcall"]
    local get_handlers = opts["get_handlers"]
    local debug_fn = opts["debug"] or function() end
    local enable_msgprint = opts["enable_msgprint"]
    local server = opts["server"]
    local max_block_args = opts["max_block_args"] or 15
    local timeout_hook = opts["timeout_hook"]

    local send_fn
    local msgmt = {}
    function msgmt.__index(_, key)
        return msgmt[key]
    end

    function msgmt:Add(name, ...)
        assert(name, "#1 Block must have name")
        self.params[#self.params + 1] = { select("#", ...), name, ... }
        self.assemble = true
        return self
    end

    function msgmt:Append(msg2)
        assert(type(msg2) == "table", "#1 table expected")
        for i = 1, #msg2.params do
            assert(type(msg2.params[i]) == "table", "#1[" .. i .. "] table expected")
            self.params[#self.params + 1] = msg2.params[i]
        end
        self.assemble = true
        return self
    end

    function msgmt:Assemble()
        if not self.assemble then
            return self
        end
        self.MSG = dumps(self.params)
        self.assemble = false
        return self
    end

    function msgmt:Send(player, ...)
        assert(not server or player, "#1 player is nil")
        assert(send_fn, "send not bound")
        send_fn(self:ToString(), player, ...)
        return self
    end

    function msgmt:Clear()
        for i = 1, #self.params do
            self.params[i] = nil
        end
        self.MSG = nil
        self.assemble = false
        return self
    end

    function msgmt:ToString()
        return self:Assemble().MSG
    end

    function msgmt:HasMsg()
        return #self.params > 0
    end

    local function handle_block(player, data)
        local handle_name = data[2]
        assert(handle_name, "Invalid handle, no handle name")

        local handledata = get_handlers()[handle_name]
        if not handledata then
            error("Unknown AIO block handle: '" .. tostring(handle_name) .. "'")
        end

        if server and data[1] > max_block_args then
            error("Received AIO block with over " .. max_block_args .. " arguments. Try using tables instead")
        end
        handledata(player, unpack(data, 3, data[1] + 2))
    end

    local function parse_blocks(msg, player, on_block)
        local hooked = timeout_hook
        if hooked then
            hooked.begin(msg)
        end

        local ok, err = pcall(function()
            debug_fn("Received messagelength:", #msg)
            if enable_msgprint then
                print("received:", msg)
            end

            local data = pcall_fn(loads, msg, #msg)
            if not data or type(data) ~= "table" then
                debug_fn("Received invalid message - data not a table")
                return
            end

            for i = 1, #data do
                local block = data[i]
                if on_block then
                    on_block(player, block)
                else
                    pcall_fn(handle_block, player, block)
                end
            end
        end)

        if hooked then
            hooked["end"]()
        end

        if not ok then
            error(err)
        end
    end

    local rpc = {}

    function rpc.Msg()
        local msg = { params = {}, MSG = nil, assemble = false }
        setmetatable(msg, msgmt)
        return msg
    end

    function rpc.bind_send(fn)
        send_fn = fn
    end

    rpc.handle_block = handle_block
    rpc.parse_blocks = parse_blocks

    return rpc
end

return M
