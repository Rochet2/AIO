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

-- Adds the file at given path to files to send to players if called on server side.
-- The addon code is trimmed according to settings in AIO.lua.
-- The addon is cached on client side and will be updated only when needed.
-- Returns false on client side and true on server side. By default the
-- path is the current file's path and name is the file's name
-- 'path' is relative to worldserver.exe but an absolute path can also be given.
added = AIO.AddAddon([path, name])

-- Similar to AddAddon - Adds 'code' to the addons sent to players. The code is trimmed
-- according to settings in AIO.lua. The addon is cached on client side and will
-- be updated only when needed. 'name' is an unique name for the addon, usually
-- you can use the file name or addon name there. Do note that short names are
-- better since they are sent back and forth to indentify files.
-- The function only exists on server side.
AIO.AddAddonCode(name, code)

-- Triggers the handler with the 'handlername' from the handlertable added with
-- AIO.AddHandlers(name, handlertable) for the 'name'
-- The server side version.
AIO.Handle(player, name, handlername[, ...])
-- The client side version.
AIO.Handle(name, handlername[, ...])

-- Adds a table of handler functions for the specified 'name'. When a message like
--  AIO.Handle(name, "HandlerName", ...) is received, the handlertable["HandlerName"]
-- will be called with player and varargs as parameters.
-- Returns the passed 'handlertable'
handlertable = AIO.AddHandlers(name, handlertable)

-- Adds a new callback function that is called if a message with the given
-- name is recieved and the message has the correct fmt if given.
-- fmt is a table of lua type strings: {"string", "table", "number", ...}
-- All parameters the sender sends in the message will be passed to func when called
AIO.RegisterEvent(name, func[, fmt])

-- Adds a new function that is called when the initial message is sent to the player.
-- The function is called before sending and the initial message is passed to it
-- along with the player if available: func(msg[, player])
-- In the function you can modify the passed msg and/or return a new one to be
-- used as initial message. Only for server side.
AIO.AddOnInit(func)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are account bound
AIO.AddSavedVar(key)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are character bound.
AIO.AddSavedVarChar(key)

-- Makes the addon frame save it's position over relog.
-- If char is true, the position saving is character bound, otherwise account bound.
-- Only exists on client side and you only call it once per frame.
AIO.SavePosition(frame[, char])

-- Creates and returns a new AIO message that you can append stuff to and send to
-- client or server. Example: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
-- These messages handle all client-server communication.
msg = AIO.Msg()

-- The name is used to identify the handler function on receiving end.
-- A handler function registered with AIO.RegisterEvent(name, func[, fmt])
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

-- Enables some additional prints for debugging
AIO_ENABLE_DEBUG_MSGS   = false -- default false

-- Server-client messaging config
-- Max limit of packets from client to server, default 100 (avoid overflow from bad user)
AIO_MAX_PACKET_COUNT    = 100
-- Max time to wait for a message before it is erased, default 15 sec
AIO_MSG_REMOVE_DELAY    = 15*1000 -- ms
-- Delay between possible sending of full addon code, default 4 sec (avoid lagging from bad user)
AIO_UI_INIT_DELAY       = 4*1000 -- ms
-- Setting to enable and disable LZW compressing for messages, default true
-- disabled for client->server
AIO_MSG_COMPRESS        = true
-- Setting to enable and disable obfuscation for code to reduce size, default true
-- only used on server side
AIO_CODE_OBFUSCATE      = true

local assert = assert
local type = type
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local ssub = string.sub
local match = string.match
local slen = string.len
local ceil = ceil or math.ceil
-- Some lua compatibility between 5.1 and 5.2
loadstring = loadstring or load -- loadstring name varies with lua 5.1 and 5.2
unpack = unpack or table.unpack -- unpack place varies with lua 5.1 and 5.2

-- boolean value to define whether we are on server or client side
local AIO_SERVER = type(GetLuaEngine) == "function"
-- Client must have same version (basically same AIO file)
local AIO_VERSION = 0.77
-- ID characters for client-server messaging
local AIO_ShortMsg          = 'S'
local AIO_LongMsg           = 'L'
local AIO_LongMsgStart      = 's'
local AIO_LongMsgEnd        = 'e'
local AIO_EndBlock          = 'B'
local AIO_Compressed        = 'C'
local AIO_Uncompressed      = 'U'
local AIO_Prefix            = "AIO"
AIO_Prefix = ssub((AIO_Prefix), 1, 16) -- shorten to max allowed
local AIO_MsgLen = 255 -1 -slen(AIO_Prefix) -1 -- remove \t, prefix, msg type indentifier

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
-- Client side flag for noting if the client has been inited or not
local AIO_INITED = false
-- Server and Client side functions to execute on AIO messages
local AIO_HANDLERS = {}
-- Server side functions to execute when an init msg is received
local AIO_INITHOOKS = {}
-- A server side table of addon codes
-- you should add all addon code here with AIO.AddAddon(name, code)
local AIO_ADDONS = {}
-- Server and Client side custom coded handlers for incoming data
local AIO_BLOCKHANDLES = {}
-- A server side table for correct order of addons to send
local AIO_ADDONSORDER = {}

local LibWindow
local LuaSrcDiet
local LuaSerializer = LuaSerializer or require("LuaSerializer")
local TLibCompress = AIO_MSG_COMPRESS and (TLibCompress or require("LibCompress"))
if AIO_SERVER then
    LuaSrcDiet = require("LuaSrcDiet")
else
    LibWindow = LibStub("LibWindow-1.1")
end

-- Used to print debug messages if AIO_ENABLE_DEBUG_MSGS is true
function AIO_debug(...)
    if AIO_ENABLE_DEBUG_MSGS then
        print("AIO:", ...)
    end
end

-- Errors with msg at given level if condition is false
-- level works like on lua error function
function AIO_assert(cond, msg, level)
    if not cond then
        error("AIO: "..(msg or "AIO assertion failed"), (level or 1)+1)
    end
end

-- Reads a file at given absolute or relative to server root path
-- and returns the full file contents as a string
local function AIO_ReadFile(path)
    AIO_debug("Reading a file")
    assert(type(path) == 'string', "#1 string expected")
    local f = assert(io.open(path, "r"))
    local str = f:read("*all")
    f:close()
    return str
end

-- Selects a method to send the string to the player depending on whether
-- running on client or server side. From client to server no player needed
local function AIO_SendAddonMessage(msg, player)
    if AIO_SERVER then
        -- server -> client
        player:SendAddonMessage(AIO_Prefix, msg, 7, player)
    else
        -- client -> server
        SendAddonMessage(AIO_Prefix, msg, "WHISPER", UnitName("player"))
    end
end

-- Sends an AIO.Msg() to given players (vararg).
-- Can have one or more receivers (no receivers when sending from client -> server)
-- Compresses the messages according to settings at top of file
local function AIO_Send(msg, player, ...)
    assert(type(msg) == "string", "#1 string expected")
    assert(not AIO_SERVER or type(player) == 'userdata', "#2 player expected")

    -- compression disabled for client for safety
    if AIO_MSG_COMPRESS and AIO_SERVER then
        msg = AIO_Compressed..assert(TLibCompress.CompressLZW(msg))
    else
        msg = AIO_Uncompressed..msg
    end

    AIO_debug("Sending message length:", slen(msg))

    -- split message to 255 character packets if needed (send long message)
    if slen(msg) <= AIO_MsgLen then
        -- Send short <= 255 long msg
        AIO_SendAddonMessage(AIO_ShortMsg..msg, player)
    else
        -- Calculate amount of messages to send -1 since one is the end message
        local msgs = ceil(slen(msg) / AIO_MsgLen)-1
        AIO_SendAddonMessage(AIO_LongMsgStart..ssub(msg, 1, AIO_MsgLen), player)
        for i = 2, msgs do -- starts at 2 since one message was already sent
            AIO_SendAddonMessage(AIO_LongMsg..ssub(msg, ((i-1)*AIO_MsgLen)+1, (i*AIO_MsgLen)), player)
        end
        AIO_SendAddonMessage(AIO_LongMsgEnd..ssub(msg, ((msgs)*AIO_MsgLen)+1, ((msgs+1)*AIO_MsgLen)), player)
    end

    -- More than one receiver, mass send message
    if ... then
        for i = 1, select('#',...) do
            AIO_Send(msg, select(i, ...))
        end
    end
end

local msgmt = {}
function msgmt.__index(tbl, key)
    return msgmt[key]
end

-- Add a new block to message and returns self
-- A block is a chunk of data identified by a string name
-- blocks are sent between server and client and handled on the receiving end
-- by block handlers. Blockhandlers are functions you can assign to
-- a specific name as a handler with AIO.RegisterEvent(name, func, fmt)
-- The All values in the block after it's name will be passed to the handler
-- function in same order. Name will be omitted
function msgmt:Add(Name, ...)
    -- Tag Data Name Data Arguments
    assert(Name, "#1 Block must have name")
    self.params = self.params+1
    self[self.params] = Name
    for i = 1, select('#',...) do
        self.params = self.params+1
        self[self.params] = select(i,...)
    end
    self.params = self.params+1
    self[self.params] = AIO_EndBlock
    self.assemble = true
    return self
end

-- Function to append messages together, returns self
-- Example AIO.Msg():Append(msg):Append(msg2):Send(...)
function msgmt:Append(msg2)
    self:Assemble()
    if type(msg) == 'string' then
        self.MSG = self.MSG..msg2
    else
        self.MSG = self.MSG..msg2:Assemble().MSG
    end
    return self
end

-- Assembles the message string from stored data
function msgmt:Assemble()
    if not self.assemble then
        return self
    end
    -- We do not compress yet so we can keep appending the message
    self.MSG = self.MSG..LuaSerializer.serialize_nocompress(unpack(self, 1, self.params))
    for i = 1, self.params do
        self[i] = nil
    end
    self.params = 0
    self.assemble = false
    return self
end

-- Function to send the message to given players
function msgmt:Send(player, ...)
    assert(not AIO_SERVER or player, "#1 player is nil")
    AIO_Send(self:Assemble().MSG, player, ...)
    return self
end

-- Erases the so far built message and returns self
function msgmt:Clear()
    for i = 1, self.params do
        self[i] = nil
    end
    self.MSG = ''
    self.assemble = false
    self.params = 0
    return self
end

-- Returns the message string or an empty string
function msgmt:ToString()
    return self:Assemble().MSG
end

-- Returns true if the message has something in it
function msgmt:HasMsg()
    return self.params > 0 or self.MSG ~= ''
end

-- Creates and returns a new message that you can append stuff to and send to client or server
-- Example: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
function AIO.Msg()
    local msg = {params = 0, MSG = '', assemble = false}
    setmetatable(msg, msgmt)
    return msg
end

-- Checks that all values in given block have the correct type from fmt
-- fmt is a table of lua type strings: {"string", "table", "number"}
-- Does not check anything and returns true if fmt is nil
local function AIO_CheckArgs(fmt, ...)
    if not fmt then
        return true
    end
    for i = 1, #fmt do
        if type(select(i,...)) ~= fmt[i] then
            AIO_debug("Invalid handle, args dont match fmt", block[1])
            return false
        end
    end
    return true
end

-- Calls the handler for block, see AIO.RegisterEvent
-- for adding handlers for blocks
local function AIO_HandleBlock(player, HandleName, ...)
    assert(HandleName, "Invalid handle, no handle name")
    local handledata = AIO_BLOCKHANDLES[HandleName]
    if not handledata then
        error("Unknown AIO block handle: '"..tostring(HandleName).."'")
    end
    if not AIO_CheckArgs(handledata.fmt, ...) then
        error("Block arguments dont match the format: "..tostring(HandleName))
    end

    -- found the block handler and arguments match the format.
    -- call the block handler
    handledata.func(player, ...)

    if not AIO_SERVER and not AIO_INITED then
        error("Received a block before initialization, check your code: "..HandleName)
    end
end

-- Extracts blocks from parsed addon messages to a table
local function AIO_ParseBlocks(msg, player)
    AIO_debug("Received messagelength:", slen(msg))

    -- Check if message is compressed and uncompress if needed
    local compression, msg = ssub(msg, 1, 1), ssub(msg, 2)
    if compression == AIO_Compressed then
        if AIO_SERVER then
            AIO_debug("Received compressed message. Compression should be disabled for client->server communication for safety")
            return
        end
        msg = assert(TLibCompress.DecompressLZW(msg))
    end

    local data, n = LuaSerializer.unserialize_nocompress(msg)

    -- Handle parsing of all blocks
    local i = 1
    local j = 1
    while j <= n do
        if data[j] == AIO_EndBlock then
            -- Using pcall here so errors wont stop handling other blocks in the msg
            local success, errormsg = pcall(AIO_HandleBlock, player, unpack(data, i, j-1))
            if not success then
                if AIO_SERVER then
                    AIO_debug(errormsg)
                else
                    print(errormsg)
                end
            end
            i = j+1
        end
        j = j+1
    end
end

-- Handles cleaning and assembling the messages received
-- Messages can be 255 characters long, so big messages will be split
local plrdata = {}
-- Timed event on server side to remove messages that take too long to arrive (player disconnected)
-- Time for remove is at top of this file
local function RemoveData(guid)
    if not plrdata[guid] then
        return
    end
    if AIO_SERVER and plrdata[guid].timer then
        player:RemoveEventById(plrdata[guid].timer)
    end
    plrdata[guid] = nil
end
local function RemoveMsg(eventid, delay, repeats, player)
    plrdata[player:GetGUIDLow()] = nil
end
-- Handles incoming addon messages. Parses them, saves them and handles all
-- unusual cases for too long, too delayed and incorrect messages
local function AIO_HandleIncomingMsg(msg, player)
    -- Received a long message part (msg split into 255 character parts)
    local msgid, msg = ssub(msg, 1,1), ssub(msg, 2)

    if msgid == AIO_ShortMsg then
        -- Received <= 255 char msg, direct parse, take out the msg tag first
        AIO_ParseBlocks(msg, player)
        return
    end

    -- guid is used to store information about long messages for specific player
    local guid = AIO_SERVER and player:GetGUIDLow() or 1

    if msgid == AIO_LongMsgStart then
        -- The first message of a long message received. Erase any previous message (reload can mess etc)
        RemoveData(guid)
        local data = {
            count = 1,
            messages = msg
        }
        plrdata[guid] = data

        if AIO_SERVER then
            data.timer = player:RegisterEvent(RemoveMsg, AIO_MSG_REMOVE_DELAY, 1)
        else
            data.timer = true
        end
        return
    end

    local data = plrdata[guid]
    if not data then
        return
    end
    if not data.messages or not data.timer or not data.count then
        -- invalid data or msg not started yet and should have
        RemoveData(guid)
        return
    end
    if AIO_SERVER and data.count > AIO_MAX_PACKET_COUNT then
        -- On server side ignore too many packets
        RemoveData(guid)
        AIO_debug("Too long message from, try tweaking AIO_MAX_PACKET_COUNT")
        return
    end

    if msgid == AIO_LongMsgEnd then
        -- The last message of a long message received.
        AIO_ParseBlocks(data.messages..msg, player)
        RemoveData(guid)
        return
    elseif msgid == AIO_LongMsg then
        -- A part of a long message received.
        data.count = data.count + 1
        data.messages = data.messages..msg
        return
    end
end

-- Erase data on logout
if AIO_SERVER then
    local function Erase(event, player)
        RemoveData(player:GetGUIDLow())
    end
    RegisterPlayerEvent(4, Erase)
end

-- Adds a new callback function for AIO that is called if
-- a block with the same name is recieved and the block has the correct format if given.
-- fmt is a table of lua type strings: {"string", "table", "number", ...} and it can be left out (nil)
-- All parameters the client sends will be passed to func when called
-- Only one function can be a handler for one name (subject for change)
function AIO.RegisterEvent(name, func, fmt)
    assert(type(name) == "string", "name of the registered event string expected")
    assert(type(func) == "function", "callback function must be a function")
    assert(fmt == nil or type(fmt) == "table", "format must be a table of lua types or nil")
    assert(not AIO_BLOCKHANDLES[name], "an event is already registered for the name: "..name)
    for k,v in ipairs(fmt or {}) do
        assert(type(v) == "string", "fmt must contain only lua type strings")
    end
    AIO_BLOCKHANDLES[name] = {func = func, fmt = fmt}
end

-- Adds a table of handler functions for the specified name.
-- You can fill a table with functions and use this to add them for a name.
-- Then when a message like AIO.Msg():Add("MyName", "HandlerName"):Send()
-- is received, the handlertable["HandlerName"] will be executed with player and additional params passed to the block.
-- Returns the passed table
function AIO.AddHandlers(name, handlertable)
    assert(type(name) == 'string', "#1 string expected")
    assert(type(handlertable) == 'table', "#2 a table expected")

    for k,v in pairs(handlertable) do
        assert(type(v) == 'function', "#2 a table of functions expected, found a "..type(v).." value")
    end

    local function handler(player, key, ...)
        if key and handlertable[key] then
            handlertable[key](player, ...)
        end
    end
    AIO.RegisterEvent(name, handler)
    return handlertable
end

-- Adds the current file as an AIO sent addon.
-- Can be used from server and client, but on client does nothing.
-- You can provide path and/or name of the lua file to add, but if
-- omitted the file the function is executed in will be used as path
-- and the path's or given path's file name will be used.
-- Returns true if addon was added
function AIO.AddAddon(path, name)
    if AIO_SERVER then
        path = path or debug.getinfo(2, 'S').short_src
        name = name or match(path, "([^/]*)$")
        local code = AIO_ReadFile(path)
        AIO.AddAddonCode(name, code)
        AIO_debug("Added addon path&name:", path, name)
        return true
    end
end

if AIO_SERVER then
    -- A shorthand for sending a message for a handler.
    function AIO.Handle(player, name, handlername, ...)
        assert(type(player) == 'userdata', "#1 player expected")
        assert(type(name) == 'string', "#2 string expected")
        return AIO.Msg():Add(name, handlername, ...):Send(player)
    end

    local blrot = bit32.lrotate -- requires bit lib (lua 5.2)
    local sbyte = string.byte
    -- Calculates a checksum for the string and returns it
    local function AIO_crc(code)
        assert(type(code) == 'string', "#1 must be a string")
        local sum = 0
        for i = 1, #code do
            sum = blrot(sum, 1)
            sum = sum + sbyte(code, i)
        end
        return sum
    end

    -- Adds the addon code to the sent addons on login.
    -- The addon code is trimmed according to settings at top of this file.
    -- The addon is cached on client side and will be updated if needed.
    -- name is an unique ID for the addon, usually you can use the file name or addon name there
    -- Do note that short names are better since they are sent back and forth to indentify files
    function AIO.AddAddonCode(name, code)
        AIO_assert(type(name) == 'string', "#1 string expected", 2)
        AIO_assert(type(code) == 'string', "#2 string expected", 2)
        if AIO_CODE_OBFUSCATE then
            code = LuaSrcDiet(code)
        end
        AIO_assert(type(code) == 'string', "Some code trimming operation failed", 2)
        AIO_ADDONS[name] = {name=name, crc=AIO_crc(code), code=code}
        AIO_ADDONSORDER[#AIO_ADDONSORDER+1] = AIO_ADDONS[name]
    end

    -- Adds a new function that is called when an init message
    -- is about to be sent by server. The function is called before sending and
    -- the message is passed to it along with the player if available:
    -- func(msg[, player])
    -- you can modify the passed message and or return a new one
    function AIO.AddOnInit(func)
        AIO_assert(type(func) == 'function', "#1 function expected", 2)
        table.insert(AIO_INITHOOKS, func)
    end

    -- This restricts player's ability to request the initial UI to some set time delay
    local timers = {}
    local function RemoveInitTimer(eventid, playerguid)
        if type(playerguid) == "number" then
            timers[playerguid] = nil
        end
    end
    -- This handles sending initial UI to player.
    -- The Client sends a request to the server for the addons along with it's cached addon data.
    -- Then the server checks what files it has to send back and what it has to remove from the client's cache.
    -- Then after server sends the required data to client, the client will one by one execute the addons
    -- in the same order as they are sent from the server.
    local versionmsg = AIO.Msg():Add("AIO", "Init", AIO_VERSION)
    function AIO_HANDLERS.Init(player, version, ...)
        -- check that the player is not on cooldown for init calling
        local guid = player:GetGUIDLow()
        if timers[guid] then
            return
        end
        -- make a new cooldown for init calling
        timers[guid] = CreateLuaEvent(function(e) RemoveInitTimer(e, guid) end, AIO_UI_INIT_DELAY, 1) -- the timer here (AIO_UI_INIT_DELAY) is the min time in ms between inits the player can do

        -- Check for bad version and send version back for error directly
        if version ~= AIO_VERSION then
            versionmsg:Send(player)
            return
        end

        local initmsg = AIO.Msg():Append(versionmsg)
        local cached = {}
        for i = 1, select('#',...)-1, 2 do
            local name = select(i, ...)
            local crc = select(i+1, ...)
            if type(name) == 'string' and type(crc) == 'number' then
                if AIO_ADDONS[name] then
                    if AIO_ADDONS[name].crc == crc then
                        cached[name] = 1 -- valid
                    else
                        cached[name] = 2 -- outdated
                    end
                else
                    cached[name] = 3 -- not valid
                end
                AIO_debug("Cache state:", name, cached[name])
            end
        end
        for i = 1, #AIO_ADDONSORDER do
            local data = AIO_ADDONSORDER[i]
            local name = data.name
            local crc = data.crc
            local code = data.code
            if cached[name] then
                if cached[name] == 1 then -- valid
                    -- send crc only
                    initmsg:Add("AIO", "Addon", name, 0, nil)
                elseif cached[name] == 2 then -- outdated
                    -- send new
                    initmsg:Add("AIO", "Addon", name, crc, code)
                elseif cached[name] == 3 then -- not valid
                    -- send nil for erase
                    initmsg:Add("AIO", "Addon", name, nil, nil)
                end
            else
                -- not cached, send new
                initmsg:Add("AIO", "Addon", name, crc, code)
            end
        end

        for k,v in ipairs(AIO_INITHOOKS) do
            initmsg = v(initmsg, player) or initmsg
        end
        initmsg:Send(player)
    end

    -- An addon message event handler for the lua engine
    -- If the message data is correct, move the message forward to the AIO message handler.
    local function ONADDONMSG(event, sender, Type, prefix, msg, target)
        if prefix == AIO_Prefix and tostring(sender) == tostring(target) then
            AIO_HandleIncomingMsg(msg, sender)
        end
    end
    RegisterServerEvent(30, ONADDONMSG)

    for k,v in ipairs(GetPlayersInWorld()) do
        AIO.Handle(v, "AIO", "ForceReload")
    end

else

    -- A shorthand for sending a message for a handler.
    function AIO.Handle(name, handlername, ...)
        assert(type(name) == 'string', "#1 string expected")
        return AIO.Msg():Add(name, handlername, ...):Send()
    end

    -- Key is a key for a variable in the global table _G
    -- The variable is stored when the player logs out and will be restored
    -- when he logs back in before the addon codes are run
    -- these variables are account bound
    function AIO.AddSavedVar(key)
        AIO_assert(key ~= nil, "#1 table key expected", 2)
        AIO_SAVEDVARS[key] = true
    end

    -- Key is a key for a variable in the global table _G
    -- The variable is stored when the player logs out and will be restored
    -- when he logs back in before the addon codes are run
    -- these variables are character bound
    function AIO.AddSavedVarChar(key)
        AIO_assert(key ~= nil, "#1 table key expected", 2)
        AIO_SAVEDVARSCHAR[key] = true
    end

    AIO_FRAMEPOSITIONS = AIO_FRAMEPOSITIONS or {}
    AIO.AddSavedVar("AIO_FRAMEPOSITIONS")
    AIO_FRAMEPOSITIONSCHAR = AIO_FRAMEPOSITIONSCHAR or {}
    AIO.AddSavedVarChar("AIO_FRAMEPOSITIONSCHAR")
    -- Makes the frame save it's position over relog
    -- If char is true, the position saving is character bound, otherwise account bound
    function AIO.SavePosition(frame, char)
        LibWindow.RegisterConfig(frame, char and AIO_FRAMEPOSITIONSCHAR or AIO_FRAMEPOSITIONS)
        LibWindow.RestorePosition(frame)
        LibWindow.SavePosition(frame)
        table.insert(AIO_SAVEDFRAMES, frame)
    end

    -- A client side event handler
    -- Passes the incoming message to AIO message handler if it is valid
    local function ONADDONMSG(self, event, prefix, msg, Type, sender)
        if prefix == AIO_Prefix then
            if event == "CHAT_MSG_ADDON" and sender == UnitName("player") then
                -- Normal AIO message handling from addon messages
                AIO_HandleIncomingMsg(msg, sender)
            end
        end
    end
    local MsgReceiver = CreateFrame("Frame")
    MsgReceiver:RegisterEvent("CHAT_MSG_ADDON")
    MsgReceiver:SetScript("OnEvent", ONADDONMSG)

    -- A block handler for AddSavedVar name,
    -- Adds a new character bound saved var. See AIO.AddSavedVar(key) for more
    function AIO_HANDLERS.AddSavedVar(player, key)
        AIO_assert(key ~= nil, "#1 table key expected", 2)
        AIO.AddSavedVar(key)
    end

    -- A block handler for AddSavedVarChar name,
    -- Adds a new character bound saved var. See AIO.AddSavedVarChar(key) for more
    function AIO_HANDLERS.AddSavedVarChar(player, key)
        AIO_assert(key ~= nil, "#1 table key expected", 2)
        AIO.AddSavedVarChar(key)
    end

    -- A block handler for Function name, executes the sent function with passed parameters.
    -- Functions can not be sent or executed on server side.
    function AIO_HANDLERS.Function(player, Func, ...)
        if type(Func) ~= "function" then
            error(Func ~= nil, "#2 valid function or global table key expected", 1)
            error(_G[Func] ~= nil, "#2 valid function or global table key expected", 1)
            Func = _G[Func]
        end
        Func(...)
    end

    -- A block handler for Init name, checks the version number and errors if needed
    -- On wrong version prevents handling any more messages
    function AIO_HANDLERS.Init(player, version)
        AIO_INITED = true
        if(AIO_VERSION ~= version) then
            print("You have AIO version "..AIO_VERSION.." and the server uses "..(version or "nil")..". Get the same version")
            -- stop handling any incoming messages
            AIO_HandleBlock = function() end
        else
            print("Initialized AIO version "..AIO_VERSION..". Type '/aio help' for commands")
        end
    end

    -- A block handler for Addon name.
    -- Stores new and changed addons to cache and runs the addon from cache
    -- Also removes removed and outdated addons
    -- On wrong version prevents handling any more messages
    function AIO_HANDLERS.Addon(player, name, crc, code)
        if type(name) ~= 'string' then
            return
        end
        AIO_debug("Incoming addon (name, crc, hascode): "..name, crc, not not code)
        if crc and code then
            AIO_sv_Addons[name] = {crc=crc, code=code}
        else
            if not crc or not AIO_sv_Addons[name] then
                AIO_sv_Addons[name] = nil
                return
            end
        end
        assert(loadstring(AIO_sv_Addons[name].code, name))()
    end

    -- Forces reload of UI for user on next action
    function AIO_HANDLERS.ForceReload(player)
        local frame = CreateFrame("BUTTON")
        frame:SetToplevel(true)
        frame:SetFrameStrata("TOOLTIP")
        frame:SetFrameLevel(100)
        frame:SetAllPoints(WorldFrame)
        -- frame.texture = frame:CreateTexture()
        -- frame.texture:SetAllPoints(frame)
        -- frame.texture:SetTexture(0.1, 0.1, 0.1, 0.5)
        frame:SetScript("OnClick", ReloadUI)
        print("AIO: Force reloading UI")
        message("AIO: Force reloading UI")
    end

    local frame = CreateFrame("FRAME") -- Need a frame to respond to events
    frame:RegisterEvent("ADDON_LOADED") -- Fired when saved variables are loaded
    frame:RegisterEvent("PLAYER_LOGOUT") -- Fired when about to log out

    -- message to request initialization of UI
    function frame:OnEvent(event, addon)
        if event == "ADDON_LOADED" and addon == "AIO" then
            -- Our saved variables are ready at this point. If there is no save, they will be nil
            -- Must be before any other addon action like sending init request
            if type(AIO_sv) ~= 'table' then
                AIO_sv = {} -- This is the first time this addon is loaded; initialize the var
            end
            if type(AIO_sv_char) ~= 'table' then
                AIO_sv_char = {} -- This is the first time this addon is loaded; initialize the var
            end
            if type(AIO_sv_Addons) ~= 'table' then
                AIO_sv_Addons = {} -- This is the first time this addon is loaded; initialize the var
            end

            -- Restore addon saved variables to global namespace
            -- Must be before sending init request
            for k,v in pairs(AIO_sv) do
                if _G[k] then
                    AIO_debug("Overwriting global var _G["..k.."] with a saved var")
                end
                _G[k] = v
            end
            for k,v in pairs(AIO_sv_char) do
                if _G[k] then
                    AIO_debug("Overwriting global var _G["..k.."] with a saved character var")
                end
                _G[k] = v
            end

            -- Request initialization of UI if not done yet
            -- works by timer for every second. Timer shut down after inited.
            -- initmsg consists of the version and all known crc codes for cached addons.
            local rem = {}
            local addons = {}
            for name, data in pairs(AIO_sv_Addons) do
                if type(name) ~= 'string' or type(data) ~= 'table' or type(data.crc) ~= 'number' or type(data.code) ~= 'string' then
                    table.insert(rem, name)
                else
                    table.insert(addons, name)
                    table.insert(addons, data.crc)
                end
            end
            for _,name in ipairs(rem) do
                AIO_sv_Addons[name] = nil -- remove invalid addons
            end

            local initmsg = AIO.Msg():Add("AIO", "Init", AIO_VERSION, unpack(addons))

            local reset = 1
            local timer = reset
            local function ONUPDATE(self, diff)
                if(AIO_INITED) then
                    self:SetScript("OnUpdate", nil)
                    initmsg = nil
                    reset = nil
                    timer = nil
                    return
                end
                if (timer < diff) then
                    initmsg:Send()
                    timer = reset
                else
                    timer = timer - diff
                end
            end
            frame:SetScript("OnUpdate", ONUPDATE)
            initmsg:Send()
        elseif event == "PLAYER_LOGOUT" then
            -- On logout we must store all global namespace to saved vars
            AIO_sv = {} -- discard vars that no longer exist
            for key,_ in pairs(AIO_SAVEDVARS or {}) do
                AIO_sv[key] = _G[key]
            end
            AIO_sv_char = {} -- discard vars that no longer exist
            for key,_ in pairs(AIO_SAVEDVARSCHAR or {}) do
                AIO_sv_char[key] = _G[key]
            end

            for k,v in ipairs(AIO_SAVEDFRAMES or {}) do
                LibWindow.SavePosition(v)
            end
        end
    end
    frame:SetScript("OnEvent", frame.OnEvent)

    SLASH_AIO1 = "/aio"
    -- Tables holding the command functions and the help messages
    -- both are indexed by the command name. See below for how to add a command and help
    local cmds = {}
    local helps = {}
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

    -- Define slash commands and helps for them
    -- triggered with /aio <command name>
    helps.help = "prints this list"
    function cmds.help()
        print("Available commands:")
        for k,v in pairs(cmds) do
            print("/aio "..k.." - "..(helps[k] or "no info"))
        end
    end
    helps.reset = "resets local AIO cache - clears saved addons and their saved variables and reloads the UI"
    function cmds.reset()
        AIO_SAVEDVARS = nil
        AIO_SAVEDVARSCHAR = nil
        AIO_sv_Addons = nil
        AIO_SAVEDFRAMES = {}
        ReloadUI()
    end
    helps.debug = "toggles showing of debug messages"
    function cmds.debug()
        AIO_ENABLE_DEBUG_MSGS = not AIO_ENABLE_DEBUG_MSGS
    end
end

-- Adds all handlers from AIO_HANDLERS for the "AIO" msg handler
AIO.AddHandlers("AIO", AIO_HANDLERS)

return AIO
