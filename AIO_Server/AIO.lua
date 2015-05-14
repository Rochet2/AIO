--[[
    Copyright (C) 2014-  Rochet2 <https://github.com/Rochet2>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
]]

--[===[
This file should be identical on client and server side
This file contains the base definitions of AIO and the base client-server messaging

Messages are sent as addon messages sender and target are the player
Messages larger than 255 characters (in total) will be split to 255 character parts that will then be assembled and run when whole on the receiver end
Some special characters will be reserved for special purposes, see the definitions below

Messaging is handled by objects you can create with AIO.Msg()
The message will have functions:
msg:Add(Name, ...) -- FuncName, arguments
msg:Send(...) -- Receiver players, will not be used for client->server messages
msg:Append(MSG) -- Appends another message to the message
msg:Clear() -- Deletes the message from the message
msg:ToString() -- Returns the message (always msg var or "")
msg:HasMsg() -- returns true or false depending on msg being string or not
You can code handlers to the receiver end and trigger them with Add
Example of handler on receiver side:
function BlockHandle.Print(value)
    Print(value)
end
Example of how to trigger handler from sender side:
local msg = AIO.Msg() -- new message
msg:Add("Print", "Test") -- new block that triggers Print handler with parameter "test"
msg:Send(player) -- send message to player
See AIO_BlockHandle.lua for more

AIO.HandleBlocks(T, player) is not defined in this file
It is responsible for taking action for all received blocks
See AIO_BlockHandle.lua for definition

There are many useful functions aiding the messaging here
The To functions and ToMsgVal will convert the given value to a string representative of the given value
ToRealVal will reverse this and convert the given string to a real value it should be
Most of these will be used automatically when you use Add. ToFunction is an exception
-- Converts a value to string using special characters to represent the value if needed
function AIO.ToMsgVal(val)
-- Converts a string value from a message to the actual value it represents
function AIO.ToRealVal(val)
-- Converts a string to a function parameter
-- Note that all parameters passed to function will be accessible with ...
-- If RetRealFunc is true, when the string is executed, it returns the function to actually use as function
function AIO.ToFunction(FuncAsString, RetRealFunc)
-- Converts table to parameter
function AIO.ToTable(tbl)
-- Converts boolean to parameter
function AIO.ToBoolean(bool)
-- Returns nil parameter
function AIO.ToNil()
-- Converts a table to string
function table.tostring( tbl )
-- Converts a string created with table.tostring(tbl) back to table. Will convert Msg values to their real values
function table.fromstring( str )

When sending a function, you will NEED to use AIO.ToFunction(FuncAsString, RetRealFunc)
You will be able to access passed variables with vararg ...
Example:
local func = AIO.ToFunction("print(...)")
local msg = AIO.Msg() -- new message
msg:Add("Function", func, "Test", 1) -- Add a block to call Function handler
msg:Send(player) -- Prints Test 1 on receiver end

Examples for RetRealFunc:
local func = AIO.ToFunction("return print", true)
msg:Add("Function", func, "Test", 1)
msg:Send(player) -- Prints Test 1 on receiver end

local code = [[
local function MyFunc(var1, var2)
    print(var1 == var2)
end
return MyFunc
]]
local func = AIO.ToFunction(code, true)
msg:Add("Function", func, "a", "b")
msg:Send(player) -- Prints false on receiver end
]===]

-- Check if loaded
-- Try to avoid multiple loads with require etc
if (type(AIO) == "table") then
    error("AIO was already loaded or something is wrong")
end

-- AIO main table
AIO =
{
    -- A server side AIO.Msg() that will be sent on init to player
    -- you should add all addon code here with AIO.AddInitMsg(msg)
    INITMSG = nil,
    -- Client side flag for noting if the client has been inited or not
    -- Server side flag for noting when server load operations have been done and they should no longer be done
    INITED = false,
    -- Server and Client side custom coded handlers for incoming data
    BLOCKHANDLES = {},
}

AIO.SERVER = type(GetLuaEngine) == "function"
AIO.Version = 0.60
-- Used for client-server messaging
AIO.Prefix  = "AIO"
-- ID characters for client-server messaging
AIO.ShortMsg        = 'a'
AIO.LongMsg         = 'b'
AIO.LongMsgStart    = 'c'
AIO.LongMsgEnd      = 'd'
AIO.EndBlock        = 'e'
AIO.EndData         = 'f'
AIO.True            = 'g'
AIO.False           = 'h'
AIO.Nil             = 'i'
AIO.Table           = 'j'
AIO.Function        = 'k'
AIO.String          = 'l'
AIO.Number          = 'm'
AIO.pInf            = 'n'
AIO.nInf            = 'o'
AIO.nNan            = 'p'
AIO.pNan            = 'q'
AIO.TableSep        = 'r'
AIO.Compressed      = 's'
AIO.Uncompressed    = 't'
AIO.CodeChar        = '&' -- some really rare character
AIO.CodeEscaper     = '~'
AIO.Prefix = AIO.Prefix:sub(1, 16) -- shorten prefix to max allowed if needed
AIO.ServerPrefix = ("S"..AIO.Prefix):sub(1, 16)
AIO.ClientPrefix = ("C"..AIO.Prefix):sub(1, 16)
AIO.MsgLen = 255 -1 -math.max(AIO.ServerPrefix:len(), AIO.ClientPrefix:len()) -1 -- remove \t, prefix, msg type indentifier

-- Server client messaging limits
-- Max limit of packets from client to server, default 100 (avoid overflow from bad user)
AIO.MAX_PACKET_COUNT    = 100
-- Max time to wait for a message before it is erased, default 30 sec
AIO.MSG_REMOVE_DELAY    = 30*1000 -- ms
-- Delay between possible sending of full addon code, default 4 sec (avoid lagging from bad user)
AIO.UI_INIT_DELAY       = 4*1000 -- ms
-- Setting to enable and disable compressing for messages
AIO.MSG_COMPRESS        = true

-- premature optimization ftw
local type = type
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local AIO = AIO

if AIO.SERVER then
    require("AIO_LibCompress")
end

function AIO.assert(cond, msg, level)
    if (not cond) then
        error(msg or "AIO assertion failed", (level or 1)+1)
    end
end

-- Reads a file at given absolute or relative to server root path
-- returns the full file contents as a string
function AIO.ReadFile(path)
    local f = assert(io.open(path, "r"), 2)
    local str = f:read("*all")
    f:close()
    return str
end

-- Some lua compatibility
AIO.loadstring = loadstring or load -- loadstring name varies with lua 5.1 and 5.2
AIO.unpack = table.unpack or unpack -- unpack place varies with lua 5.1 and 5.2
AIO.maxn = table.maxn or function(t) local n = 0 for k, _ in pairs(t) do if(type(k) == "number" and k > n) then n = k end end return n end -- table.maxn was removed in lua 5.2

-- Merges t2 to t1 (tables)
function AIO.TableMerge(t1, t2)
    for k,v in pairs(t2) do
        if (type(v) == "table") then
            if(type(t1[k]) ~= "table") then
                t1[k] = {}
            end
            AIO.TableMerge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

-- Functions for handling converting table to string and from string
-- table.tostring(t), table.fromstring(s)
function table.tostring( tbl )
    AIO.assert(type(tbl) == "table", "#1 table expected", 2)
    local result = {}
    for k, v in pairs( tbl ) do
        table.insert( result, AIO.ToMsgVal( k ) )
        table.insert( result, AIO.ToMsgVal( v ) )
    end
    return table.concat( result, AIO.CodeChar..AIO.TableSep )..AIO.CodeChar..AIO.TableSep
end

function table.fromstring( str )
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    local res = {}
    for k, v in str:gmatch("(.-)"..AIO.CodeChar..AIO.TableSep.."(.-)"..AIO.CodeChar..AIO.TableSep) do
        local _k, _v = AIO.ToRealVal(k), AIO.ToRealVal(v)
        if (_k ~= nil) then
            res[_k] = _v
        end
    end
    return res
end

-- Returns true if var is an AIO function table object
function AIO.IsFunction(var)
    if(type(var) ~= "table") then
        return false
    end
    if(type(var.F) ~= "string" or not var.AIOF) then
        return false
    end
    return true
end

-- Converts a string to bytehexstring - unused currently
function AIO.ToByte(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (string.format((("%02x"):rep(str:len())), string.byte(str, 1, str:len())))
end
local function hextochar(hexstr) return (string.char((tonumber(hexstr, 16)))) end
-- Converts a bytehexstring to string - unused currently
function AIO.FromByte(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (string.gsub(str, "%x%x", hextochar))
end

-- Escapes special characters
function AIO.Encode(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (string.gsub(str, AIO.CodeChar, AIO.CodeChar..AIO.CodeEscaper))
end
-- Unescapes special characters
function AIO.Decode(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (string.gsub(str, AIO.CodeChar..AIO.CodeEscaper, AIO.CodeChar))
end

-- Converts a string to a function parameter
-- Note that all parameters passed to function will be accessible with ...
-- If RetRealFunc is true, when the string is executed, it returns the function to actually use as function
function AIO.ToFunction(FuncAsString, RetRealFunc)
    AIO.assert(type(FuncAsString) == "string", "#1 string expected", 2)
    return {F = FuncAsString, R = RetRealFunc, AIOF = true}
end
-- Converts table to parameter
function AIO.ToTable(tbl)
    AIO.assert(type(tbl) == "table", "#1 table expected", 2)
    return AIO.Table..table.tostring(tbl)
end
-- Returns string parameter
function AIO.ToString(val)
    AIO.assert(type(val) == "string", "#1 string expected", 2)
    return AIO.String..val
end
-- Returns number parameter
function AIO.ToNumber(val)
    val = tonumber(val)
    AIO.assert(val, "#1 number expected", 2)
    
    if val == math.huge then      -- test for +inf
        return AIO.pInf
    elseif val == -math.huge then -- test for -inf
        return AIO.nInf
    elseif val ~= val then        -- test for nan and -nan
        if tostring(val):find('-', 1, true) == 1 then
            return AIO.nNan
        end
        return AIO.pNan
    end
    return AIO.Number..tostring(val)
end
-- Converts boolean to parameter
function AIO.ToBoolean(bool)
    if (bool) then
        return AIO.True
    else
        return AIO.False
    end
end
-- Returns nil parameter
function AIO.ToNil()
    return AIO.Nil
end

-- Converts a value to string using special characters to represent the value if needed
function AIO.ToMsgVal(val)
    local ret
    local Type = type(val)
    if (Type == "string") then
        -- if(val:match("^"..AIO.String.."%x*$") == 1) then error("Reconverting string to string:"..val, 1) end
        ret = AIO.ToString(val)
    elseif (Type == "number") then
        ret = AIO.ToNumber(val)
    elseif (Type == "boolean") then
        ret = AIO.ToBoolean(val)
    elseif (Type == "nil") then
        ret = AIO.ToNil()
    elseif (Type == "function") then
        error("#1 Cant pass function, use AIO.ToFunction(FuncAsString) to pass a function parameter", 2)
        return
    elseif (Type == "table") then
        if (AIO.IsFunction(val)) then
            ret = AIO.Function..table.tostring(val)
        else
            ret = AIO.ToTable(val)
        end
    else
        error("#1 Invalid value type ".. Type, 2)
        return
    end
    return AIO.Encode(ret)
end

-- Converts a string value from a message to the actual value it represents
function AIO.ToRealVal(val)
    AIO.assert(type(val) == "string", "#1 string expected", 2)
    
    local Type, data = AIO.Decode(val):match("(.)(.*)")
    if (not Type or not data) then
        return nil
    elseif (Type == AIO.Nil) then
        return nil
    elseif (Type == AIO.True) then
        return true
    elseif (Type == AIO.False) then
        return false
    elseif (Type == AIO.String) then
        return data
    elseif (Type == AIO.Number) then
        return tonumber(data)
    elseif (Type == AIO.pInf) then
        return math.huge
    elseif (Type == AIO.nInf) then
        return -math.huge
    elseif (Type == AIO.pNan) then
        return -(0/0)
    elseif (Type == AIO.nNan) then
        return 0/0
    elseif (Type == AIO.Function) then
        if (AIO.SERVER) then
            return nil -- ignore on server side, unsafe
        end
        local tbl = table.fromstring(data)
        if (not AIO.IsFunction(tbl)) then
            return nil
        end
        local func, err = AIO.loadstring(tbl.F)
        AIO.assert(func, err, 2)
        if (tbl.R) then
            -- RetRealFunc was true
            func = func()
        end
        return func
    elseif(Type == AIO.Table) then
        return table.fromstring(data)
    end
    
    return nil -- val
end

-- Creates a new message that you can append stuff to and send to client or server
function AIO.Msg()
    local msg = {}
    
    -- Appends given value to the message for last block
    function msg:AddVal(val)
        if(not self.MSG) then
            self.MSG = "";
        end
        self.MSG = self.MSG..AIO.ToMsgVal(val)..AIO.CodeChar..AIO.EndData
        return self
    end
    
    -- Add a new block to object.
    -- Tag Data Name Data Arguments
    function msg:Add(Name, ...)
        AIO.assert(Name, "#1 Block must have name", 2)
        if(not self.MSG) then
            self.MSG = "";
        else
            self.MSG = self.MSG..AIO.CodeChar..AIO.EndBlock
        end
        self:AddVal(Name)
        for i = 1, select('#',...) do
            self:AddVal(select(i, ...))
        end
        return self
    end
    
    -- Function to append messages together
    -- Example AIO.Msg():Append(msg):Append(msgasstring):Send(...)
    function msg:Append(msg2)
        if(not msg2) then
            return self
        end
        if(not self.MSG) then
            self.MSG = "";
        end
        if(type(msg2) == "string") then
            self.MSG = self.MSG..AIO.CodeChar..AIO.EndBlock..msg2
        elseif(type(msg2) == "table") then
            self:Append(msg2.MSG)
        else
            error("#1 Cant append "..tostring(msg2), 2)
        end
        return self
    end

    -- varargs are receiver players if needed
    function msg:Send(...)
        AIO.Send(self.MSG..AIO.CodeChar..AIO.EndBlock, ...)
        return self
    end
    
    function msg:Clear()
        self.MSG = nil
        return self
    end
    
    function msg:ToString()
        return self.MSG or ""
    end
    
    function msg:HasMsg()
        return type(self.MSG) == "string"
    end
    
    return msg
end

-- Selects a method to send an addon message
function AIO.SendAddonMessage(msg, player)
    if(AIO.SERVER) then
        -- server -> client
        if(player) then
            player:SendAddonMessage(AIO.ServerPrefix, msg, 7, player)
        end
    else
        -- client -> server
        SendAddonMessage(AIO.ClientPrefix, msg, "WHISPER", UnitName("player"))
    end
end

-- Send msg to all players (variable arguments) or self
function AIO.SendToPlayers(msg, ...)
    for i = 1, select('#',...) do
        AIO.Send(msg, select(i, ...))
    end
end

-- Send msg. Can have one or more receivers (no receivers when sending from client -> server)
function AIO.Send(msg, player, ...)
    AIO.assert(type(msg) == "string", "#1 string expected", 2)
    
    if AIO.MSG_COMPRESS then
        msg = AIO.Compressed..assert(TLibCompress.CompressLZW(msg))
    else
        msg = AIO.Uncompressed..msg
    end
    
    -- More than one receiver, mass send message
    if(...) then
        AIO.SendToPlayers(msg, player, ...)
        return
    end
    
    -- split message to 255 character packets if needed (send long message)
    if (msg:len() <= AIO.MsgLen) then
        -- Send short <= 255 long msg
        AIO.SendAddonMessage(AIO.ShortMsg..msg, player)
    else
        -- Calculate amount of messages to send -1 since one is the end message
        local msgs = math.ceil(msg:len() / AIO.MsgLen)-1
        AIO.SendAddonMessage(AIO.LongMsgStart..string.sub(msg, 1, AIO.MsgLen), player)
        for i = 2, msgs do -- starts at 2 since one message was already sent
            AIO.SendAddonMessage(AIO.LongMsg..string.sub(msg, ((i-1)*AIO.MsgLen)+1, (i*AIO.MsgLen)), player)
        end
        AIO.SendAddonMessage(AIO.LongMsgEnd..string.sub(msg, ((msgs)*AIO.MsgLen)+1, ((msgs+1)*AIO.MsgLen)), player)
    end
end

-- Handles cleaning and assembling the messages received
-- Messages can be 255 characters long, so big messages will be split
local Timers = {}
local Packets = {}
local LongMessages = {}
local function RemoveMsg(eventid, delay, repeats, player)
    local guid = player:GetGUIDLow()
    LongMessages[guid] = nil
    Packets[guid] = nil
    Timers[guid] = nil
end
function AIO.HandleIncomingMsg(msg, player)
    -- Received a long message part (msg split into 255 character parts)
    local guid = AIO.SERVER and player:GetGUIDLow() or 1
    if (msg:find(AIO.ShortMsg) == 1) then
        -- Received <= 255 char msg, direct parse, take out the msg tag first
        AIO.ParseBlocks(msg:sub(AIO.ShortMsg:len() + 1), player)
    elseif (msg:find(AIO.LongMsgStart)) == 1 then
        -- The first message of a long message received. Erase any previous message (reload can mess etc)
        Packets[guid] = 1
        LongMessages[guid] = msg:sub(AIO.LongMsgStart:len() + 1)
        if (AIO.SERVER) then
            if (Timers[guid]) then
                player:RemoveEventById(Timers[guid])
            end
            Timers[guid] = player:RegisterEvent(RemoveMsg, AIO.MSG_REMOVE_DELAY, 1)
        else
            Timers[guid] = true
        end
    elseif (msg:find(AIO.LongMsgEnd)) == 1 then
        -- The last message of a long message received.
        if (not LongMessages[guid] or not Timers[guid] or not Packets[guid]) then
            -- end received with no start
            if (AIO.SERVER and Timers[guid]) then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
            return
        end
        AIO.ParseBlocks(LongMessages[guid]..msg:sub(AIO.LongMsgEnd:len() + 1), player)
        if (AIO.SERVER and Timers[guid]) then
            player:RemoveEventById(Timers[guid])
        end
        LongMessages[guid] = nil
        Packets[guid] = nil
        Timers[guid] = nil
    elseif (msg:find(AIO.LongMsg)) == 1 then
        -- A part of a long message received.
        if (not LongMessages[guid] or not Timers[guid] or not Packets[guid]) then
            -- Ignore if a msg not even started
            if (AIO.SERVER and Timers[guid]) then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
            return
        end
        if (AIO.SERVER and Packets[guid] >= AIO.MAX_PACKET_COUNT) then
            -- On server side ignore too many packets
            if (AIO.SERVER and Timers[guid]) then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
            return
        end
        Packets[guid] = Packets[guid] + 1
        LongMessages[guid] = LongMessages[guid]..msg:sub(AIO.LongMsg:len()+1)
    end
end

-- Extracts blocks from msg to a table that has block data in a table
function AIO.ParseBlocks(msg, player)
    local compression, msg = msg:sub(1, 1), msg:sub(2)
    if compression == AIO.Compressed then
        msg = assert(TLibCompress.DecompressLZW(msg))
    end
    for block in msg:gmatch("(.-)"..AIO.CodeChar..AIO.EndBlock) do
        local t = {}
        -- table.insert is not used here since it ignores nil values
        local i = 1
        for data in block:gmatch("(.-)"..AIO.CodeChar..AIO.EndData) do
            t[i] = AIO.ToRealVal(data)
            i = i+1
        end
        -- This function is not defined in AIO.lua
        -- See AIO_BlockHandle.lua
        -- Passed values are a table containing Add arguments in order and the sender player
        -- At this point all values of the block have been converted to real tables, functions, frames..
        AIO.HandleBlock(t, player)
    end
end

function AIO.CheckArgs(fmt, block)
    if (not fmt) then
        return true
    end
    for i = 1, #fmt do
        if (type(block[i+1]) ~= fmt[i]) then
            return false
        end
    end
    return true
end

-- Helper for HandleBlocks to discard handlename
-- Cant use table.remove since it removes nil values
local function DiscardFirst(_, ...)
    return ...
end

-- Calls the handler for block, see AIO.RegisterEvent
function AIO.HandleBlock(block, player)
    local HandleName = block[1]
    if (not HandleName) then
        return -- invalid message
    end
    local handledata = AIO.BLOCKHANDLES[HandleName]
    if(handledata and AIO.CheckArgs(handledata.fmt, block, n)) then
        -- Using of maxn is important instead of # operator since the table contains
        -- holes (nil mixed in) and # will then possibly return invalid length
        handledata.func(player, DiscardFirst(AIO.unpack(block, 1, AIO.maxn(block))))
    elseif not AIO.SERVER then
        error("Unknown AIO block handle: "..tostring(HandleName))
    end
end

-- Adds a new callback function for AIO that is called if
-- a block with the same name is recieved and the block has the correct format if given
-- fmt is a table of lua type strings: {"string", "table", "number", ...}
-- all parameters the client sends will be passed to func when called
function AIO.RegisterEvent(name, func, fmt)
    assert(type(name) == "string", "name of the registered event must be a string")
    assert(type(func) == "function", "callback function must be a function")
    assert(fmt == nil or type(fmt) == "table", "format must be a table of lua types or nil")
    assert(not AIO.BLOCKHANDLES[name], "an event is already registered for the name: "..name)
    for k,v in ipairs(fmt or {}) do
        assert(type(v) ~= "string", "fmt must contain only lua type strings")
    end
    AIO.BLOCKHANDLES[name] = {func = func, fmt = fmt}
end

-- Adds a new callback function for AIO that is called if
-- a block with the same name is recieved and the block has the correct format if given
-- fmt is a table of lua type strings: {"string", "table", "number", ...}
-- all parameters the client sends will be passed to func when called
function AIO.AddInitMsg(msg)
    AIO.INITMSG = AIO.INITMSG or AIO.Msg():Add("Init", AIO.Version)
    AIO.INITMSG:Append(msg)
end

-- Addon message receiver setup
if(AIO.SERVER) then
    -- This restricts player's ability to request the initial UI to some set time
    local timers = {}
    local function RemoveInitTimer(eventid, playerguid)
        if(type(playerguid) == "number") then
            timers[playerguid] = nil
        end
    end
    -- This handles sending initial UI to player and calling the on UI init hooks
    local function Init(player)
        -- check that the data we have is valid
        if(type(player) ~= "userdata" or type(player.GetObjectType) ~= "function" or player:GetObjectType() ~= "Player") then
            return
        end
        -- check that the player is not on cooldown for init calling
        local guid = player:GetGUIDLow()
        if (timers[guid]) then
            return
        end
        -- make a new cooldown for init calling
        timers[guid] = CreateLuaEvent(function(e) RemoveInitTimer(e, guid) end, AIO.UI_INIT_DELAY, 1) -- the timer here (AIO.UI_INIT_DELAY) is the min time in ms between inits the player can do

        local InitMsg = AIO.INITMSG or AIO.Msg():Add("Init", AIO.Version)
        InitMsg:Send(player)
    end

    AIO.RegisterEvent("Init", Init)

    -- If serverscript
    local function ONADDONMSG(event, sender, Type, prefix, msg, target)
        if(prefix == AIO.ClientPrefix and tostring(sender) == tostring(target)) then
            AIO.HandleIncomingMsg(msg, sender)
        end
    end
    
    local function LOGOUT(event, player)
        -- Remove messages saved for player when he disconnects
        local guid = player:GetGUIDLow()
        LongMessages[guid] = nil
        Packets[guid] = nil
        Timers[guid] = nil
    end

    RegisterServerEvent(30, ONADDONMSG)
    RegisterPlayerEvent(4, LOGOUT)
else
    -- If addonscript
    
    local function Function(player, Func, ...)
        if(type(Func) ~= "function") then
            error(Func ~= nil, "#2 valid function or global table key expected", 1)
            error(_G[Func] ~= nil, "#2 valid function or global table key expected", 1)
            Func = _G[Func]
        end
        Func(...)
    end

    local function Init(player, version)
        AIO.INITED = true
        if(AIO.Version ~= version) then
            print("You have AIO version "..AIO.Version.." and the server uses "..(version or "nil")..". Get the same version")
        else
            print("Initialized AIO version "..AIO.Version)
        end
    end

    AIO.RegisterEvent("Function", Function)
    AIO.RegisterEvent("Init", Init)

    -- message to request initialization of UI
    local initmsg = AIO.Msg():Add("Init")
    
    local function ONADDONMSG(self, event, prefix, msg, Type, sender)
        if (prefix == AIO.ServerPrefix) then
            if(event == "CHAT_MSG_ADDON" and sender == UnitName("player")) then
                -- Normal AIO message handling from addon messages
                AIO.HandleIncomingMsg(msg, sender)
            end
        elseif(event == "PLAYER_LOGIN") then
            -- Request initialization of UI on player login if not done yet
            if(AIO.INITED) then
                return
            end
            initmsg:Send()
        end
    end
    
    -- Request initialization of UI if not done yet
    -- works by timer for every second. Timer shut down after inited.
    local reset = 1
    local timer = reset
    local function ONUPDATE(self, diff)
        if(AIO.INITED) then
            self:SetScript("OnUpdate", nil)
            return
        end
        if (timer < diff) then
            initmsg:Send()
            timer = reset
        else
            timer = timer - diff
        end
    end
    
    local MsgReceiver = CreateFrame("Frame")
    MsgReceiver:RegisterEvent("PLAYER_LOGIN")
    MsgReceiver:RegisterEvent("CHAT_MSG_ADDON")
    MsgReceiver:SetScript("OnEvent", ONADDONMSG)
    MsgReceiver:SetScript("OnUpdate", ONUPDATE)
    
    
    local function Addons(player, ...)
        for i = 1, select('#', ...) do
            local func = assert(AIO.loadstring(select(i, ...)))
            func()
        end
    end
    AIO.RegisterEvent("Addons", Addons)
end

return AIO
