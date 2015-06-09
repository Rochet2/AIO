local AIO = AIO or require("AIO")

local HandlePingPong
if AIO.AddAddon() then
    -- we are on server
    
    -- When we receive PingPong message on server, print ping to the sender player
    -- and send pong message to him
    function HandlePingPong(player, msg)
        player:SendBroadcastMessage(tostring(msg))
        AIO.Msg():Add("PingPong", "pong"):Send(player)
    end
else
    -- we are on client
    
    -- store the time we send the ping here
    local senttime

    -- When we receive the PingPong message on client, print pong and the time it took to
    -- go from client to server to client.
    function HandlePingPong(player, msg)
        print(tostring(msg), time()-senttime)
    end
    
    -- just incase we are overwriting someone's function ..
    assert(not Ping, "PingPong: Ping is already defined")
    
    -- Send ping, ingame use /run Ping() to test this script
    function Ping()
        senttime = time()
        AIO.Msg():Add("PingPong", "ping"):Send()
    end
    Ping() -- automatically call on UI load
end

AIO.RegisterEvent("PingPong", HandlePingPong)
