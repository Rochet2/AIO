local aio_framing = require("aio_framing")

local tconcat = table.concat

local AIO_ServerPrefix = "SAIO"
local AIO_MsgLen = 255 - 1 - #AIO_ServerPrefix - #aio_framing.SHORT_TAG
local framing = aio_framing.new(AIO_MsgLen)
local uint16_encode = aio_framing.uint16_encode
local uint16_decode = aio_framing.uint16_decode

local function split_message(msg, msg_guid)
    return framing:split(msg, msg_guid)
end

local function assemble_message(packet)
    local complete, chunk = framing:parse(packet)
    if complete then
        return complete
    end
    return chunk
end

local function reassemble_long(chunks)
    table.sort(chunks, function(a, b) return a.part_id < b.part_id end)
    local payloads = {}
    for i = 1, #chunks do
        payloads[i] = chunks[i].payload
    end
    return tconcat(payloads)
end

test("framing uint16 roundtrip", function()
    for _, value in ipairs({0, 1, 255, 1000, 64769}) do
        assert_eq(uint16_decode(uint16_encode(value)), value, "roundtrip " .. value)
    end
end)

test("framing short message unchanged", function()
    local msg = "short payload"
    local packets = split_message(msg, 1)
    assert_eq(#packets, 1)
    assert_eq(assemble_message(packets[1]), msg)
end)

test("framing long message split and reassemble", function()
    local msg = string.rep("x", AIO_MsgLen + 100)
    local packets = split_message(msg, 42)
    assert_true(#packets > 1)

    local chunks = {}
    for i = 1, #packets do
        chunks[i] = assemble_message(packets[i])
    end

    assert_eq(chunks[1].parts, #packets)
    assert_eq(reassemble_long(chunks), msg)
end)
