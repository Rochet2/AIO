--[[
    Stateful reassembly of framed long messages with TTL and optional per-peer byte caps.
]]

local tconcat = table.concat

local M = {}

function M.new(opts)
    assert(opts.framing, "framing required")
    assert(opts.NewQueue, "NewQueue required")
    assert(opts.get_time, "get_time required")
    assert(opts.get_time_diff, "get_time_diff required")
    assert(opts.get_message_stored_size, "get_message_stored_size required")
    assert(opts.cache_time_ms, "cache_time_ms required")

    local framing = opts.framing
    local create_queue = opts.NewQueue
    local get_time = opts.get_time
    local get_time_diff = opts.get_time_diff
    local get_message_stored_size = opts.get_message_stored_size
    local cache_space = opts.cache_space
    local cache_time_ms = opts.cache_time_ms
    local msg_id_min = opts.msg_id_min or 1
    local msg_id_max = opts.msg_id_max or 2^16 - 767

    local plrdata = {}
    local removeque = create_queue()

    local function remove_data(peer_id, msgid)
        local pdata = plrdata[peer_id]
        if not pdata then
            return
        end
        if msgid then
            local data = pdata[msgid]
            if data then
                pdata.stored = pdata.stored - get_message_stored_size(data)
                if pdata.stored < 0 then
                    pdata.stored = 0
                end
                pdata[msgid] = nil
                pdata.ramque:gettable()[data.ramquepos] = nil
                removeque:gettable()[data.remquepos] = nil
            end
        else
            local que = pdata.ramque:gettable()
            local l, r = pdata.ramque:getrange()
            for i = l, r do
                if que[i] then
                    removeque:gettable()[que[i].remquepos] = nil
                end
            end
            plrdata[peer_id] = nil
        end
    end

    local function ensure_peer(peer_id)
        if not plrdata[peer_id] then
            plrdata[peer_id] = {
                stored = 0,
                ramque = create_queue(),
                MSG_GUID = msg_id_min,
            }
        end
        return plrdata[peer_id]
    end

    local function bump_send_id(pdata)
        if pdata.MSG_GUID >= msg_id_max then
            pdata.MSG_GUID = msg_id_min
        else
            pdata.MSG_GUID = pdata.MSG_GUID + 1
        end
    end

    local function all_parts_present(parts)
        for i = 1, parts.n do
            if not parts[i] then
                return false
            end
        end
        return true
    end

    local reassembler = {}

    function reassembler.split_payload(_, peer_id, payload)
        local pdata = ensure_peer(peer_id)
        local message_id = pdata.MSG_GUID
        local packets = framing:split(payload, message_id)
        bump_send_id(pdata)
        return packets
    end

    function reassembler.ingest(_, peer_id, packet)
        local complete, chunk = framing:parse(packet)
        if complete then
            return complete
        end
        if not chunk then
            return nil
        end

        local message_id = chunk.message_id
        local parts = chunk.parts
        local part_id = chunk.part_id
        local msg = chunk.payload

        local pdata = ensure_peer(peer_id)
        pdata[message_id] = pdata[message_id] or {}
        local data = pdata[message_id]

        if not data.parts or data.parts.n ~= parts then
            if data.parts then
                for i = 0, data.parts.n do
                    data.parts[i] = nil
                end
            end
            data.peer_id = peer_id
            data.parts = { n = parts }
            data.id = message_id
            data.stamp = get_time()
            data.remquepos = removeque:pushright(data)
            data.ramquepos = pdata.ramque:pushright(data)
        end

        data.parts[part_id] = msg

        pdata.stored = pdata.stored + #msg
        if cache_space and pdata.stored > cache_space then
            local l, r = pdata.ramque:getrange()
            for i = l, r - 1 do
                local msgdata = pdata.ramque:popleft()
                if msgdata then
                    removeque:gettable()[msgdata.remquepos] = nil
                    pdata[msgdata.id] = nil
                    for j = 1, msgdata.parts.n do
                        if msgdata.parts[j] then
                            pdata.stored = pdata.stored - #msgdata.parts[j]
                        end
                    end
                    if pdata.stored <= cache_space then
                        break
                    end
                end
            end
            if pdata.stored > cache_space then
                remove_data(peer_id)
                error("AIO_MSG_CACHE_SPACE is too small for received message")
            end
        end

        if all_parts_present(data.parts) then
            local cat = tconcat(data.parts)
            remove_data(peer_id, message_id)
            return cat
        end

        return nil
    end

    function reassembler.remove_peer(_, peer_id)
        remove_data(peer_id)
    end

    function reassembler.remove_message(_, peer_id, message_id)
        remove_data(peer_id, message_id)
    end

    function reassembler.sweep_expired(_)
        if removeque:empty() then
            return
        end
        local now = get_time()
        local l, r = removeque:getrange()
        for i = l, r do
            local v = removeque:popleft()
            if v then
                if get_time_diff(now, v.stamp) < cache_time_ms then
                    removeque:pushleft(v)
                    break
                end
                remove_data(v.peer_id, v.id)
            end
        end
    end

    return reassembler
end

return M
