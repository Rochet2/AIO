local aio_util = require("aio_util")

local function makeRemoveData()
    local plrdata = {}

    local function RemoveData(guid, msgid)
        local pdata = plrdata[guid]
        if not pdata then
            return
        end
        if msgid then
            local data = pdata[msgid]
            if data then
                pdata.stored = pdata.stored - aio_util.getMessageStoredSize(data)
                if pdata.stored < 0 then
                    pdata.stored = 0
                end
                pdata[msgid] = nil
            end
        else
            plrdata[guid] = nil
        end
    end

    return plrdata, RemoveData
end

test("RemoveData subtracts stored bytes for completed message", function()
    local plrdata, RemoveData = makeRemoveData()
    local guid = 42
    plrdata[guid] = {stored = 0}
    plrdata[guid][7] = {
        parts = {
            n = 2,
            [1] = string.rep("a", 100),
            [2] = string.rep("b", 50),
        },
    }
    plrdata[guid].stored = 150

    RemoveData(guid, 7)

    assert_eq(plrdata[guid].stored, 0)
    assert_eq(plrdata[guid][7], nil)
end)

test("RemoveData clamps stored at zero", function()
    local plrdata, RemoveData = makeRemoveData()
    local guid = 1
    plrdata[guid] = {stored = 10}
    plrdata[guid][1] = {
        parts = {
            n = 1,
            [1] = string.rep("x", 100),
        },
    }

    RemoveData(guid, 1)

    assert_eq(plrdata[guid].stored, 0)
end)
