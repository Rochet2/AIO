local unpack = _G.unpack or table.unpack -- luacheck: ignore 143
local smallfolk = require("smallfolk")
local aio_rpc = require("aio_rpc")

-- Match AIO_pcall: return values on success, nil on failure (not ok, err).
local function aio_pcall(f, ...)
    local results = {pcall(f, ...)}
    if not results[1] then
        return nil
    end
    return unpack(results, 2, #results)
end

local function make_rpc(opts)
    opts = opts or {}
    local handlers = opts.handlers or {}
    return aio_rpc.new({
        dumps = smallfolk.dumps,
        loads = smallfolk.loads,
        pcall = aio_pcall,
        get_handlers = function()
            return handlers
        end,
        server = opts.server,
        max_block_args = opts.max_block_args,
        timeout_hook = opts.timeout_hook,
        enable_msgprint = opts.enable_msgprint,
    })
end

test("rpc Msg Add ToString and HasMsg", function()
    local rpc = make_rpc({ handlers = {} })
    local msg = rpc.Msg():Add("Ping", "hello")
    assert_true(msg:HasMsg())
    local wire = msg:ToString()
    assert_true(#wire > 0)
    local params = smallfolk.loads(wire)
    assert_eq(params[1][2], "Ping")
    assert_eq(params[1][3], "hello")
end)

test("rpc Msg Clear resets state", function()
    local rpc = make_rpc({ handlers = {} })
    local msg = rpc.Msg():Add("A", 1):Clear()
    assert_true(not msg:HasMsg())
    assert_eq(msg:ToString(), nil)
end)

test("rpc Msg Append merges blocks", function()
    local rpc = make_rpc({ handlers = {} })
    local a = rpc.Msg():Add("One", 1)
    local b = rpc.Msg():Add("Two", 2)
    local wire = a:Append(b):ToString()
    local params = smallfolk.loads(wire)
    assert_eq(#params, 2)
    assert_eq(params[1][2], "One")
    assert_eq(params[2][2], "Two")
end)

test("rpc parse_blocks dispatches handler", function()
    local seen = {}
    local rpc = make_rpc({
        handlers = {
            Echo = function(player, a, b)
                seen.player = player
                seen.a = a
                seen.b = b
            end,
        },
    })
    local wire = rpc.Msg():Add("Echo", "x", 3):ToString()
    rpc.parse_blocks(wire, 42)
    assert_eq(seen.player, 42)
    assert_eq(seen.a, "x")
    assert_eq(seen.b, 3)
end)

test("rpc parse_blocks uses on_block when provided", function()
    local blocks = {}
    local rpc = make_rpc({ handlers = { H = function() end } })
    local wire = rpc.Msg():Add("H", 1):Add("H", 2):ToString()
    rpc.parse_blocks(wire, nil, function(player, block)
        blocks[#blocks + 1] = block
    end)
    assert_eq(#blocks, 2)
    assert_eq(blocks[1][2], "H")
    assert_eq(blocks[1][3], 1)
end)

test("rpc parse_blocks ignores non-table payload", function()
    local rpc = make_rpc({ handlers = { H = function()
        error("should not run")
    end } })
    rpc.parse_blocks("not valid smallfolk", 1)
end)

test("rpc unknown handler raises via handle_block", function()
    local rpc = make_rpc({ handlers = {} })
    local ok = pcall(rpc.handle_block, 1, { 1, "Missing", 1 })
    assert_true(not ok)
end)

test("rpc server max_block_args enforced via handle_block", function()
    local rpc = make_rpc({
        server = true,
        max_block_args = 2,
        handlers = { H = function() end },
    })
    local ok = pcall(rpc.handle_block, 1, { 3, "H", 1, 2, 3 })
    assert_true(not ok)
end)

test("rpc timeout_hook begin and end", function()
    local log = {}
    local rpc = make_rpc({
        handlers = { H = function() end },
        timeout_hook = {
            begin = function(msg)
                log.begin = #msg
            end,
            ["end"] = function()
                log.ended = true
            end,
        },
    })
    local wire = rpc.Msg():Add("H", 1):ToString()
    rpc.parse_blocks(wire, 1)
    assert_true(log.begin > 0)
    assert_true(log.ended)
end)

test("rpc bind_send Send on client", function()
    local sent = {}
    local rpc = make_rpc({ handlers = {} })
    rpc.bind_send(function(payload, player, channel)
        sent.payload = payload
        sent.player = player
        sent.channel = channel
    end)
    rpc.Msg():Add("A", 1):Send(nil, "CHAN")
    assert_true(sent.payload ~= nil)
    assert_eq(sent.player, nil)
    assert_eq(sent.channel, "CHAN")
end)

test("rpc server Send requires player", function()
    local rpc = make_rpc({ handlers = {}, server = true })
    rpc.bind_send(function() end)
    local ok = pcall(function()
        rpc.Msg():Add("A", 1):Send(nil)
    end)
    assert_true(not ok)
end)
