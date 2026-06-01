--[[
    Copyright (C) 2014-  Rochet2 <https://github.com/Rochet2>

    This program is free software you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

--[=[
-- #API
-- For example scripts see the Examples folder. The example files are named according to their final execution location. To run the examples place all of their files to `server_root/lua_scripts/`.

-- AIO is required this way due to server and client differences with require function
local AIO = AIO or require("AIO")

-- Returns true if we are on server side, false if we are on client side
isServer = AIO.IsServer()

-- Returns true if we are on main state, true if we are on client side
isMainState = AIO.IsMainState()

-- Returns AIO version - note the type is not guaranteed to be a number
version = AIO.GetVersion()

-- Adds the file at given path to files to send to players if called on server side in main state.
-- The addon code is trimmed according to settings in AIO.lua.
-- The addon is cached on client side and will be updated only when needed.
-- Returns false on client side and true on server side. By default the
-- path is the current file's path and name is the file's name
-- 'path' is relative to worldserver.exe but an absolute path can also be given.
-- You should call this function only on startup to ensure everyone gets the same
-- addons and no addon is duplicate.
added = AIO.AddAddon([path, name])
-- The way this is designed to be used is at the top of an addon file so that the
-- file is added and not run if we are on server, and just run if we are on client:
if AIO.AddAddon() then
    return
end

-- Similar to AddAddon - Adds 'code' to the addons sent to players. The code is trimmed
-- according to settings in AIO.lua. The addon is cached on client side and will
-- be updated only when needed. 'name' is an unique name for the addon, usually
-- you can use the file name or addon name there. Do note that short names are
-- better since they are sent back and forth to identify files.
-- The function only exists on server side. Only on main lua state.
-- You should call this function only on startup to ensure everyone gets the same
-- addons and no addon is duplicate.
AIO.AddAddonCode(name, code)

-- Triggers the handler function that has the name 'handlername' from the handlertable
-- added with AIO.AddHandlers(name, handlertable) for the 'name'.
-- Can also trigger a function registered with AIO.RegisterEvent(name, func)
-- All triggered handlers have parameters handler(player, ...) where varargs are
-- the varargs in AIO.Handle or msg.Add
-- This function is a shorthand for AIO.Msg():Add(name, handlername, ...):Send()
-- For efficiency favour creating messages once and sending them rather than creating
-- them over and over with AIO.Handle().
-- The server side version.
AIO.Handle(player, name, handlername[, ...])
-- The client side version.
AIO.Handle(name, handlername[, ...])

-- Only on main lua state.
-- Adds a table of handler functions for the specified 'name'. When a message like:
-- AIO.Handle(name, "HandlerName", ...) is received, the handlertable["HandlerName"]
-- will be called with player and varargs as parameters.
-- Returns the passed 'handlertable'.
-- AIO.AddHandlers uses AIO.RegisterEvent internally, so same name can not be used on both.
handlertable = AIO.AddHandlers(name, handlertable)

-- Only on main lua state.
-- Adds a new callback function that is called if a message with the given
-- name is received. All parameters the sender sends in the message will
-- be passed to func when called.
-- Example message: AIO.Msg():Add(name, ...):Send()
-- AIO.AddHandlers uses AIO.RegisterEvent internally, so same name can not be used on both.
AIO.RegisterEvent(name, func)

-- Adds a new function that is called when the initial message is sent to the player.
-- The function is called before sending and the initial message is passed to it
-- along with the player if available: func(msg[, player])
-- In the function you can modify the passed msg and/or return a new one to be
-- used as initial message. Only on server side. Only on main lua state.
-- This can be used to send for example initial values (like player stats) for the addons.
-- If dynamic loading is preferred, you can use the messaging API to request the values
-- on demand also.
AIO.AddOnInit(func)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are account bound.
-- Only exists on client side and you should call it only once per key.
-- All saved data is saved to client side.
AIO.AddSavedVar(key)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are character bound.
-- Only exists on client side and you should call it only once per key.
-- All saved data is saved to client side.
AIO.AddSavedVarChar(key)

-- Makes the addon frame save it's position and restore it on login.
-- If char is true, the position saving is character bound, otherwise account bound.
-- Only exists on client side and you should call it only once per frame.
-- All saved data is saved to client side.
AIO.SavePosition(frame[, char])

-- AIO message class:
-- Creates and returns a new AIO message that you can append stuff to and send to
-- client or server. Example: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
-- These messages handle all client-server communication.
msg = AIO.Msg()

-- The name is used to identify the handler function on receiving end.
-- A handler function registered with AIO.RegisterEvent(name, func)
-- will be called on receiving end with the varargs.
function msgmt:Add(name, ...)

-- Appends messages to eachother, returns self
msg = msg:Append(msg2)

-- Sends the message, returns self
-- Server side version - sends to all players passed
msg = msg:Send(player, ...)
-- Client side version - sends to server
msg = msg:Send()

-- Returns true if the message has something in it
hasmsg = msg:HasMsg()

-- Returns the message as a string
msgstr = msg:ToString()

-- Erases the so far built message and returns self
msg = msg:Clear()

-- Assembles the message string from added and appended data. Mainly for internal use.
-- Returns self
msg = msg:Assemble()
]=]

-- Try to avoid multiple versions of AIO
assert(not AIO, "AIO is already loaded. Possibly different versions!")

----------------------------------
-- Server-Client messaging config:
----------------------------------

-- When developing an addon it is advised to set AIO_ENABLE_PCALL false and AIO_CODE_OBFUSCATE to false
-- Or alternatively set AIO_ENABLE_PCALL true, AIO_ENABLE_TRACEBACK to true and AIO_CODE_OBFUSCATE to false
-- The defaults are recommended for normal use

-- Enables some additional prints for debugging
local AIO_ENABLE_DEBUG_MSGS = false -- default false

-- Enables pcall to silence errors and continue running normally when an error occurs
-- If AIO_ENABLE_PCALL is true, errors are printed and running is continued
-- If AIO_ENABLE_PCALL is false, pcall is not used and errors occur normally
-- Erroring out can be useful for debugging scripts
local AIO_ENABLE_PCALL = true -- default true

-- Enables using debug.traceback as the error handler to help locating errors
-- on server side. Make sure you have default Eluna extensions in place.
-- On client side uses _ERRORMESSAGE function to output errors with trace.
-- Requires AIO_ENABLE_PCALL to be true
local AIO_ENABLE_TRACEBACK = false -- default false

-- prints all messages
local AIO_ENABLE_MSGPRINT = false -- default false

-- Max VM instructions to do before timeout
-- Attempts to avoid server freeze on bad code and or user
-- Use 0 to disable timeout
-- Server side only
local AIO_TIMEOUT_INSTRUCTIONCOUNT = 1e8 -- default 1e8

-- Amount of data to store per character at maximum
-- Attempts to avoid consuming ram
-- Server side only
local AIO_MSG_CACHE_SPACE = 5e5 -- bytes -- default 5e5

-- Time to wait for a message to arrive
-- Attempts to avoid consuming ram and storing incomplete messages
local AIO_MSG_CACHE_TIME = 15*1000 -- ms -- default 15*1000

-- Delay between checking for outdated messages
local AIO_MSG_CACHE_DELAY = 5*1000 -- ms -- default 5*1000

-- Delay between possible sending of full addon code
-- User can potentially request the full addon list repeatedly
-- this limits the ability to do that (avoid lagging from bad user)
-- Server side only
local AIO_UI_INIT_DELAY = 5*1000 -- ms -- default 5*1000

-- Setting to enable and disable LZW compressing for addons
-- Server side only
local AIO_MSG_COMPRESS = true -- default true

-- Setting to enable and disable obfuscation for code to reduce size
-- Note that error messages will not have correct line numbers since obfuscation rearrange the code
-- for debugging purposes it is recommended to disable this option
-- Server side only
local AIO_CODE_OBFUSCATE = true -- default true

-- Force all online players to reload UI when the AIO server script loads or reloads
-- Server side only
local AIO_FORCE_RELOAD_ON_STARTUP = true -- default true

-- Setting to send client errors to server
-- Client must have AIO_ENABLE_PCALL enabled
-- Client side only
local AIO_ERROR_LOG = false -- default false

----------------------------------

----------------------------------

local ssub = string.sub
local schar = string.char
local aio_core = require("aio_core")
local aio_framing = require("aio_framing")
local aio_reassembler_mod = require("aio_reassembler")
local aio_rpc_mod = require("aio_rpc")
local tconcat = table.concat
-- Some lua compatibility between 5.1 and 5.2
local loadstring = loadstring or load -- luacheck: ignore 113
local unpack = _G.unpack or table.unpack -- luacheck: ignore 143
-- server client compatibility (milliseconds on both sides)
local AIO_GetTime = os and function() return os.time() * 1000 end or function() return GetTime() * 1000 end
local AIO_GetTimeDiff = function(now, earlier) return now - earlier end

-- boolean value to define whether we are on server or client side
local AIO_SERVER = type(GetLuaEngine) == "function"
-- boolean value to define if we are on main lua state (eluna multistate support)
local AIO_MAIN_LUA_STATE = not AIO_SERVER or not GetStateMapId or GetStateMapId() == -1
-- Client must have same version (basically same AIO file)
local AIO_VERSION = 1.76
-- ID characters for client-server messaging
local AIO_ShortMsg          = aio_framing.SHORT_TAG
local AIO_Compressed        = 'C'
local AIO_Uncompressed      = 'U'
local AIO_Prefix            = "AIO"
AIO_Prefix = ssub((AIO_Prefix), 1, 16) -- shorten to max allowed
local AIO_ServerPrefix = ssub(("S"..AIO_Prefix), 1, 16)
local AIO_ClientPrefix = ssub(("C"..AIO_Prefix), 1, 16)
assert(#AIO_ServerPrefix == #AIO_ClientPrefix)
-- Client can send only 255 max size messages, but server can send more
-- on different patches the limit varies, on 3.3.5 it is exactly 3004 and on cataclysm 2^23
-- thus we use 2560 that is about 10 times more data and below both max values. Too high value can crash client.
-- Change if you need to :)
local AIO_MsgLen = (AIO_SERVER and 2560 or 255) -1 -#AIO_ServerPrefix -#AIO_ShortMsg -- remove \t, prefix, msg ID
local MSG_MIN = 1
local MSG_MAX = 2^16-767

-- AIO main table
AIO =
{
    -- AIO flavour functions
    unpack = unpack,
}

local AIO = AIO
-- Client side table containing frames that need to have their position saved
local AIO_SAVEDFRAMES = {}
-- Client side tables that contain keys to _G table for saved variables
-- you should add your variables here with AIO.AddSavedVar(key) or AIO.AddSavedVarChar(key)
local AIO_SAVEDVARS = {}
local AIO_SAVEDVARSCHAR = {}
-- Client-only mutable state (shared with aio_client_ui)
local AIO_client_state = not AIO_SERVER and {
    AIO_INITED = false,
    AIO_PENDING_RESET = false,
    AIO_VERSION_MISMATCH = false,
} or nil
-- Server and Client side functions to execute on AIO messages
local AIO_HANDLERS = AIO_MAIN_LUA_STATE and {} or nil
-- Server side functions to execute when an init msg is received
local AIO_INITHOOKS = AIO_MAIN_LUA_STATE and {} or nil
-- Server and Client side custom coded handlers for incoming data
local AIO_BLOCKHANDLES = AIO_MAIN_LUA_STATE and {} or nil
-- A server side table for correct order of addons to send
-- you should add all addon code here with AIO.AddAddon
local AIO_ADDONSORDER = AIO_MAIN_LUA_STATE and {} or nil

-- Dependencies
local NewQueue = NewQueue or require("queue")
local Smallfolk = Smallfolk or require("smallfolk")
local lualzw = lualzw or require("lualzw")
local aio_util = require("aio_util")
local LibWindow -- luacheck: ignore 231
local LuaSrcDiet -- luacheck: ignore 231
if AIO_SERVER then
    if AIO_MAIN_LUA_STATE then
        LuaSrcDiet = require("LuaSrcDiet")
    end
else
    LibWindow = LibStub("LibWindow-1.1")
end

-- Returns true if we are on server
function AIO.IsServer()
    return AIO_SERVER
end

-- Returns true if we are on client, returns true if we are on main state on server and false otherwise
function AIO.IsMainState()
    return AIO_MAIN_LUA_STATE
end

-- Returns AIO version - note the type is not guaranteed to be a number
function AIO.GetVersion()
    return AIO_VERSION
end

-- Client reset (set in client branch below)
local AIO_RESET -- luacheck: ignore 231

-- Used to print debug messages if AIO_ENABLE_DEBUG_MSGS is true
function AIO_debug(...)
    if AIO_ENABLE_DEBUG_MSGS then
        print("AIO:", ...)
    end
end

local AIO_pcall = aio_core.make_pcall({
    unpack = unpack,
    pcall = pcall,
    xpcall = xpcall,
    enable_pcall = AIO_ENABLE_PCALL,
    server = AIO_SERVER,
    enable_traceback = AIO_ENABLE_TRACEBACK,
    debug_traceback = debug.traceback,
    on_error = function(err)
        if AIO_SERVER then
            AIO_debug(err)
        else
            if AIO_ERROR_LOG then
                AIO.Handle("AIO", "Error", err)
            end
            if AIO_ENABLE_TRACEBACK then
                _ERRORMESSAGE(err)
            else
                print(err)
            end
        end
    end,
})

local framing_codec = aio_framing.new(AIO_MsgLen)
local reassembler = aio_reassembler_mod.new({
    framing = framing_codec,
    NewQueue = NewQueue,
    get_time = AIO_GetTime,
    get_time_diff = AIO_GetTimeDiff,
    get_message_stored_size = aio_util.getMessageStoredSize,
    cache_space = AIO_SERVER and AIO_MSG_CACHE_SPACE or nil,
    cache_time_ms = AIO_MSG_CACHE_TIME,
    msg_id_min = MSG_MIN,
    msg_id_max = MSG_MAX,
})

local function ProcessRemoveQue()
    reassembler:sweep_expired()
end
if AIO_SERVER and AIO_MAIN_LUA_STATE then
    CreateLuaEvent(ProcessRemoveQue, AIO_MSG_CACHE_DELAY, 0)
end
-- Erase data on logout
if AIO_SERVER and AIO_MAIN_LUA_STATE then
    local function Erase(event, player)
        reassembler:remove_peer(player:GetGUIDLow())
    end
    RegisterPlayerEvent(4, Erase)
end

-- Selects a method to send the string to the player depending on whether
-- running on client or server side. From client to server no player needed
local function AIO_SendAddonMessage(msg, player)
    if AIO_SERVER then
        -- server -> client
        player:SendAddonMessage(AIO_ServerPrefix, msg, 7, player)
    else
        -- client -> server
        SendAddonMessage(AIO_ClientPrefix, msg, "WHISPER", UnitName("player"))
    end
end

-- Sends a string to given players (vararg).
-- Can have one or more receiver players (no receivers when sending from client -> server)
-- Splits too long messages into smaller pieces
local function AIO_Send(msg, player, ...)
    assert(type(msg) == "string", "#1 string expected")
    assert(not AIO_SERVER or type(player) == 'userdata', "#2 player expected")

    AIO_debug("Sending message length:", #msg)
    if AIO_ENABLE_MSGPRINT then
        print("sent:", msg)
    end

    if #msg <= AIO_MsgLen then
        AIO_SendAddonMessage(AIO_ShortMsg .. msg, player)
    else
        local peer_id = AIO_SERVER and player:GetGUIDLow() or 1
        local packets = reassembler:split_payload(peer_id, msg)
        for i = 1, #packets do
            AIO_SendAddonMessage(packets[i], player)
        end
    end

    -- More than one receiver, mass send message
    if ... then
        for i = 1, select('#',...) do
            AIO_Send(msg, select(i, ...))
        end
    end
end

local timeout_parse_msg = ''
local function AIO_Timeout()
    error(string.format(
        "AIO Timeout. Your code ran over %s instructions with message:\n%s",
        '' .. AIO_TIMEOUT_INSTRUCTIONCOUNT,
        timeout_parse_msg or 'nil'
    ))
end

local timeout_hook
if AIO_SERVER and AIO_TIMEOUT_INSTRUCTIONCOUNT > 0 then
    timeout_hook = {
        begin = function(msg)
            timeout_parse_msg = msg
            debug.sethook(AIO_Timeout, "", AIO_TIMEOUT_INSTRUCTIONCOUNT)
        end,
        ["end"] = function()
            debug.sethook()
        end,
    }
end

local rpc = aio_rpc_mod.new({
    dumps = Smallfolk.dumps,
    loads = Smallfolk.loads,
    pcall = AIO_pcall,
    get_handlers = function() return AIO_BLOCKHANDLES end,
    debug = AIO_debug,
    enable_msgprint = AIO_ENABLE_MSGPRINT,
    server = AIO_SERVER,
    timeout_hook = timeout_hook,
})
rpc.bind_send(AIO_Send)

function AIO.Msg()
    return rpc.Msg()
end

local AIO_HandleBlock = aio_core.make_handle_block({
    unpack = unpack,
    client_state = AIO_client_state,
    block_handlers = AIO_BLOCKHANDLES,
    server = AIO_SERVER,
    max_block_args = 15,
    debug = AIO_debug,
})

local function AIO_ParseBlocks(msg, player)
    AIO_pcall(function()
        rpc.parse_blocks(msg, player, function(p, data)
            AIO_pcall(AIO_HandleBlock, p, data)
        end)
    end)
end

local function _AIO_HandleIncomingMsg(msg, player)
    local peer_id = AIO_SERVER and player:GetGUIDLow() or 1
    local assembled = reassembler:ingest(peer_id, msg)
    if assembled then
        AIO_ParseBlocks(assembled, player)
    end
end
local function AIO_HandleIncomingMsg(msg, player)
    AIO_pcall(_AIO_HandleIncomingMsg, msg, player)
end

if AIO_MAIN_LUA_STATE then
    -- Adds a new callback function for AIO that is called if
    -- a block with the same name is received.
    -- All parameters the client sends will be passed to func when called
    -- Only one function can be a handler for one name (subject for change)
    function AIO.RegisterEvent(name, func)
        assert(name ~= nil, "name of the registered event expected not nil")
        assert(type(func) == "function", "callback function must be a function")
        assert(not AIO_BLOCKHANDLES[name], "an event is already registered for the name: "..name)
        AIO_BLOCKHANDLES[name] = func
    end

    -- Adds a table of handler functions for the specified name.
    -- You can fill a table with functions and use this to add them for a name.
    -- Then when a message like AIO.Msg():Add("MyName", "HandlerName"):Send()
    -- is received, the handlertable["HandlerName"] will be executed with player and additional params passed to the block.
    -- Returns the passed table
    function AIO.AddHandlers(name, handlertable)
        assert(name ~= nil, "#1 expected not nil")
        assert(type(handlertable) == 'table', "#2 a table expected")

        for k,v in pairs(handlertable) do
            assert(type(v) == 'function', "#2 a table of functions expected, found a "..type(v).." value")
        end

        local function handler(player, key, ...)
            if key and handlertable[key] then
                handlertable[key](player, ...)
            elseif key then
                AIO_debug("Unknown handler key for", name, ":", key)
            end
        end
        AIO.RegisterEvent(name, handler)
        return handlertable
    end
end

-- Adds the current file as an AIO sent addon if called on server side main state.
-- Can be used from server and client, but on client does nothing.
-- You can provide path and/or name of the lua file to add, but if
-- omitted the file the function is executed in will be used as path
-- and the path's or given path's file name will be used.
-- Returns true if called on server side
local aio_side_ctx = {
    AIO = AIO,
    AIO_VERSION = AIO_VERSION,
    AIO_client_state = AIO_client_state,
    AIO_SAVEDFRAMES = AIO_SAVEDFRAMES,
    AIO_SAVEDVARS = AIO_SAVEDVARS,
    AIO_SAVEDVARSCHAR = AIO_SAVEDVARSCHAR,
    AIO_HANDLERS = AIO_HANDLERS,
    AIO_ADDONSORDER = AIO_ADDONSORDER,
    AIO_INITHOOKS = AIO_INITHOOKS,
    AIO_debug = AIO_debug,
    AIO_pcall = AIO_pcall,
    AIO_HandleIncomingMsg = AIO_HandleIncomingMsg,
    AIO_Msg = AIO.Msg,
    AIO_CODE_OBFUSCATE = AIO_CODE_OBFUSCATE,
    AIO_MSG_COMPRESS = AIO_MSG_COMPRESS,
    AIO_UI_INIT_DELAY = AIO_UI_INIT_DELAY,
    AIO_FORCE_RELOAD_ON_STARTUP = AIO_FORCE_RELOAD_ON_STARTUP,
    AIO_MSG_CACHE_DELAY = AIO_MSG_CACHE_DELAY,
    AIO_Compressed = AIO_Compressed,
    AIO_Uncompressed = AIO_Uncompressed,
    AIO_ClientPrefix = AIO_ClientPrefix,
    AIO_ServerPrefix = AIO_ServerPrefix,
    AIO_Prefix = AIO_Prefix,
    lualzw = lualzw,
    aio_util = aio_util,
    LuaSrcDiet = LuaSrcDiet,
    LibWindow = LibWindow,
    loadstring = loadstring,
    ssub = ssub,
    reassembler_sweep = ProcessRemoveQue,
}

function AIO.AddAddon(path, name)
    if AIO_SERVER then
        if AIO_MAIN_LUA_STATE then
            require("aio_server_pipeline").add_addon_file(aio_side_ctx, path, name)
        end
        return true
    end
end

if AIO_SERVER then
    function AIO.Handle(player, name, handlername, ...)
        assert(type(player) == "userdata", "#1 player expected")
        assert(name ~= nil, "#2 expected not nil")
        return AIO.Msg():Add(name, handlername, ...):Send(player)
    end

    if AIO_MAIN_LUA_STATE then
        require("aio_server_pipeline").install_main_state(aio_side_ctx)
    end
else
    function AIO.Handle(name, handlername, ...)
        assert(name ~= nil, "#1 expected not nil")
        return AIO.Msg():Add(name, handlername, ...):Send()
    end

    require("aio_client_ui").install(aio_side_ctx)
    AIO_RESET = aio_side_ctx.AIO_RESET
end

if AIO_MAIN_LUA_STATE then
    -- Adds all handlers from AIO_HANDLERS for the "AIO" msg handler
    AIO.AddHandlers("AIO", AIO_HANDLERS)

    -- Tables holding the command functions and the help messages
    -- both are indexed by the command name. See below for how to add a command and help
    local cmds = {}
    local helps = {}

    -- A print selector
    local function pprint(player, ...)
        if player then
            player:SendBroadcastMessage(tconcat({...}, " "))
        else
            print(...)
        end
    end

    if AIO_SERVER then
        local function OnCommand(event, player, msg)
            msg = msg:lower()
            if ssub(msg, 1, 3) ~= 'aio' then
                return
            end
            msg = ssub(msg, 5)
            if msg and msg ~= "" then
                for k,v in pairs(cmds) do
                    if k:find(msg, 1, true) == 1 then
                        v(player)
                        return false
                    end
                end
            end
            pprint(player, "Unknown command .aio "..tostring(msg))
            cmds.help(player)
            return false
        end
        RegisterPlayerEvent(42, OnCommand)
    else
        SLASH_AIO1 = "/aio"
        function SlashCmdList.AIO(msg)
            local msg = msg:lower()
            if msg and msg ~= "" then
                for k,v in pairs(cmds) do
                    if k:find(msg, 1, true) == 1 then
                        v()
                        return
                    end
                end
            end
            print("Unknown command /aio "..tostring(msg))
            cmds.help()
        end
    end

    -- Define slash commands and helps for them
    -- triggered with /aio <command name>
    helps.help = "prints this list"
    function cmds.help(player)
        pprint(player, "Available commands:")
        for k,v in pairs(cmds) do
            pprint(player, (AIO_SERVER and '.' or '/').."aio "..k.." - "..(helps[k] or "no info"))
        end
    end
    if not AIO_SERVER then
        helps.reset = "resets local AIO cache - clears saved addons and their saved variables and reloads the UI"
        function cmds.reset()
            AIO_RESET()
            ReloadUI()
        end
    end
    helps.trace = "toggles using debug.traceback or _ERRORMESSAGE"
    function cmds.trace(player)
        AIO_ENABLE_TRACEBACK = not AIO_ENABLE_TRACEBACK
        pprint(player, "using trace is now", AIO_ENABLE_TRACEBACK and "on" or "off")
    end
    helps.debug = "toggles showing of debug messages"
    function cmds.debug(player)
        AIO_ENABLE_DEBUG_MSGS = not AIO_ENABLE_DEBUG_MSGS
        pprint(player, "showing debug messages is now", AIO_ENABLE_DEBUG_MSGS and "on" or "off")
    end
    helps.pcall = "toggles using pcall"
    function cmds.pcall(player)
        AIO_ENABLE_PCALL = not AIO_ENABLE_PCALL
        pprint(player, "using pcall is now", AIO_ENABLE_PCALL and "on" or "off")
    end
    helps.printio = "toggles printing all sent and received messages"
    function cmds.printio(player)
        AIO_ENABLE_MSGPRINT = not AIO_ENABLE_MSGPRINT
        pprint(player, "printing IO is now", AIO_ENABLE_MSGPRINT and "on" or "off")
    end
end

return AIO
