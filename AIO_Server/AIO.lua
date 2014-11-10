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

Messaging is handled by objects you can create with AIO:CreateMsg()
The message will have functions:
msg:AddBlock(Name, ...) -- FuncName, arguments
msg:Send(...) -- Receiver players, will not be used for client->server messages
msg:Append(MSG) -- Appends another message to the message
msg:Clear() -- Deletes the message from the message
msg:ToString() -- Returns the message (always msg var or "")
msg:HasMsg() -- returns true or false depending on msg being string or not
You can code handlers to the receiver end and trigger them with AddBlock
Example of handler on receiver side:
function BlockHandle.Print(value)
    Print(value)
end
Example of how to trigger handler from sender side:
local msg = AIO:CreateMsg() -- new message
msg:AddBlock("Print", "Test") -- new block that triggers Print handler with parameter "test"
msg:Send(player) -- send message to player
See AIO_BlockHandle.lua for more

AIO:HandleBlocks(T, player) is not defined in this file
It is responsible for taking action for all received blocks
See AIO_BlockHandle.lua for definition

There are many useful functions aiding the messaging here
The To functions and ToMsgVal will convert the given value to a string representative of the given value
ToRealVal will reverse this and convert the given string to a real value it should be
Most of these will be used automatically when you use AddBlock. ToFunction is an exception
-- Converts a value to string using special characters to represent the value if needed
function AIO:ToMsgVal(val)
-- Converts a string value from a message to the actual value it represents
function AIO:ToRealVal(val)
-- Converts a string to a function parameter
-- Note that all parameters passed to function will be accessible with ...
-- If RetRealFunc is true, when the string is executed, it returns the function to actually use as function
function AIO:ToFunction(FuncAsString, RetRealFunc)
-- Converts frame name to frame object parameter
function AIO:ToFrame(FrameName)
-- Converts table to parameter
function AIO:ToTable(tbl)
-- Converts boolean to parameter
function AIO:ToBoolean(bool)
-- Returns nil parameter
function AIO:ToNil()
-- Converts a table to string
function table.tostring( tbl )
-- Converts a string created with table.tostring(tbl) back to table. Will convert Msg values to their real values
function table.fromstring( str )

When sending a function, you will NEED to use AIO:ToFunction(FuncAsString, RetRealFunc)
You will be able to access passed variables with vararg ...
Example:
local func = AIO:ToFunction("print(...)")
local msg = AIO:CreateMsg() -- new message
msg:AddBlock("Function", func, "Test", 1) -- Add a block to call Function handler
msg:Send(player) -- Prints Test 1 on receiver end

Examples for RetRealFunc:
local func = AIO:ToFunction("return print", true)
msg:AddBlock("Function", func, "Test", 1)
msg:Send(player) -- Prints Test 1 on receiver end

local code = [[
local function MyFunc(var1, var2)
    print(var1 == var2)
end
return MyFunc
]]
local func = AIO:ToFunction(code, true)
msg:AddBlock("Function", func, "a", "b")
msg:Send(player) -- Prints false on receiver end

Sometimes you may want to access a certain frame on the receiver end.
You can access the frame by it's name with AIO:ToFrame(framename)
When this is converted to the real value with AIO:ToRealVal(val), it will on client side be the frame object if found from global table _G
If you need to access something in a function string, just use the normal _G["FrameName"]
]===]

-- Check if loaded
-- Try to avoid multiple loads with require etc
if (type(AIO) == "table") then
    return AIO
end

-- Was not loaded yet, create table
AIO =
{
    -- Stores frames etc by name
    Objects = {},
    -- Stores long messages for players
    LongMessages = {},
    -- Counter for nameless objects (used for naming serverside)
    NamelessCount = 0,
    -- Server side var of messages (string) to send on initing player UI
    INIT_MSG = nil,
    -- Server side table of functions to call before initing player UI
    PRE_INIT_FUNCS = {},
    -- Server side table of functions to call after initing player UI
    POST_INIT_FUNCS = {},
    -- Client side flag for noting if the client has been inited or not
    -- Server side flag for noting when server load operations have been done and they should no longer be done
    INITED = false,
}

AIO.SERVER = type(GetLuaEngine) == "function"
AIO.Version = 0.41
-- Used for client-server messaging
AIO.Prefix  = "AIO"
-- ID characters for client-server messaging
AIO.Ignore          = 'a'
AIO.ShortMsg        = 'b'
AIO.LongMsg         = 'c'
AIO.LongMsgStart    = 'p'
AIO.LongMsgEnd      = 'd'
AIO.StartBlock      = 'e'
AIO.StartData       = 'f'
AIO.True            = 'g'
AIO.False           = 'h'
AIO.Nil             = 'i'
AIO.Frame           = 'j'
AIO.Table           = 'k'
AIO.Function        = 'l'
AIO.String          = 'm'
AIO.Number          = 'n'
AIO.Global          = 'o'
AIO.Identifier      = '&'
AIO.Prefix = AIO.Prefix:sub(1, 16) -- shorten prefix to max allowed if needed
AIO.ServerPrefix = ("S"..AIO.Prefix):sub(1, 16)
AIO.ClientPrefix = ("C"..AIO.Prefix):sub(1, 16)
AIO.MsgLen = 255 -1 -math.max(AIO.ServerPrefix:len(), AIO.ClientPrefix:len()) -AIO.ShortMsg:len() -- remove \t, prefix, msg type indentifier
AIO.LongMsgLen = 255 -1 -math.max(AIO.ServerPrefix:len(), AIO.ClientPrefix:len()) -AIO.LongMsg:len() -- remove \t, prefix, msg type indentifier

-- premature optimization ftw
local type = type
local assert = assert
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local _G = _G
local AIO = AIO

-- Some lua compatibility
AIO.loadstring = loadstring or load -- loadstring name varies with lua 5.1 and 5.2
AIO.unpack = table.unpack or unpack -- unpack place varies with lua 5.1 and 5.2
AIO.maxn = table.maxn or function(t) local n = 0 for k, _ in pairs(t) do if(type(k) == "number" and k > n) then n = k end end return n end -- table.maxn was removed in lua 5.2

-- Merges t2 to t1 (tables)
function AIO:TableMerge(t1, t2)
    for k,v in pairs(t2) do
        if (type(v) == "table") then
            if(type(t1[k]) ~= "table") then
                t1[k] = {}
            end
            AIO:TableMerge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

-- Functions for handling converting table to string and from string
-- table.tostring(t), table.fromstring(s)
-- http://lua-users.org/wiki/TableUtils
-- Heavily modified ..
local function val_to_str ( v )
    local v = AIO:ToMsgVal(v)
    if(v:find(AIO.Identifier..AIO.Table) == 1) then
        return v:sub(3)
    end
    return '"'..v..'"'
end
function table.tostring( tbl )
    assert(type(tbl) == "table")
    local result = {}
    for k, v in pairs( tbl ) do
        table.insert( result, "[" .. val_to_str( k ) .. "]" .. "=" .. val_to_str( v ) )
    end
    return "{" .. table.concat( result, "," ) .. "}"
end

local function table_to_real( t )
    local res = {}
    for k,v in pairs(t or {}) do
        local _k, _v
        if(type(k) == "table") then
            _k = table_to_real(k)
        else
            _k = AIO:ToRealVal(k)
        end
        if(type(v) == "table") then
            _v = table_to_real(v)
        else
            _v = AIO:ToRealVal(v)
        end
        if(type(_k) ~= nil) then
            res[_k] = _v
        end
    end
    return res
end

function table.fromstring( str )
    assert(type(str) == "string")
    -- Some security
    if (str:find("[^{},%[%]%a%d \"=]") or
        str:find("%a%a") or
        str:find('[^"]%a') or
        not str:find("{.*}")) then
        return nil
    end
    local func, err = AIO.loadstring("return "..str)
    assert(func, err)
    return table_to_real(func())
end

-- Returns true if var is an Object table
function AIO:IsObject(var)
    if(type(var) ~= "table") then
        return false
    end
    if (AIO.SERVER) then
        return var.IS_OBJECT
    end
    return var.IsObjectType
end

-- Returns true if var is a Frame table object
function AIO:IsFrame(var)
    if(type(var) ~= "table") then
        return false
    end
    if (AIO.SERVER) then
        return var.IS_FRAME
    end
    return var.IsObjectType and var:IsObjectType("Frame")
end

-- Returns an Object (frame) by its name
function AIO:GetObject(Name)
    if (type(Name) ~= "string") then
        return
    end
    return AIO.Objects[Name]
end

-- Converts a string to byte string
function AIO:ToByte(str)
    local byte = ""
    for i = 1, str:len() do
        byte = byte.." "..string.byte(str, i)
    end
    return byte
end
-- Converts byte string to string
function AIO:FromByte(str)
    local T = {}
    for num in str:gmatch(" (%d+)") do
        table.insert(T, num)
    end
    return string.char(AIO.unpack(T))
end

-- Converts a string to a function parameter
-- Note that all parameters passed to function will be accessible with ...
-- If RetRealFunc is true, when the string is executed, it returns the function to actually use as function
function AIO:ToFunction(FuncAsString, RetRealFunc)
    assert(type(FuncAsString) == "string")
    return AIO.Identifier..AIO.Function..(RetRealFunc and 1 or 0)..AIO:ToByte(FuncAsString)
end
-- Converts frame or frame name to frame object parameter
function AIO:ToFrame(FrameOrFrameName)
    assert(type(FrameOrFrameName) == "string" or AIO:IsFrame(FrameOrFrameName))
    if (type(FrameOrFrameName) == "table") then
        FrameOrFrameName = FrameOrFrameName:GetName()
    end
    return AIO.Identifier..AIO.Frame..AIO:ToByte(FrameOrFrameName)
end
-- Converts table to parameter
function AIO:ToTable(tbl)
    assert(type(tbl) == "table")
    return AIO.Identifier..AIO.Table..table.tostring(tbl)
end
-- Returns string parameter
function AIO:ToString(val)
    assert(type(val) == "string")
    return AIO.Identifier..AIO.String..AIO:ToByte(val)
end
-- Returns number parameter
function AIO:ToNumber(val)
    val = tonumber(val)
    assert(val)
    return AIO.Identifier..AIO.Number..AIO:ToByte(tostring(val))
end
-- Converts boolean to parameter
function AIO:ToBoolean(bool)
    if (bool) then
        return AIO.Identifier..AIO.True
    else
        return AIO.Identifier..AIO.False
    end
end
-- Returns nil parameter
function AIO:ToNil()
    return AIO.Identifier..AIO.Nil
end
-- Returns global variable parameter
function AIO:ToGlobal(ObjectOrVarName)
    assert(type(ObjectOrVarName) == "string" or AIO:IsObject(ObjectOrVarName))
    if (type(ObjectOrVarName) == "table") then
        ObjectOrVarName = ObjectOrVarName:GetName()
    end
    return AIO.Identifier..AIO.Global..AIO:ToByte(ObjectOrVarName)
end

-- Converts a value to string using special characters to represent the value if needed
function AIO:ToMsgVal(val)
    local Type = type(val)
    if (Type == "string") then
        if(val:find(AIO.Identifier) == 1) then
            return val
        else
            return AIO:ToString(val)
        end
    elseif (Type == "number") then
        return AIO:ToNumber(val)
    elseif (Type == "boolean") then
        return AIO:ToBoolean(val)
    elseif (Type == "nil") then
        return AIO:ToNil()
    elseif (Type == "function") then
        error("Cant pass function, use AIO:ToFunction(FuncAsString) to pass a function parameter")
    elseif (Type == "table") then
        if (AIO:IsFrame(val)) then
            return AIO:ToFrame(val:GetName())
        end
        if (AIO:IsObject(val)) then
            return AIO:ToGlobal(val:GetName())
        end
        return AIO:ToTable(val)
    else
        error("Invalid value type ".. Type)
    end
end

-- Converts a string value from a message to the actual value it represents
function AIO:ToRealVal(val)
    if(val == AIO.True) then
        return true
    elseif(val == AIO.False) then
        return false
    elseif(val == AIO.Nil) then
        return nil
    elseif(type(val) == "string") then
        if (val:find(AIO.String) == 1) then
            return AIO:FromByte(val:sub(2))
        elseif (val:find(AIO.Number) == 1) then
            return tonumber(AIO:FromByte(val:sub(2)))
        elseif (val:find(AIO.Function) == 1) then
            if(AIO.SERVER) then
                return nil -- ignore on server side, unsafe
            end
            local code = AIO:FromByte(val:sub(3))
            local func, err = AIO.loadstring(code)
            assert(func, err)
            if (val:find("1") == 2) then
                -- RetRealFunc was true
                func = func()
            end
            return func
        elseif(val:find(AIO.Frame) == 1) then
            if(AIO.SERVER) then
                return AIO:FromByte(val:sub(2))
            else
                return _G[AIO:FromByte(val:sub(2))]
            end
        elseif(val:find(AIO.Table) == 1) then
            return table.fromstring(val:sub(2))
        elseif(val:find(AIO.Global) == 1) then
            return _G[AIO:FromByte(val:sub(2))]
        end
    end
    return val
end

-- Creates a new message that you can append stuff to and send to client or server
function AIO.CreateMsg()
    local msg = {}
    
    -- Appends given value to the message for last block
    function msg:AddVal(val)
        if(not self.MSG) then
            self.MSG = "";
        end
        self.MSG = self.MSG..AIO.StartData..AIO:ToMsgVal(val)
    end
    
    -- Add a new block to object.
    -- Tag Data Name Data Arguments
    function msg:AddBlock(Name, ...)
        assert(Name, "Block must have name")
        if(not self.MSG) then
            self.MSG = "";
        end
        self.MSG = self.MSG..AIO.StartBlock
        self:AddVal(Name)
        for i = 1, select('#',...) do
            self:AddVal(select(i, ...))
        end
    end
    
    -- Function to append messages together and objects to messages to create long messages and for static frame use
    -- Example msg:Append(Frame1); msg:Append(Frame2); msg:Send(...)
    function msg:Append(msg2, NoChilds)
        if(not msg2) then
            return
        end
        if(not self.MSG) then
            self.MSG = "";
        end
        if(type(msg2) == "string") then
            self.MSG = self.MSG..msg2
        elseif(type(msg2) == "table") then
            self:Append(msg2.MSG)
            if (not NoChilds and msg2.Children) then
                for k,v in ipairs(msg2.Children) do
                    self:Append(v)
                end
            end
        else
            error("Cant append "..tostring(msg2))
        end
    end

    -- varargs are receiver players if needed
    function msg:Send(...)
        AIO:Send(self.MSG, ...)
    end

    -- Same as msg:Send(...), but sends the data with Ignore tag,
    -- which for client means that the whole message is ignored if the given value is true (can be function, frame etc)
    function msg:SendIgnoreIf(Val, ...)
        AIO:Send(AIO.Ignore..AIO:ToMsgVal(Val)..self.MSG, ...)
    end
    
    function msg:Clear()
        self.MSG = nil
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
function AIO:SendAddonMessage(msg, player)
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
function AIO:SendToPlayers(msg, ...)
    for i = 1, select('#',...) do
        AIO:Send(msg, select(i, ...))
    end
end

-- Send msg. Can have one or more receivers (no receivers when sending from client -> server)
function AIO:Send(msg, player, ...)
    assert(msg, "Trying to send a nonexistant message")
    
    msg = msg:gsub(AIO.Identifier, "")
    
    -- More than one receiver, mass send message
    if(...) then
        AIO:SendToPlayers(msg, player, ...)
        return
    end
    
    -- split message to 255 character packets if needed (send long message)
    if (msg:len() <= AIO.MsgLen) then
        -- Send short <= 255 long msg
        AIO:SendAddonMessage(AIO.ShortMsg..msg, player)
    else
        msg = AIO.LongMsgStart..msg -- Add start tag
        
        -- Calculate amount of messages to send -1 since one message is the end message
        -- The msg length already contains the start tag, we add length of end tag
        local msgs = math.ceil((msg:len()+AIO.LongMsgEnd:len()) / AIO.LongMsgLen)-1
        for i = 1, msgs do
            AIO:SendAddonMessage(AIO.LongMsg..string.sub(msg, ((i-1)*AIO.LongMsgLen)+1, (i*AIO.LongMsgLen)), player)
        end
        AIO:SendAddonMessage(AIO.LongMsg..AIO.LongMsgEnd..string.sub(msg, ((msgs)*AIO.LongMsgLen)+1, ((msgs+1)*AIO.LongMsgLen)), player)
    end
end

-- Handles cleaning and assembling the messages received
-- Messages can be 255 characters long, so big messages will be split
function AIO:HandleIncomingMsg(msg, player)
    -- Received a long message part (msg split into 255 character parts)
    if (msg:find(AIO.LongMsg)) == 1 then
        local guid = AIO.SERVER and player:GetGUIDLow() or 1
        if (msg:find(AIO.LongMsgStart)) == 2 then
            -- The first message of a long message received. Erase any previous message (reload can mess etc)
            AIO.LongMessages[guid] = msg:sub(3)
        elseif (msg:find(AIO.LongMsgEnd)) == 2 then
            -- The last message of a long message received.
            if (not AIO.LongMessages[guid]) then
                -- Dont error when client sends bad data (end without start)
                if (AIO.SERVER) then
                    AIO.LongMessages[guid] = nil
                    return
                else
                    AIO.LongMessages[guid] = nil
                    error("Received long message end tag even if there has been no long message")
                    return
                end
            end
            AIO:ParseBlocks(AIO.LongMessages[guid]..msg:sub(3), player)
            AIO.LongMessages[guid] = nil
        else
            -- A part of a long message received.
            -- Ignore if a msg not even started
            if (not AIO.LongMessages[guid]) then
                return
            end
            AIO.LongMessages[guid] = AIO.LongMessages[guid]..msg:sub(2)
        end
    elseif (msg:find(AIO.ShortMsg) == 1) then
        -- Received <= 255 char msg, direct parse, take out the msg tag first
        AIO:ParseBlocks(msg:sub(2), player)
    end
end

-- Extracts blocks from msg to a table that has block data in a table
function AIO:ParseBlocks(msg, player)
    -- SendIgnore detect, if so, check that frame exists and return
    local _, ignoreEnd, ignoreFrame = msg:find("^"..AIO.Ignore.."([^"..AIO.StartBlock..AIO.StartData.."]+)")
    if(ignoreEnd) then
        local ignore = AIO:ToRealVal(ignoreFrame)
        if((type(ignore) == "function" and ignore(player, msg)) or ignore) then
            return
        end
        msg = msg:sub(ignoreEnd+1)
    end
    for block in msg:gmatch(AIO.StartBlock.."([^"..AIO.StartBlock.."]+)") do
        local t = {}
        -- table.insert is not used here since it ignores nil values
        local i = 1
        for data in block:gmatch(AIO.StartData.."([^"..AIO.StartData..AIO.StartBlock.."]+)") do
            t[i] = AIO:ToRealVal(data)
            i = i+1
        end
        -- This function is not defined in AIO.lua
        -- See AIO_BlockHandle.lua
        -- Passed values are a table containing AddBlock arguments in order and the sender player
        -- At this point all values of the block have been converted to real tables, functions, frames..
        AIO:HandleBlock(t, player)
    end
end

-- Addon message receiver setup
if(AIO.SERVER) then
    -- If serverscript
    local function ONADDONMSG(event, sender, Type, prefix, msg, target)
        if(prefix == AIO.ClientPrefix and tostring(sender) == tostring(target)) then
            AIO:HandleIncomingMsg(msg, sender)
        end
    end
    
    local function LOGOUT(event, player)
        -- Remove messages saved for player when he disconnects
        AIO.LongMessages[player:GetGUIDLow()] = nil
    end

    RegisterServerEvent(30, ONADDONMSG)
    RegisterPlayerEvent(4, LOGOUT)
else
    -- If addonscript
    
    -- message to request initialization of UI
    local initmsg = AIO:CreateMsg()
    initmsg:AddBlock("Init")
    
    local function ONADDONMSG(self, event, prefix, msg, Type, sender)
        if (prefix == AIO.ServerPrefix) then
            if(event == "CHAT_MSG_ADDON" and sender == UnitName("player")) then
                -- Normal AIO message handling from addon messages
                AIO:HandleIncomingMsg(msg, sender)
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
end

if (AIO.SERVER) then
    require("AIO_Objects")
    require("AIO_BlockHandle")
end
