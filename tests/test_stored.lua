local aio_framing = require("aio_framing")
local aio_reassembler = require("aio_reassembler")
local aio_util = require("aio_util")
local create_queue = require("queue")

local AIO_MsgLen = 200
local framing = aio_framing.new(AIO_MsgLen)

local function make_reassembler(overrides)
    local opts = {
        framing = framing,
        NewQueue = create_queue,
        get_time = function() return 1000 end,
        get_time_diff = function(now, then_) return now - then_ end,
        get_message_stored_size = aio_util.getMessageStoredSize,
        is_message_expired = aio_util.isMessageExpired,
        cache_space = 5e5,
        cache_time_ms = 15000,
    }
    if overrides then
        for k, v in pairs(overrides) do
            opts[k] = v
        end
    end
    return aio_reassembler.new(opts)
end

test("remove_message subtracts stored bytes for incomplete message", function()
    local r = make_reassembler()
    local payload = string.rep("z", AIO_MsgLen + 50)
    local packets = framing:split(payload, 7)
    assert_true(#packets > 1)

    assert_eq(r:ingest(42, packets[1]), nil)
    local stored_after_part = r:get_stored(42)
    assert_true(stored_after_part > 0)

    r:remove_message(42, 7)
    assert_eq(r:get_stored(42), 0)
end)

test("completing a long message clears stored bytes", function()
    local r = make_reassembler()
    local payload = string.rep("a", AIO_MsgLen + 50)
    local packets = framing:split(payload, 3)

    local assembled
    for i = 1, #packets do
        assembled = r:ingest(1, packets[i])
        if i < #packets then
            assert_true(r:get_stored(1) > 0)
        end
    end
    assert_eq(assembled, payload)
    assert_eq(r:get_stored(1), 0)
end)

test("remove_message clamps stored at zero", function()
    local r = make_reassembler({
        get_message_stored_size = function(data)
            return aio_util.getMessageStoredSize(data) + 100
        end,
    })
    local payload = string.rep("x", AIO_MsgLen + 10)
    local packets = framing:split(payload, 1)
    assert_eq(r:ingest(9, packets[1]), nil)
    assert_true(r:get_stored(9) > 0)

    r:remove_message(9, 1)
    assert_eq(r:get_stored(9), 0)
end)
