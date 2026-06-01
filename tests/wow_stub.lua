--[[
    Minimal Eluna/WoW globals for loading AIO.lua outside the game.
]]

local wow_stub = {
    addon_messages = {},
    server_events = {},
    player_events = {},
    lua_events = {},
    frames = {},
    reload_ui_count = 0,
    print_log = {},
}

local MODULES = {
    "AIO",
    "aio_core",
    "aio_framing",
    "aio_reassembler",
    "aio_rpc",
    "aio_util",
    "aio_server_pipeline",
    "aio_client_ui",
    "crc32lua",
    "LuaSrcDiet",
}

function wow_stub.clear_packages()
    for i = 1, #MODULES do
        package.loaded[MODULES[i]] = nil
    end
    _G.AIO = nil
    _G.AIO_sv = nil
    _G.AIO_sv_char = nil
    _G.AIO_sv_Addons = nil
end

function wow_stub.reset_log()
    wow_stub.addon_messages = {}
    wow_stub.server_events = {}
    wow_stub.player_events = {}
    wow_stub.lua_events = {}
    wow_stub.frames = {}
    wow_stub.reload_ui_count = 0
    wow_stub.print_log = {}
end

local function make_frame()
    local frame = {
        scripts = {},
        events = {},
    }
    function frame:RegisterEvent(name)
        frame.events[name] = true
    end
    function frame:SetScript(name, fn)
        frame.scripts[name] = fn
    end
    function frame:SetToplevel() end
    function frame:SetFrameStrata() end
    function frame:SetFrameLevel() end
    function frame:SetAllPoints() end
    wow_stub.frames[#wow_stub.frames + 1] = frame
    return frame
end

function wow_stub.make_player(guid)
    guid = guid or 1
    local player = { _guid = guid }
    function player:GetGUIDLow()
        return player._guid
    end
    function player:SendAddonMessage(prefix, msg, channel, target)
        wow_stub.addon_messages[#wow_stub.addon_messages + 1] = {
            dir = "server_to_client",
            guid = player._guid,
            prefix = prefix,
            msg = msg,
            channel = channel,
            target = target,
        }
    end
    function player:SendBroadcastMessage(text)
        wow_stub.print_log[#wow_stub.print_log + 1] = { player = player._guid, text = text }
    end
    return player
end

local function format_print(...)
    local parts = { ... }
    for i = 1, #parts do
        parts[i] = tostring(parts[i])
    end
    return table.concat(parts, "\t")
end

local function stub_print(...)
    wow_stub.print_log[#wow_stub.print_log + 1] = { text = format_print(...) }
end

function wow_stub.install_server_deps(_package_path_fn)
    package.preload["LuaSrcDiet"] = function()
        return function(code)
            return code
        end
    end
    package.preload["crc32lua"] = function()
        return {
            crc32 = function(data, crc)
                local h = crc or 0
                for i = 1, #data do
                    h = (h * 33 + string.byte(data, i)) % 4294967296
                end
                return h
            end,
        }
    end
end

function wow_stub.install_client_deps(package_path_fn)
    package_path_fn("AIO_Client/Dep_LibWindow-1.1/")
    package_path_fn("AIO_Client/Dep_LibWindow-1.1/LibWindow-1.1/")
    package.preload["aio_client_ui"] = function()
        local M = {}
        function M.install(ctx)
            ctx.AIO_RESET = function()
                ctx.AIO_client_state.AIO_PENDING_RESET = true
            end
            function ctx.AIO.AddSavedVar(key)
                ctx.AIO_SAVEDVARS[key] = true
            end
            function ctx.AIO.AddSavedVarChar(key)
                ctx.AIO_SAVEDVARSCHAR[key] = true
            end
            function ctx.AIO.SavePosition() end
            ctx.AIO_HANDLERS.Init = function() end
            ctx.AIO_HANDLERS.ForceReload = function() end
            ctx.AIO_HANDLERS.ForceReset = function() end
        end
        function M.install_reassembler_timer() end
        return M
    end
end

function wow_stub.clear_server_globals()
    _G.AIO_TEST_ALLOW_TABLE_PLAYERS = nil
    _G.GetLuaEngine = nil
    _G.GetStateMapId = nil
    _G.RegisterServerEvent = nil
    _G.RegisterPlayerEvent = nil
    _G.CreateLuaEvent = nil
    _G.PrintInfo = nil
    _G.GetPlayersInWorld = nil
end

function wow_stub.clear_client_globals()
    _G.GetTime = nil
    _G.CreateFrame = nil
    _G.SendAddonMessage = nil
    _G.UnitName = nil
    _G.ReloadUI = nil
    _G.SlashCmdList = nil
    _G.SLASH_AIO1 = nil
    _G.GetBuildInfo = nil
    _G.RegisterAddonMessagePrefix = nil
    _G.message = nil
    _G.WorldFrame = nil
    _G.LibStub = nil
    _G.AIO_sv = nil
    _G.AIO_sv_char = nil
    _G.AIO_sv_Addons = nil
    _G.AIO_FRAMEPOSITIONS = nil
    _G.AIO_FRAMEPOSITIONSCHAR = nil
end

local function clear_debug_hook()
    if debug and debug.sethook then
        debug.sethook()
    end
end

function wow_stub.install_server()
    wow_stub.clear_server_globals()
    wow_stub.clear_client_globals()
    clear_debug_hook()
    _G.AIO_TEST_ALLOW_TABLE_PLAYERS = true

    _G.GetLuaEngine = function()
        return {}
    end
    _G.GetStateMapId = function()
        return -1
    end
    _G.RegisterServerEvent = function(id, fn)
        wow_stub.server_events[id] = fn
    end
    _G.RegisterPlayerEvent = function(id, fn)
        wow_stub.player_events[id] = fn
    end
    _G.CreateLuaEvent = function(fn, delay, repeats)
        local handle = #wow_stub.lua_events + 1
        wow_stub.lua_events[handle] = {
            fn = fn,
            delay = delay,
            repeats = repeats,
        }
        return handle
    end
    _G.PrintInfo = stub_print
    _G.GetPlayersInWorld = function()
        return {}
    end
end

function wow_stub.install_client()
    wow_stub.clear_server_globals()
    wow_stub.clear_client_globals()
    clear_debug_hook()
    _G.AIO_TEST_ALLOW_TABLE_PLAYERS = true

    -- Do not replace _G.print: Lua 5.4 can hang when shadowing the C print global.
    _G.GetTime = function()
        return 0
    end
    _G.CreateFrame = make_frame
    _G.WorldFrame = {}
    _G.UnitName = function()
        return "TestPlayer"
    end
    _G.SendAddonMessage = function(prefix, msg, channel, target)
        wow_stub.addon_messages[#wow_stub.addon_messages + 1] = {
            dir = "client_to_server",
            prefix = prefix,
            msg = msg,
            channel = channel,
            target = target,
        }
    end
    _G.ReloadUI = function()
        wow_stub.reload_ui_count = wow_stub.reload_ui_count + 1
    end
    _G.message = function() end
    _G.GetBuildInfo = function()
        return nil, nil, nil, 30300
    end
    _G.RegisterAddonMessagePrefix = function() end
    _G.SlashCmdList = {}
    _G.SLASH_AIO1 = "/aio"
    _G.LibStub = function(name)
        if name == "LibWindow-1.1" then
            return {
                RegisterConfig = function() end,
                RestorePosition = function() end,
                SavePosition = function() end,
            }
        end
        error("LibStub: unknown library " .. tostring(name))
    end
    _G.AIO_sv = {}
    _G.AIO_sv_char = {}
    _G.AIO_sv_Addons = {}
end

function wow_stub.fire_server_addon_msg(player, prefix, msg, target)
    local handler = wow_stub.server_events[30]
    assert(handler, "server addon event 30 not registered")
    handler(nil, player, nil, prefix, msg, target or player)
end

function wow_stub.fire_player_command(player, msg)
    local handler = wow_stub.player_events[42]
    assert(handler, "player command event 42 not registered")
    return handler(nil, player, msg)
end

function wow_stub.fire_addon_loaded(addon_name)
    for i = 1, #wow_stub.frames do
        local frame = wow_stub.frames[i]
        if frame.scripts.OnEvent and frame.events.ADDON_LOADED then
            frame.scripts.OnEvent(frame, "ADDON_LOADED", addon_name)
        end
    end
end

function wow_stub.fire_client_chat_addon(prefix, msg)
    for i = 1, #wow_stub.frames do
        local frame = wow_stub.frames[i]
        if frame.scripts.OnEvent and frame.events.CHAT_MSG_ADDON then
            frame.scripts.OnEvent(frame, "CHAT_MSG_ADDON", nil, prefix, msg, nil, UnitName("player"))
        end
    end
end

function wow_stub.run_frame_onupdate(diff)
    diff = diff or 1000
    for i = 1, #wow_stub.frames do
        local onupdate = wow_stub.frames[i].scripts.OnUpdate
        if onupdate then
            onupdate(wow_stub.frames[i], diff)
        end
    end
end

return wow_stub
