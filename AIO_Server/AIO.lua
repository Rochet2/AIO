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

--[===[
This file should be identical on client and server side.
This file contains the base definitions of AIO and the base client-server messaging.

Messages are sent as addon messages with sender and target are the player.
Messages larger than 255 characters (in total) will be split to 255 character parts that will
then be assembled and run when whole on the receiver end.
Some special characters will be reserved for special purposes, see the definitions below.
You should be able to use the characters safely since they are escaped though.

The whole addon is documented with comments through out.
If you need more information about a function, go see the documentation above it's definition
or see the example codes or the actual function code.

Client-server messaging is handled by objects you can create with AIO.Msg()
IMPORTANT! Do note that the client CAN send anything. Check the received parameters and use caution when coding!
The message will have functions:
    msg:Add(Name, ...) -- handlername, arguments (a block)
    msg:Send(...) -- Receiver players, will not be used for client->server messages
    msg:Append(MSG) -- Appends another message to the message
    msg:Clear() -- Deletes the message from the message
    msg:ToString() -- Returns the message (always msg var or "")
    msg:HasMsg() -- returns true or false depending on msg being string or not

You can code handlers to the receiver end that will trigger when the receiver gets a msg with a block with same name
Note that you can code these from server side as addons and send them like other addon files. )
Example of handler on receiver side:
    local function MyHandler(player, value)
        print(value)
    end
    AIO.RegisterEvent("MyHandler", MyHandler)

Example of how to trigger a block handler from sender side:
    local msg = AIO.Msg()           -- new message
    msg:Add("MyHandler", "Test")    -- new block that triggers MyHandler with parameter "Test"
    msg:Send(player)                -- send message to player

There are many useful functions aiding the messaging here
The AIO.ToMsgVal(value) function will convert the given value to a string representative of that value and return it
The AIO.ToRealVal(value) will reverse this and convert the given string to a real value it should be
Most of the value specific conversion methods are used automatically with ToMsgVal and ToRealVal
You can find them in the code here below, however ToFunction is an exception:
    -- Converts a string to a function parameter
    -- Note that all parameters passed to function will be accessible with ...
    -- If RetRealFunc is true, when the string is executed, it returns the function to actually use as function
    -- RetRealFunc can be omitted
    -- returns the representation string
    AIO.ToFunction(FuncAsString[, RetRealFunc])

When sending a function in a block, you will NEED to use AIO.ToFunction(FuncAsString, RetRealFunc)
You will be able to access passed variables with vararg ...
Note that you can not send functions from client to server.
Example:
    local func = AIO.ToFunction("print(...)")
    local msg = AIO.Msg() -- new message
    msg:Add("Function", func, "Test", 1) -- Add a block to call Function handler
    msg:Send(player) -- Prints Test 1 on the receiving end

Example for RetRealFunc:
    local func = AIO.ToFunction("return print", true) -- Notice difference here
    local msg = AIO.Msg() -- new message
    msg:Add("Function", func, "Test", 1)
    msg:Send(player) -- Prints Test 1 on the receiving end

Another example for RetRealFunc
Noteice how the MyFunc variables are handled here. No need for varargs:
    local code = [[
        local function MyFunc(var1, var2)
            print(var1 == var2)
        end
        return MyFunc
    ]]
    local func = AIO.ToFunction(code, true)
    msg:Add("Function", func, "a", "b")
    msg:Send(player) -- Prints false on the receiving end

a
]===]

-- Check if loaded
-- Try to avoid multiple loads with require etc
if type(AIO) ~= "nil" then
    error("AIO is already defined - something is wrong")
end

local assert = assert
local type = type
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local sub = string.sub
local gsub = string.gsub
local gmatch = string.gmatch
local match = string.match
local find = string.find
local len = string.len
local tinsert = table.insert
local tconcat = table.concat
local format = string.format
local byte = string.byte
local char = string.char
local ceil = math.ceil

-- AIO main table
AIO =
{
    -- Client side table containing frames that need to have their position saved
    SAVEDFRAMES = {},
    -- Contains functions to execute when an init msg is received
    INITHOOKS = {},
    -- A server side table of addon codes
    -- you should add all addon code here with AIO.AddAddon(name, code)
    ADDONS = {},
    -- A server side table for correct order of addons to send
    ADDONSORDER = {},
    -- Client side tables that contain keys to _G table for saved variables
    -- you should add your variables here with AIO.AddSavedVar(key) or AIO.AddSavedVarChar(key)
    SAVEDVARS = {},
    SAVEDVARSCHAR = {},
    -- Client side flag for noting if the client has been inited or not
    -- Server side flag for noting when server load operations have been done and they should no longer be done
    INITED = false,
    -- Server and Client side custom coded handlers for incoming data
    BLOCKHANDLES = {},
    -- Server and Client side functions to execute on AIO messages
    HANDLERS = {},
}

AIO.SERVER = type(GetLuaEngine) == "function"
-- Client must have same version (basically same AIO file)
AIO.Version = 0.75
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
AIO.Prefix = sub(AIO.Prefix, 1, 16) -- shorten prefix to max allowed if needed
AIO.ServerPrefix = sub(("S"..AIO.Prefix), 1, 16)
AIO.ClientPrefix = sub(("C"..AIO.Prefix), 1, 16)
AIO.MsgLen = 255 -1 -math.max(len(AIO.ServerPrefix), len(AIO.ClientPrefix)) -1 -- remove \t, prefix, msg type indentifier

-- Enables some additional prints for debugging
AIO.ENABLE_DEBUG_MSGS   = false -- default false

-- Server client messaging config
-- Max limit of packets from client to server, default 100 (avoid overflow from bad user)
AIO.MAX_PACKET_COUNT    = 100
-- Max time to wait for a message before it is erased, default 15 sec
AIO.MSG_REMOVE_DELAY    = 15*1000 -- ms
-- Delay between possible sending of full addon code, default 4 sec (avoid lagging from bad user)
AIO.UI_INIT_DELAY       = 4*1000 -- ms
-- Setting to enable and disable LZW compressing for messages, default true
AIO.MSG_COMPRESS        = true
-- Setting to enable and disable obfuscation for code to reduce size, default true
AIO.CODE_OBFUSCATE      = true
-- Setting to enable and disable comment and minor whitespace strippng for addons, default false - done by obfuscation
AIO.CODE_STRIP_COMMENTS = false

-- premature optimization ftw
local AIO = AIO

local compressor = TLibCompress
local obfuscator
if AIO.SERVER then
    -- On server we need to require the compressing file
    -- On client it is on the .toc file
    compressor = require("AIO_LibCompress")
    obfuscator = require("LuaSrcDiet")
else
    AIO.lwin = LibStub("LibWindow-1.1")
end

-- Used to print debug messages if AIO.ENABLE_DEBUG_MSGS is true
function AIO.debug(...)
    if AIO.ENABLE_DEBUG_MSGS then
        print("AIO:", ...)
    end
end

-- Errors with msg at given level if condition is false
-- level works like on lua error function
function AIO.assert(cond, msg, level)
    if not cond then
        error("AIO: "..(msg or "AIO assertion failed"), (level or 1)+1)
    end
end

-- Reads a file at given absolute or relative to server root path
-- and returns the full file contents as a string
function AIO.ReadFile(path)
    AIO.debug("Reading a file")
    AIO.assert(type(path) == 'string', "#1 string expected", 2)
    local f = assert(io.open(path, "r"))
    local str = f:read("*all")
    f:close()
    return str
end

-- Some lua compatibility between 5.1 and 5.2
AIO.loadstring = loadstring or load -- loadstring name varies with lua 5.1 and 5.2
AIO.unpack = table.unpack or unpack -- unpack place varies with lua 5.1 and 5.2
AIO.maxn = table.maxn or function(t) local n = 0 for k, _ in pairs(t) do if type(k) == "number" and k > n then n = k end end return n end -- table.maxn was removed in lua 5.2

-- Merges t2 to t1 (tables) by replacing values in t1 with values from t2 and returns t1
function AIO.TableMerge(t1, t2)
    AIO.assert(type(t1) == 'table' and type(t2) == 'table', "parameters #1 and #2 must be tables", 2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) ~= "table" then
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
-- local s = table.tostring(t), local t = table.fromstring(s)
-- Does not support circular table relation which will cause stack overflow
function table.tostring( tbl )
    AIO.assert(type(tbl) == "table", "#1 table expected", 2)
    local result = {}
    for k, v in pairs( tbl ) do
        tinsert( result, AIO.ToMsgVal( k ) )
        tinsert( result, AIO.ToMsgVal( v ) )
    end
    return tconcat( result, AIO.CodeChar..AIO.TableSep )..AIO.CodeChar..AIO.TableSep
end
function table.fromstring( str )
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    local res = {}
    for k, v in gmatch(str, "(.-)"..AIO.CodeChar..AIO.TableSep.."(.-)"..AIO.CodeChar..AIO.TableSep) do
        local _k, _v = AIO.ToRealVal(k), AIO.ToRealVal(v)
        if _k ~= nil then
            res[_k] = _v
        end
    end
    return res
end

-- Returns true if var is an AIO function table object
function AIO.IsFunction(var)
    if type(var) ~= "table" then
        return false
    end
    if type(var.F) ~= "string" or not var.AIOF then
        return false
    end
    return true
end

-- Converts a string to bytehexstring
function AIO.ToByte(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (format((("%02x"):rep(len(str))), byte(str, 1, len(str))))
end
local function hextochar(hexstr) return (char((tonumber(hexstr, 16)))) end
-- Converts a bytehexstring to string
function AIO.FromByte(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (gsub(str, "%x%x", hextochar))
end

-- Escapes special characters
function AIO.Encode(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (gsub(str, AIO.CodeChar, AIO.CodeChar..AIO.CodeEscaper))
end
-- Unescapes special characters
function AIO.Decode(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (gsub(str, AIO.CodeChar..AIO.CodeEscaper, AIO.CodeChar))
end

-- You can not send functions over messages or from client to server
-- Thus we allow sending a string from server to client that contains the function contents:
-- Converts a string to a function parameter
-- Note that all parameters passed to function will be accessible with ...
-- If RetRealFunc is true then when the string is executed it returns a function to actually use as function
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
        if find(tostring(val), '-', 1, true) == 1 then
            return AIO.nNan
        end
        return AIO.pNan
    end
    return AIO.Number..tostring(val)
end
-- Converts boolean to parameter
function AIO.ToBoolean(bool)
    if bool then
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
    if Type == "string" then
        -- if match(val, "^"..AIO.String.."%x*$") == 1 then error("Reconverting string to string:"..val, 1) end
        ret = AIO.ToString(val)
    elseif Type == "number" then
        ret = AIO.ToNumber(val)
    elseif Type == "boolean" then
        ret = AIO.ToBoolean(val)
    elseif Type == "nil" then
        ret = AIO.ToNil()
    elseif Type == "function" then
        error("#1 Cant pass function, use AIO.ToFunction(FuncAsString) to pass a function parameter", 2)
        return
    elseif Type == "table" then
        if AIO.IsFunction(val) then
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

    local Type, data = match(AIO.Decode(val), "(.)(.*)")
    if not Type or not data then
        return nil
    elseif Type == AIO.Nil then
        return nil
    elseif Type == AIO.True then
        return true
    elseif Type == AIO.False then
        return false
    elseif Type == AIO.String then
        return data
    elseif Type == AIO.Number then
        return tonumber(data)
    elseif Type == AIO.pInf then
        return math.huge
    elseif Type == AIO.nInf then
        return -math.huge
    elseif Type == AIO.pNan then
        return -(0/0)
    elseif Type == AIO.nNan then
        return 0/0
    elseif Type == AIO.Function then
        if AIO.SERVER then
            return nil -- ignore on server side, unsafe
        end
        local tbl = table.fromstring(data)
        if not AIO.IsFunction(tbl) then
            return nil
        end
        local func, err = AIO.loadstring(tbl.F)
        AIO.assert(func, err, 2)
        if tbl.R then
            -- RetRealFunc was true
            func = func()
        end
        return func
    elseif Type == AIO.Table then
        return table.fromstring(data)
    end

    return nil -- val
end

-- Creates and returns a new message that you can append stuff to and send to client or server
-- Example: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
function AIO.Msg()
    local msg = {}

    -- Add a new block to message and returns self
    -- A block is a chunk of data identified by a string name
    -- blocks are sent between server and client and handled on the receiving end
    -- by block handlers. Blockhandlers are functions you can assign to
    -- a specific name as a handler with AIO.RegisterEvent(name, func, fmt)
    -- The All values in the block after it's name or added with msg:AddVal(val)
    -- will be passed to the handler function in same order. Name will be omitted
    function msg:Add(Name, ...)
        -- Tag Data Name Data Arguments
        AIO.assert(Name, "#1 Block must have name", 2)
        if self.MSG then
            self.MSG = self.MSG..AIO.CodeChar..AIO.EndBlock
        end
        self:AddVal(Name)
        for i = 1, select('#',...) do
            self:AddVal(select(i, ...))
        end
        return self
    end

    -- Appends given value to the message for last block
    -- and returns self
    function msg:AddVal(val)
        if not self.MSG then
            self.MSG = ""
        end
        self.MSG = self.MSG..AIO.ToMsgVal(val)..AIO.CodeChar..AIO.EndData
        return self
    end

    -- Function to append messages together, returns self
    -- Example AIO.Msg():Append(msg):Append(msg2):Send(...)
    function msg:Append(msg2)
        if type(msg2) == "string" then
            if self.MSG then
                self.MSG = self.MSG..AIO.CodeChar..AIO.EndBlock
            else
                self.MSG = ""
            end
            self.MSG = self.MSG..msg2
        elseif type(msg2) == "table" then
            self:Append(msg2.MSG)
        else
            error("#1 Cant append "..tostring(msg2), 2)
        end
        return self
    end

    -- Functino to send the message to given players
    -- varargs are receiver players if needed
    function msg:Send(player, ...)
        AIO.assert(not AIO.SERVER or player, "Player is nil", 2)
        AIO.Send(self.MSG..AIO.CodeChar..AIO.EndBlock, player, ...)
        return self
    end

    -- Erases the so far built message and returns self
    function msg:Clear()
        self.MSG = nil
        return self
    end

    -- Returns the message string or an empty string
    function msg:ToString()
        return self.MSG or ""
    end

    -- Returns true if the message has something in it
    function msg:HasMsg()
        return type(self.MSG) == "string"
    end

    return msg
end

-- Selects a method to send the string to the player depending on whether
-- running on client or server side. From client to server no player needed
function AIO.SendAddonMessage(msg, player)
    AIO.assert(type(msg) == 'string', "#1 string expected", 2)
    if AIO.SERVER then
        -- server -> client
        AIO.assert(type(player) == 'userdata', "#2 player expected, got "..type(player), 2)
        player:SendAddonMessage(AIO.ServerPrefix, msg, 7, player)
    else
        -- client -> server
        SendAddonMessage(AIO.ClientPrefix, msg, "WHISPER", UnitName("player"))
    end
end

-- Sends the string to all players (variable arguments)
function AIO.SendToPlayers(msg, ...)
    AIO.assert(type(msg) == 'string', "#1 string expected", 2)
    for i = 1, select('#',...) do
        AIO.Send(msg, select(i, ...))
    end
end

-- Sends an AIO.Msg() to given players (vararg).
-- Can have one or more receivers (no receivers when sending from client -> server)
-- Compresses the messages according to settings at top of file
function AIO.Send(msg, player, ...)
    AIO.assert(type(msg) == "string", "#1 string expected", 2)
    AIO.assert(not AIO.SERVER or player, "#2 player expected", 2)

    if AIO.MSG_COMPRESS then
        msg = AIO.Compressed..assert(compressor.CompressLZW(msg))
    else
        msg = AIO.Uncompressed..msg
    end

    -- More than one receiver, mass send message
    if ... then
        AIO.SendToPlayers(msg, player, ...)
        return
    end

    AIO.debug("Sending message length:", len(msg))

    -- split message to 255 character packets if needed (send long message)
    if len(msg) <= AIO.MsgLen then
        -- Send short <= 255 long msg
        AIO.SendAddonMessage(AIO.ShortMsg..msg, player)
    else
        -- Calculate amount of messages to send -1 since one is the end message
        local msgs = ceil(len(msg) / AIO.MsgLen)-1
        AIO.SendAddonMessage(AIO.LongMsgStart..sub(msg, 1, AIO.MsgLen), player)
        for i = 2, msgs do -- starts at 2 since one message was already sent
            AIO.SendAddonMessage(AIO.LongMsg..sub(msg, ((i-1)*AIO.MsgLen)+1, (i*AIO.MsgLen)), player)
        end
        AIO.SendAddonMessage(AIO.LongMsgEnd..sub(msg, ((msgs)*AIO.MsgLen)+1, ((msgs+1)*AIO.MsgLen)), player)
    end
end

-- Handles cleaning and assembling the messages received
-- Messages can be 255 characters long, so big messages will be split
local Timers = {}
local Packets = {}
local LongMessages = {}
-- Timed event on server side to remove messages that take too long to arrive (player disconnected)
-- Time for remove is at top of this file
local function RemoveMsg(eventid, delay, repeats, player)
    local guid = player:GetGUIDLow()
    LongMessages[guid] = nil
    Packets[guid] = nil
    Timers[guid] = nil
end
-- Handles incoming addon messages. Parses them, saves them and handles all
-- unusual cases for too long, too delayed and incorrect messages
function AIO.HandleIncomingMsg(msg, player)
    -- Received a long message part (msg split into 255 character parts)
    -- guid is used to store information about long messages for specific player
    local guid = AIO.SERVER and player:GetGUIDLow() or 1
    if find(msg, AIO.ShortMsg) == 1 then
        -- Received <= 255 char msg, direct parse, take out the msg tag first
        AIO.ParseBlocks(sub(msg, len(AIO.ShortMsg) + 1), player)
    elseif (find(msg, AIO.LongMsgStart)) == 1 then
        -- The first message of a long message received. Erase any previous message (reload can mess etc)
        Packets[guid] = 1
        LongMessages[guid] = sub(msg, len(AIO.LongMsgStart) + 1)
        if AIO.SERVER then
            if Timers[guid] then
                player:RemoveEventById(Timers[guid])
            end
            Timers[guid] = player:RegisterEvent(RemoveMsg, AIO.MSG_REMOVE_DELAY, 1)
        else
            Timers[guid] = true
        end
    elseif (find(msg, AIO.LongMsgEnd)) == 1 then
        -- The last message of a long message received.
        if not LongMessages[guid] or not Timers[guid] or not Packets[guid] then
            -- end received with no start
            if AIO.SERVER and Timers[guid] then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
            return
        end
        AIO.ParseBlocks(LongMessages[guid]..sub(msg, len(AIO.LongMsgEnd) + 1), player)
        if AIO.SERVER and Timers[guid] then
            player:RemoveEventById(Timers[guid])
        end
        LongMessages[guid] = nil
        Packets[guid] = nil
        Timers[guid] = nil
    elseif (find(msg, AIO.LongMsg)) == 1 then
        -- A part of a long message received.
        if not LongMessages[guid] or not Timers[guid] or not Packets[guid] then
            -- Ignore if a msg not even started
            if AIO.SERVER and Timers[guid] then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
            return
        end
        if AIO.SERVER and Packets[guid] >= AIO.MAX_PACKET_COUNT then
            -- On server side ignore too many packets
            if AIO.SERVER and Timers[guid] then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
            AIO.debug("Too long message from, try tweaking AIO.MAX_PACKET_COUNT")
            return
        end
        Packets[guid] = Packets[guid] + 1
        LongMessages[guid] = LongMessages[guid]..sub(msg, len(AIO.LongMsg)+1)
    end
end

-- Extracts blocks from parsed addon messages to a table
function AIO.ParseBlocks(msg, player)
    
    AIO.debug("Received messagelength:", len(msg))

    -- Check if message is compressed and uncompress if needed
    local compression, msg = sub(msg, 1, 1), sub(msg, 2)
    if compression == AIO.Compressed then
        msg = assert(compressor.DecompressLZW(msg))
    end
    -- Handle parsing of all blocks
    for block in gmatch(msg, "(.-)"..AIO.CodeChar..AIO.EndBlock) do
        local t = {}
        local i = 1
        -- handle parsing of all values in block
        for data in gmatch(block, "(.-)"..AIO.CodeChar..AIO.EndData) do
            -- tinsert is not used here since it ignores nil values
            t[i] = AIO.ToRealVal(data)
            i = i+1
        end
        -- Passed values are a table containing msg:Add(blockname, args) arguments in order and the sender player
        -- At this point all values of the block have been converted to real tables, functions..
        AIO.HandleBlock(t, player)
    end
end

-- Checks that all values in given block have the correct type from fmt
-- fmt is a table of lua type strings: {"string", "table", "number"}
-- Does not check anything and returns true if fmt is nil
function AIO.CheckArgs(fmt, block)
    if not fmt then
        return true
    end
    for i = 1, #fmt do
        if type(block[i+1]) ~= fmt[i] then
            AIO.debug("Invalid handle, args dont match fmt", block[1])
            return false
        end
    end
    return true
end

-- Helper for HandleBlock to discard handlename
-- Cant use table.remove since it removes nil values
local function DiscardFirst(_, ...)
    return ...
end

-- Calls the handler for block, see AIO.RegisterEvent
-- for adding handlers for blocks
function AIO.HandleBlock(block, player)
    local HandleName = block[1]
    if not HandleName then
        if AIO.SERVER then
            AIO.debug("Invalid handle, no handle name")
        else
            error("Invalid handle, no handle name")
        end
        return -- invalid message
    end
    local handledata = AIO.BLOCKHANDLES[HandleName]
    if handledata and AIO.CheckArgs(handledata.fmt, block, n) then
        -- found the block handler and arguments match the format.
        -- call the block handler

        -- Using of maxn is important instead of # operator since the table contains
        -- holes (nil mixed in) and # will then possibly return invalid length
        handledata.func(player, DiscardFirst(AIO.unpack(block, 1, AIO.maxn(block))))
    else
        if AIO.SERVER then
            AIO.debug("Unknown AIO block handle: "..tostring(HandleName))
        else
            error("Unknown AIO block handle: "..tostring(HandleName))
        end
    end
    if not AIO.SERVER and not AIO.INITED then
        assert("Received a block before initialization, check your code: "..HandleName)
    end
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
    assert(not AIO.BLOCKHANDLES[name], "an event is already registered for the name: "..name)
    for k,v in ipairs(fmt or {}) do
        assert(type(v) == "string", "fmt must contain only lua type strings")
    end
    AIO.BLOCKHANDLES[name] = {func = func, fmt = fmt}
end

-- Adds a table of handler functions for the specified name.
-- You can fill a table with functions and use this to add them for a name.
-- Then when a message like AIO.Msg():Add("MyName", "HandlerName"):Send()
-- is received, the handlertable["HandlerName"] will be executed with player and additional params passed to the block.
-- Returns the passed table
function AIO.AddHandlers(name, handlertable)
    AIO.assert(type(name) == 'string', "#1 string expected", 2)
    AIO.assert(type(handlertable) == 'table', "#2 a table expected", 2)
    
    for k,v in pairs(handlertable) do
        AIO.assert(type(v) == 'function', "#2 a table of functions expected, found a "..type(v).." value", 2)
    end
    
    local function handler(player, key, ...)
        if key and handlertable[key] then
            handlertable[key](player, ...)
        end
    end
    AIO.RegisterEvent(name, handler)
    return handlertable
end

if AIO.SERVER then
    -- A shorthand for sending a message for a handler.
    function AIO.Handle(player, name, handlername, ...)
        AIO.assert(type(player) == 'userdata', "#1 player expected", 2)
        AIO.assert(type(name) == 'string', "#2 string expected", 2)
        return AIO.Msg():Add(name, handlername, ...):Send(player)
    end
else
    -- A shorthand for sending a message for a handler.
    function AIO.Handle(name, handlername, ...)
        AIO.assert(type(name) == 'string', "#1 string expected", 2)
        return AIO.Msg():Add(name, handlername, ...):Send()
    end
end

-- Adds the current file as an AIO sent addon.
-- Can be used from server and client, but on client does nothing.
-- You can provide path and/or name of the lua file to add, but if
-- omitted the file the function is executed in will be used as path
-- and the path's or given path's file name will be used.
-- Returns true if addon was added
function AIO.AddAddon(path, name)
    if AIO.SERVER then
        path = path or debug.getinfo(2, 'S').short_src
        name = name or path:match("([^/]*)$")
        local code = AIO.ReadFile(path)
        AIO.AddAddonCode(name, code)
        AIO.debug("Added addon path&name:", path, name)
        return true
    end
end

if AIO.SERVER then
    local blrot = bit32.lrotate -- requires bit lib (lua 5.2)
    local sbyte = byte
    -- Calculates a checksum for the string and returns it
    function AIO.crc(code)
        AIO.assert(type(code) == 'string', "#1 must be a string", 2)
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
        AIO.assert(type(name) == 'string', "#1 string expected", 2)
        AIO.assert(type(code) == 'string', "#2 string expected", 2)
        if AIO.CODE_OBFUSCATE then
            code = obfuscator(code)
        end
        if AIO.CODE_STRIP_COMMENTS then
            code = gsub(code, "[%s\n]*%-%-%[(=*)%[.-%]%1%][%s\n]*", gsub("\n"), "[%s\n]*%-%-.-\n", gsub("\n"), "^[%s\n]*(.-)[%s\n]*$", "%1")
        end
        AIO.assert(type(code) == 'string', "Some code trimming operation failed", 2)
        AIO.ADDONS[name] = {name=name, crc=AIO.crc(code), code=code}
        tinsert(AIO.ADDONSORDER, AIO.ADDONS[name])
    end

    -- Adds a new function that is called when an init message
    -- is about to be sent by server. The function is called before sending and
    -- the message is passed to it along with the player if available:
    -- func(msg[, player])
    -- you can modify the passed message and or return a new one
    function AIO.AddOnInit(func)
        AIO.assert(type(func) == 'function', "#1 function expected", 2)
        table.insert(AIO.INITHOOKS, func)
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
    local versionmsg = AIO.Msg():Add("AIO", "Init", AIO.Version)
    function AIO.HANDLERS.Init(player, version, ...)
        -- check that the player is not on cooldown for init calling
        local guid = player:GetGUIDLow()
        if timers[guid] then
            return
        end
        -- make a new cooldown for init calling
        timers[guid] = CreateLuaEvent(function(e) RemoveInitTimer(e, guid) end, AIO.UI_INIT_DELAY, 1) -- the timer here (AIO.UI_INIT_DELAY) is the min time in ms between inits the player can do

        -- Check for bad version and send version back for error directly
        if version ~= AIO.Version then
            versionmsg:Send(player)
            return
        end

        local initmsg = AIO.Msg():Append(versionmsg)
        local cached = {}
        for i = 1, select('#',...)-1, 2 do
            local name = select(i, ...)
            local crc = select(i+1, ...)
            if type(name) == 'string' and type(crc) == 'number' then
                if AIO.ADDONS[name] then
                    if AIO.ADDONS[name].crc == crc then
                        cached[name] = 1 -- valid
                    else
                        cached[name] = 2 -- outdated
                    end
                else
                    cached[name] = 3 -- not valid
                end
                AIO.debug("Cache state:", name, cached[name])
            end
        end
        for i = 1, #AIO.ADDONSORDER do
            local name = AIO.ADDONSORDER[i].name
            local crc = AIO.ADDONSORDER[i].crc
            local code = AIO.ADDONSORDER[i].code
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
        
        for k,v in ipairs(AIO.INITHOOKS) do
            initmsg = v(initmsg, player) or initmsg
        end
        initmsg:Send(player)
    end

    -- An addon message event handler for the lua engine
    -- If the message data is correct, move the message forward to the AIO message handler.
    local function ONADDONMSG(event, sender, Type, prefix, msg, target)
        if prefix == AIO.ClientPrefix and tostring(sender) == tostring(target) then
            AIO.HandleIncomingMsg(msg, sender)
        end
    end
    RegisterServerEvent(30, ONADDONMSG)

    -- A logout event handler for the lua engine
    -- removes all player data on logout
    local function LOGOUT(event, player)
        -- Remove messages saved for player when he disconnects
        local guid = player:GetGUIDLow()
        LongMessages[guid] = nil
        Packets[guid] = nil
        Timers[guid] = nil
    end
    RegisterPlayerEvent(4, LOGOUT)

    for k,v in ipairs(GetPlayersInWorld()) do
        AIO.Handle(v, "AIO", "ForceReload")
    end

else
    
    -- Key is a key for a variable in the global table _G
    -- The variable is stored when the player logs out and will be restored
    -- when he logs back in before the addon codes are run
    -- these variables are account bound
    function AIO.AddSavedVar(key)
        AIO.assert(key ~= nil, "#1 table key expected", 2)
        AIO.SAVEDVARS[key] = true
    end
    
    -- Key is a key for a variable in the global table _G
    -- The variable is stored when the player logs out and will be restored
    -- when he logs back in before the addon codes are run
    -- these variables are character bound
    function AIO.AddSavedVarChar(key)
        AIO.assert(key ~= nil, "#1 table key expected", 2)
        AIO.SAVEDVARSCHAR[key] = true
    end

    -- A block handler for AddSavedVar name,
    -- Adds a new character bound saved var. See AIO.AddSavedVar(key) for more
    function AIO.HANDLERS.AddSavedVar(player, key)
        AIO.assert(key ~= nil, "#1 table key expected", 2)
        AIO.AddSavedVar(key)
    end

    -- A block handler for AddSavedVarChar name,
    -- Adds a new character bound saved var. See AIO.AddSavedVarChar(key) for more
    function AIO.HANDLERS.AddSavedVarChar(player, key)
        AIO.assert(key ~= nil, "#1 table key expected", 2)
        AIO.AddSavedVarChar(key)
    end
    
    AIO_FRAMEPOSITIONS = AIO_FRAMEPOSITIONS or {}
    AIO.AddSavedVar("AIO_FRAMEPOSITIONS")
    AIO_FRAMEPOSITIONSCHAR = AIO_FRAMEPOSITIONSCHAR or {}
    AIO.AddSavedVarChar("AIO_FRAMEPOSITIONSCHAR")
    -- Makes the frame save it's position over relog
    -- If char is true, the position saving is character bound, otherwise account bound
    function AIO.SavePosition(frame, char)
        AIO.lwin.RegisterConfig(frame, char and AIO_FRAMEPOSITIONSCHAR or AIO_FRAMEPOSITIONS)
        AIO.lwin.RestorePosition(frame)
        AIO.lwin.SavePosition(frame)
        table.insert(AIO.SAVEDFRAMES, frame)
    end

    -- A block handler for Function name, executes the sent function with passed parameters.
    -- Functions can not be sent or executed on server side.
    function AIO.HANDLERS.Function(player, Func, ...)
        if type(Func) ~= "function" then
            error(Func ~= nil, "#2 valid function or global table key expected", 1)
            error(_G[Func] ~= nil, "#2 valid function or global table key expected", 1)
            Func = _G[Func]
        end
        Func(...)
    end

    -- A block handler for Init name, checks the version number and errors if needed
    -- On wrong version prevents handling any more messages
    function AIO.HANDLERS.Init(player, version)
        AIO.INITED = true
        if(AIO.Version ~= version) then
            print("You have AIO version "..AIO.Version.." and the server uses "..(version or "nil")..". Get the same version")
            -- stop handling any incoming messages
            AIO.HandleBlock = function() end
        else
            print("Initialized AIO version "..AIO.Version..". Type '/aio help' for commands")
        end
    end

    -- A client side event handler
    -- Passes the incoming message to AIO message handler if it is valid
    local function ONADDONMSG(self, event, prefix, msg, Type, sender)
        if prefix == AIO.ServerPrefix then
            if event == "CHAT_MSG_ADDON" and sender == UnitName("player") then
                -- Normal AIO message handling from addon messages
                AIO.HandleIncomingMsg(msg, sender)
            end
        end
    end
    local MsgReceiver = CreateFrame("Frame")
    MsgReceiver:RegisterEvent("CHAT_MSG_ADDON")
    MsgReceiver:SetScript("OnEvent", ONADDONMSG)

    -- A block handler for Addon name.
    -- Stores new and changed addons to cache and runs the addon from cache
    -- Also removes removed and outdated addons
    -- On wrong version prevents handling any more messages
    function AIO.HANDLERS.Addon(player, name, crc, code)
        if type(name) ~= 'string' then
            return
        end
        AIO.debug("Incoming addon (name, crc, hascode): "..name, crc, not not code)
        if crc and code then
            AIO_sv_Addons[name] = {crc=crc, code=code}
        else
            if not crc or not AIO_sv_Addons[name] then
                AIO_sv_Addons[name] = nil
                return
            end
        end
        assert(AIO.loadstring(AIO_sv_Addons[name].code, name))()
    end
    
    -- Forces reload of UI for user on next action
    function AIO.HANDLERS.ForceReload(player)
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
end

-- Adds all handlers from AIO.HANDLERS for the "AIO" msg handler
AIO.AddHandlers("AIO", AIO.HANDLERS)

return AIO
