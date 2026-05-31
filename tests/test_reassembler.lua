local aio_framing = require("aio_framing")
local aio_reassembler = require("aio_reassembler")
local aio_util = require("aio_util")
local NewQueue = require("queue")

local AIO_MsgLen = 200
local framing = aio_framing.new(AIO_MsgLen)

local function make_reassembler(cache_space)
    return aio_reassembler.new({
        framing = framing,
        NewQueue = NewQueue,
        get_time = function() return 1000 end,
        get_time_diff = function(now, then_) return now - then_ end,
        get_message_stored_size = aio_util.getMessageStoredSize,
        cache_space = cache_space,
        cache_time_ms = 15000,
    })
end

test("reassembler short message ingest", function()
    local r = make_reassembler()
    local packets = framing:split("hello", 1)
    assert_eq(r:ingest(1, packets[1]), "hello")
end)

test("reassembler long message ingest", function()
    local r = make_reassembler()
    local payload = string.rep("z", AIO_MsgLen + 50)
    local packets = framing:split(payload, 7)
    local assembled
    for i = 1, #packets do
        assembled = r:ingest(1, packets[i])
    end
    assert_eq(assembled, payload)
end)

test("reassembler split_payload advances message id", function()
    local r = make_reassembler()
    local long = string.rep("a", AIO_MsgLen + 10)
    local packets1 = r:split_payload(1, long)
    local packets2 = r:split_payload(1, long)
    assert_true(#packets1 > 1)
    local id1 = aio_framing.uint16_decode(string.sub(packets1[1], 1, 2))
    local id2 = aio_framing.uint16_decode(string.sub(packets2[1], 1, 2))
    assert_eq(id2, id1 + 1)
end)
