--[[
    Client-only: addon cache, SavedVariables, init/reload UI, incoming addon messages.
]]

local M = {}

function M.install(ctx)
    local AIO = ctx.AIO
    local AIO_HANDLERS = ctx.AIO_HANDLERS
    local ssub = ctx.ssub
    local AIO_pcall = ctx.AIO_pcall
    local AIO_debug = ctx.AIO_debug

    function ctx.AIO_RESET()
        ctx.AIO_client_state.AIO_PENDING_RESET = true
        ctx.AIO_client_state.AIO_VERSION_MISMATCH = false
        if ctx.AIO_SAVEDVARS then
            for key in pairs(ctx.AIO_SAVEDVARS) do
                _G[key] = nil
            end
        end
        if ctx.AIO_SAVEDVARSCHAR then
            for key in pairs(ctx.AIO_SAVEDVARSCHAR) do
                _G[key] = nil
            end
        end
        AIO_sv_Addons = nil
        ctx.AIO_SAVEDFRAMES = {}
    end

    function AIO.AddSavedVar(key)
        assert(key ~= nil, "#1 table key expected")
        ctx.AIO_SAVEDVARS[key] = true
    end

    function AIO.AddSavedVarChar(key)
        assert(key ~= nil, "#1 table key expected")
        ctx.AIO_SAVEDVARSCHAR[key] = true
    end

    AIO_FRAMEPOSITIONS = AIO_FRAMEPOSITIONS or {}
    AIO.AddSavedVar("AIO_FRAMEPOSITIONS")
    AIO_FRAMEPOSITIONSCHAR = AIO_FRAMEPOSITIONSCHAR or {}
    AIO.AddSavedVarChar("AIO_FRAMEPOSITIONSCHAR")

    function AIO.SavePosition(frame, char)
        assert(frame:GetName(), "Called AIO.SavePosition on a nameless frame")
        local store = char and AIO_FRAMEPOSITIONSCHAR or AIO_FRAMEPOSITIONS
        if not store[frame:GetName()] then
            store[frame:GetName()] = {}
        end
        ctx.LibWindow.RegisterConfig(frame, store[frame:GetName()])
        ctx.LibWindow.RestorePosition(frame)
        ctx.LibWindow.SavePosition(frame)
        table.insert(ctx.AIO_SAVEDFRAMES, frame)
    end

    local function ONADDONMSG(_, event, prefix, msg, _, sender)
        if prefix == ctx.AIO_ServerPrefix then
            if event == "CHAT_MSG_ADDON" and sender == UnitName("player") then
                ctx.AIO_HandleIncomingMsg(msg, sender)
            end
        end
    end
    local MsgReceiver = CreateFrame("Frame")
    MsgReceiver:RegisterEvent("CHAT_MSG_ADDON")
    MsgReceiver:SetScript("OnEvent", ONADDONMSG)

    local function RunAddon(name)
        local code = AIO_sv_Addons[name] and AIO_sv_Addons[name].code
        assert(code, "Addon doesnt exist")
        local compression, compressedcode = ssub(code, 1, 1), ssub(code, 2)
        if compression == ctx.AIO_Compressed then
            compressedcode = assert(ctx.lualzw.decompress(compressedcode))
        end
        assert(loadstring(compressedcode, name))()
    end

    function AIO_HANDLERS.Init(_, version, N, addons, cached)
        if ctx.AIO_VERSION ~= version then
            if not ctx.AIO_client_state.AIO_VERSION_MISMATCH then
                ctx.AIO_client_state.AIO_VERSION_MISMATCH = true
                print("You have AIO version " .. ctx.AIO_VERSION .. " and the server uses " .. (version or "nil") .. ". Get the same version")
            end
            return
        end
        ctx.AIO_client_state.AIO_VERSION_MISMATCH = false

        assert(type(N) == "number")
        assert(type(addons) == "table")
        assert(type(cached) == "table")

        local validAddons = {}
        for i = 1, N do
            local name
            if addons[i] then
                name = addons[i].name
                AIO_sv_Addons[name] = addons[i]
                validAddons[name] = true
            elseif cached[i] then
                name = cached[i]
                validAddons[name] = true
            else
                error("Unexpected behavior, try /aio reset")
            end
            AIO_pcall(RunAddon, name)
        end

        local invalidAddons = {}
        for name in pairs(AIO_sv_Addons) do
            if not validAddons[name] then
                invalidAddons[#invalidAddons + 1] = name
            end
        end
        for i = 1, #invalidAddons do
            AIO_sv_Addons[invalidAddons[i]] = nil
        end

        ctx.AIO_client_state.AIO_INITED = true
        print("Initialized AIO version " .. ctx.AIO_VERSION .. ". Type '/aio help' for commands")
    end

    function AIO_HANDLERS.ForceReload(_)
        local frame = CreateFrame("BUTTON")
        frame:SetToplevel(true)
        frame:SetFrameStrata("TOOLTIP")
        frame:SetFrameLevel(100)
        frame:SetAllPoints(WorldFrame)
        frame:SetScript("OnClick", ReloadUI)
        print("AIO: Force reloading UI")
        message("AIO: Force reloading UI")
    end

    function AIO_HANDLERS.ForceReset(_)
        ctx.AIO_RESET()
        AIO_HANDLERS.ForceReload()
    end

    local frame = CreateFrame("FRAME")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGOUT")

    function frame:OnEvent(event, addon)
        if event == "ADDON_LOADED" and addon == "AIO_Client" then
            local _, _, _, tocversion = GetBuildInfo()
            if tocversion and tocversion >= 40100 and RegisterAddonMessagePrefix then
                RegisterAddonMessagePrefix("C" .. ctx.AIO_Prefix)
            end

            if type(AIO_sv) ~= "table" then
                AIO_sv = {}
            end
            if type(AIO_sv_char) ~= "table" then
                AIO_sv_char = {}
            end
            if type(AIO_sv_Addons) ~= "table" then
                AIO_sv_Addons = {}
            end

            if ctx.AIO_client_state.AIO_PENDING_RESET then
                AIO_sv = {}
                AIO_sv_char = {}
                AIO_sv_Addons = {}
                ctx.AIO_client_state.AIO_PENDING_RESET = false
                if ctx.AIO_SAVEDVARS then
                    for key in pairs(ctx.AIO_SAVEDVARS) do
                        _G[key] = nil
                    end
                end
                if ctx.AIO_SAVEDVARSCHAR then
                    for key in pairs(ctx.AIO_SAVEDVARSCHAR) do
                        _G[key] = nil
                    end
                end
            else
                for k, v in pairs(AIO_sv) do
                    if _G[k] then
                        AIO_debug("Overwriting global var _G[" .. k .. "] with a saved var")
                    end
                    _G[k] = v
                end
                for k, v in pairs(AIO_sv_char) do
                    if _G[k] then
                        AIO_debug("Overwriting global var _G[" .. k .. "] with a saved character var")
                    end
                    _G[k] = v
                end
            end

            local rem = {}
            local addons = {}
            for name, data in pairs(AIO_sv_Addons) do
                if type(name) ~= "string" or type(data) ~= "table" or type(data.crc) ~= "number" or type(data.code) ~= "string" then
                    table.insert(rem, name)
                else
                    addons[name] = data.crc
                end
            end
            for _, name in ipairs(rem) do
                AIO_sv_Addons[name] = nil
            end

            local initmsg = ctx.AIO_Msg():Add("AIO", "Init", ctx.AIO_VERSION, addons)
            local initInterval = 1
            local initElapsed = 0
            local function ONUPDATE(self, diff)
                if ctx.AIO_client_state.AIO_INITED then
                    self:SetScript("OnUpdate", nil)
                    return
                end
                initElapsed = initElapsed + diff
                if initElapsed >= initInterval then
                    initmsg:Send()
                    initElapsed = 0
                    initInterval = initInterval * 1.5
                end
            end
            frame:SetScript("OnUpdate", ONUPDATE)
        elseif event == "PLAYER_LOGOUT" then
            AIO_sv = {}
            for key in pairs(ctx.AIO_SAVEDVARS or {}) do
                AIO_sv[key] = _G[key]
            end
            AIO_sv_char = {}
            for key in pairs(ctx.AIO_SAVEDVARSCHAR or {}) do
                AIO_sv_char[key] = _G[key]
            end
            for _, v in ipairs(ctx.AIO_SAVEDFRAMES or {}) do
                ctx.LibWindow.SavePosition(v)
            end
        end
    end
    frame:SetScript("OnEvent", frame.OnEvent)

    M.install_reassembler_timer(ctx)
end

function M.install_reassembler_timer(ctx)
    local frame = CreateFrame("Frame")
    local timer = ctx.AIO_MSG_CACHE_DELAY
    local function ONUPDATE(_, diff)
        if timer > diff then
            timer = timer - diff
        else
            ctx.reassembler_sweep()
            timer = ctx.AIO_MSG_CACHE_DELAY
        end
    end
    frame:SetScript("OnUpdate", ONUPDATE)
end

return M
