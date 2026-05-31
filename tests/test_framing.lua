-- Mirrors AIO.lua uint16 framing helpers and long-message split/reassembly.
local floor = math.floor
local ssub = string.sub
local sbyte = string.byte
local schar = string.char
local tconcat = table.concat
local ceil = math.ceil

local AIO_ShortMsg = schar(1) .. schar(1)
local AIO_ServerPrefix = "SAIO"
local AIO_MsgLen = 255 - 1 - #AIO_ServerPrefix - #AIO_ShortMsg

local function AIO_16tostring(uint16)
    assert(uint16 <= 2^16 - 767, "Too high value")
    assert(uint16 >= 0, "Negative value")
    local high = floor(uint16 / 254)
    local l = high + 1
    local r = uint16 - high * 254 + 1
    return schar(l) .. schar(r)
end

local function AIO_stringto16(str)
    local l = sbyte(ssub(str, 1, 1)) - 1
    local r = sbyte(ssub(str, 2, 2)) - 1
    local val = l * 254 + r
    assert(val <= 2^16 - 767, "Too high value")
    assert(val >= 0, "Negative value")
    return val
end

local function split_message(msg, msg_guid)
    if #msg <= AIO_MsgLen then
        return {AIO_ShortMsg .. msg}
    end

    local msglen = AIO_MsgLen - 4
    local parts = ceil(#msg / msglen)
    local header = AIO_16tostring(msg_guid) .. AIO_16tostring(parts)
    local packets = {}

    for i = 1, parts do
        packets[i] = header .. AIO_16tostring(i) .. ssub(msg, ((i - 1) * msglen) + 1, i * msglen)
    end

    return packets
end

local function assemble_message(packet)
    local msgid = ssub(packet, 1, 2)

    if msgid == AIO_ShortMsg then
        return ssub(packet, 3)
    end

    if #packet < 6 then
        return nil
    end

    local parts = AIO_stringto16(ssub(packet, 3, 4))
    local part_id = AIO_stringto16(ssub(packet, 5, 6))
    assert(part_id >= 1 and part_id <= parts)

    return {
        message_id = AIO_stringto16(msgid),
        parts = parts,
        part_id = part_id,
        payload = ssub(packet, 7),
    }
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
        assert_eq(AIO_stringto16(AIO_16tostring(value)), value, "roundtrip " .. value)
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
