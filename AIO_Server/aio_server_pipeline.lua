--[[
    Server-only: addon build (obfuscate/compress), init handshake, addon push to clients.
]]

local M = {}

function M.add_addon_file(ctx, path, name)
    path = path or debug.getinfo(2, "S").source:sub(2)
    name = name or ctx.aio_util.basename(path)
    local code = M.read_file(ctx, path)
    ctx.AIO.AddAddonCode(name, code)
    ctx.AIO_debug("Added addon path&name:", path, name)
    return true
end

function M.read_file(ctx, path)
    ctx.AIO_debug("Reading a file")
    assert(type(path) == "string", "#1 string expected")
    local f = assert(io.open(path, "rb"))
    local str = f:read("*all")
    f:close()
    return str
end

function M.install_main_state(ctx)
    local AIO = ctx.AIO
    local AIO_HANDLERS = ctx.AIO_HANDLERS
    local AIO_ADDONSORDER = ctx.AIO_ADDONSORDER
    local AIO_INITHOOKS = ctx.AIO_INITHOOKS
    local crc32 = require("crc32lua").crc32

    function AIO.AddAddonCode(name, code)
        assert(type(name) == "string", "#1 string expected")
        assert(type(code) == "string", "#2 string expected")
        if ctx.AIO_CODE_OBFUSCATE then
            code = ctx.LuaSrcDiet(code, 3)
        end
        if ctx.AIO_MSG_COMPRESS then
            code = ctx.AIO_Compressed .. assert(ctx.lualzw.compress(code))
        else
            code = ctx.AIO_Uncompressed .. code
        end
        AIO_ADDONSORDER[#AIO_ADDONSORDER + 1] = { name = name, crc = crc32(code), code = code }
    end

    function AIO.AddOnInit(func)
        assert(type(func) == "function", "#1 function expected")
        table.insert(AIO_INITHOOKS, func)
    end

    local timers = {}
    local function RemoveInitTimer(_, playerguid)
        if type(playerguid) == "number" then
            timers[playerguid] = nil
        end
    end

    local versionmsg = ctx.AIO_Msg():Add("AIO", "Init", ctx.AIO_VERSION)
    function AIO_HANDLERS.Init(player, version, clientdata)
        local guid = player:GetGUIDLow()
        if timers[guid] then
            return
        end

        timers[guid] = CreateLuaEvent(function(e)
            RemoveInitTimer(e, guid)
        end, ctx.AIO_UI_INIT_DELAY, 1)

        if version ~= ctx.AIO_VERSION then
            versionmsg:Send(player)
            return
        end

        local istable = type(clientdata) == "table"
        local addons = {}
        local cached = {}
        for i = 1, #AIO_ADDONSORDER do
            local data = AIO_ADDONSORDER[i]
            local clientcrc = istable and clientdata[data.name] or nil
            if clientcrc and clientcrc == data.crc then
                cached[i] = data.name
            else
                addons[i] = data
            end
        end

        local initmsg = ctx.AIO_Msg():Add("AIO", "Init", ctx.AIO_VERSION, #AIO_ADDONSORDER, addons, cached)
        for _, hook in ipairs(AIO_INITHOOKS) do
            initmsg = hook(initmsg, player) or initmsg
        end
        initmsg:Send(player)
    end

    function AIO_HANDLERS.Error(_, errmsg)
        if type(errmsg) ~= "string" then
            return
        end
        PrintInfo(errmsg)
    end

    local function ONADDONMSG(_, sender, _, prefix, msg, target)
        if prefix == ctx.AIO_ClientPrefix and tostring(sender) == tostring(target) and #msg < 510 then
            ctx.AIO_HandleIncomingMsg(msg, sender)
        end
    end

    RegisterServerEvent(30, ONADDONMSG)

    if ctx.AIO_FORCE_RELOAD_ON_STARTUP then
        for _, v in ipairs(GetPlayersInWorld()) do
            AIO.Handle(v, "AIO", "ForceReload")
        end
    end
end

return M
