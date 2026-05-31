--[[
    WoW addon-message framing: uint16 packing without NUL and split/rejoin for size limits.
]]

local floor = math.floor
local ssub = string.sub
local sbyte = string.byte
local schar = string.char
local ceil = math.ceil

local M = {}

-- Short-message tag (2 bytes); must not collide with uint16 message IDs used for long messages.
M.SHORT_TAG = schar(1) .. schar(1)

function M.uint16_encode(uint16)
    assert(uint16 <= 2^16 - 767, "Too high value")
    assert(uint16 >= 0, "Negative value")
    local high = floor(uint16 / 254)
    local l = high + 1
    local r = uint16 - high * 254 + 1
    return schar(l) .. schar(r)
end

function M.uint16_decode(str)
    local l = sbyte(ssub(str, 1, 1)) - 1
    local r = sbyte(ssub(str, 2, 2)) - 1
    local val = l * 254 + r
    assert(val <= 2^16 - 767, "Too high value")
    assert(val >= 0, "Negative value")
    return val
end

-- max_payload: max bytes per wire packet body (after channel prefix accounting).
function M.new(max_payload)
    local short_tag = M.SHORT_TAG
    local uint16_encode = M.uint16_encode
    local uint16_decode = M.uint16_decode

    local framing = {
        max_payload = max_payload,
    }

    function framing.split(_, payload, message_id)
        if #payload <= max_payload then
            return { short_tag .. payload }
        end

        local msglen = max_payload - 4
        local part_count = ceil(#payload / msglen)
        local header = uint16_encode(message_id) .. uint16_encode(part_count)
        local packets = {}

        for i = 1, part_count do
            packets[i] = header .. uint16_encode(i) .. ssub(payload, ((i - 1) * msglen) + 1, i * msglen)
        end

        return packets
    end

    -- Returns complete payload string, or nil if packet is too short / incomplete chunk.
    -- On incomplete long message, returns nil, chunk_table (for tests); production uses reassembler.
    function framing.parse(_, packet)
        local msgid = ssub(packet, 1, 2)

        if msgid == short_tag then
            return ssub(packet, 3)
        end

        if #packet < 6 then
            return nil
        end

        local message_id = uint16_decode(msgid)
        local parts = uint16_decode(ssub(packet, 3, 4))
        local part_id = uint16_decode(ssub(packet, 5, 6))
        if part_id <= 0 or part_id > parts then
            error("received long message with invalid amount of parts. id, parts: " .. part_id .. " " .. parts)
        end

        return nil, {
            message_id = message_id,
            parts = parts,
            part_id = part_id,
            payload = ssub(packet, 7),
        }
    end

    return framing
end

return M
