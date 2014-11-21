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
    -- Server and Client side table of functions to reference by name to make msgs shorter
    METHOD_NAME_TABLE = {},
    -- Server and Client side table of functions to reference by index to make msgs shorter
    METHOD_INDEX_TABLE = {},
}

AIO.SERVER = type(GetLuaEngine) == "function"
AIO.Version = 0.58
-- Used for client-server messaging
AIO.Prefix  = "AIO"
-- ID characters for client-server messaging
-- Dont use hex here (abcdef or numbers)
AIO.Ignore          = 'g'
AIO.ShortMsg        = 'h'
AIO.LongMsg         = 'i'
AIO.LongMsgStart    = 'j'
AIO.LongMsgEnd      = 'k'
AIO.StartBlock      = 'l'
AIO.StartData       = 'm'
AIO.True            = 'n'
AIO.False           = 'o'
AIO.Nil             = 'p'
AIO.Frame           = 'q'
AIO.Table           = 'r'
AIO.Function        = 's'
AIO.String          = 't'
AIO.Number          = 'u'
AIO.Global          = 'v'
AIO.TableSep        = '_'
AIO.Prefix = AIO.Prefix:sub(1, 16) -- shorten prefix to max allowed if needed
AIO.ServerPrefix = ("S"..AIO.Prefix):sub(1, 16)
AIO.ClientPrefix = ("C"..AIO.Prefix):sub(1, 16)
AIO.MsgLen = 255 -1 -math.max(AIO.ServerPrefix:len(), AIO.ClientPrefix:len()) -AIO.ShortMsg:len() -- remove \t, prefix, msg type indentifier
AIO.LongMsgLen = 255 -1 -math.max(AIO.ServerPrefix:len(), AIO.ClientPrefix:len()) -AIO.LongMsg:len() -- remove \t, prefix, msg type indentifier

AIO.MAX_PACKET_COUNT    = 100
AIO.MSG_REMOVE_DELAY    = 30*1000 -- ms
AIO.UI_INIT_DELAY       = 4*1000 -- ms

-- premature optimization ftw
local type = type
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local AIO = AIO

-- Some lua compatibility
AIO.loadstring = loadstring or load -- loadstring name varies with lua 5.1 and 5.2
AIO.unpack = table.unpack or unpack -- unpack place varies with lua 5.1 and 5.2
AIO.maxn = table.maxn or function(t) local n = 0 for k, _ in pairs(t) do if(type(k) == "number" and k > n) then n = k end end return n end -- table.maxn was removed in lua 5.2
function AIO.assert(cond, msg, level)
    if (not cond) then
        error(msg or "AIO assertion failed", (level or 1)+1)
    end
end

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
local function val_to_str ( v )
    local v = AIO:ToMsgVal(v)
    return v:len()..v
end
function table.tostring( tbl )
    AIO.assert(type(tbl) == "table", "#1 table expected", 2)
    local result = {}
    for k, v in pairs( tbl ) do
        table.insert( result, val_to_str( k ) )
        table.insert( result, val_to_str( v ) )
    end
    return AIO.TableSep..table.concat( result, AIO.TableSep )
end

local function get_tbl_val(str)
    if (type(str) ~= "string") then
        return nil
    end
    local len, data = str:match("^"..AIO.TableSep.."(%d+)(.*)$")
    if (not len or not data) then
        return nil
    end
    return data:sub(1, tonumber(len)), data:sub(len+1)
end
function table.fromstring( str )
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    
    local t, save, _k = {}, false, nil
    local a, b = get_tbl_val(str)
    while (a and b) do
        if (save) then
            t[_k] = a
        else
            _k = a
        end
        save = not save
        a, b = get_tbl_val(b)
    end
    
    local res = {}
    for k,v in pairs(t) do
        local _k, _v = AIO:ToRealVal(k), AIO:ToRealVal(v)
        if (_k ~= nil) then
            res[_k] = _v
        end
    end
    
    return res
end

-- This gets a numberic representation if it exists, otherwise returns passed value
function AIO:GetFuncId(funcname)
    if (not funcname) then return funcname end
    return AIO.METHOD_NAME_TABLE[funcname] or funcname
end

-- This gets a string representation if it exists, otherwise returns passed value
function AIO:GetFuncName(index)
    if (not index) then return index end
    return AIO.METHOD_INDEX_TABLE[index] or index
end

-- Returns true if var is an AIO function table object
function AIO:IsFunction(var)
    if(type(var) ~= "table") then
        return false
    end
    if(type(var.F) ~= "string" or not var.AIOF) then
        return false
    end
    return true
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

-- Converts a string to bytehexstring
function AIO:ToByte(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (string.format((("%02x"):rep(str:len())), string.byte(str, 1, str:len())))
end
-- Converts a bytehexstring to string
local function hextochar(hexstr) return (string.char((tonumber(hexstr, 16)))) end
function AIO:FromByte(str)
    AIO.assert(type(str) == "string", "#1 string expected", 2)
    return (string.gsub(str, "%x%x", hextochar))
end

-- Converts a string to a function parameter
-- Note that all parameters passed to function will be accessible with ...
-- If RetRealFunc is true, when the string is executed, it returns the function to actually use as function
function AIO:ToFunction(FuncAsString, RetRealFunc)
    AIO.assert(type(FuncAsString) == "string", "#1 string expected", 2)
    return {F = FuncAsString, R = RetRealFunc, AIOF = true}
end
-- Converts frame or frame name to frame object parameter
function AIO:ToFrame(FrameOrFrameName)
    AIO.assert(type(FrameOrFrameName) == "string" or AIO:IsFrame(FrameOrFrameName), "#1 string or frame expected", 2)
    if (type(FrameOrFrameName) == "table") then
        FrameOrFrameName = FrameOrFrameName:GetName()
    end
    return AIO.Frame..AIO:ToByte(FrameOrFrameName)
end
-- Converts table to parameter
function AIO:ToTable(tbl)
    AIO.assert(type(tbl) == "table", "#1 table expected", 2)
    return AIO.Table..table.tostring(tbl)
end
-- Returns string parameter
function AIO:ToString(val)
    AIO.assert(type(val) == "string", "#1 string expected", 2)
    return AIO.String..AIO:ToByte(val)
end
-- Returns number parameter
function AIO:ToNumber(val)
    val = tonumber(val)
    AIO.assert(val, "#1 number expected", 2)
    return AIO.Number..AIO:ToByte(tostring(val))
end
-- Converts boolean to parameter
function AIO:ToBoolean(bool)
    if (bool) then
        return AIO.True
    else
        return AIO.False
    end
end
-- Returns nil parameter
function AIO:ToNil()
    return AIO.Nil
end
-- Returns global variable parameter
function AIO:ToGlobal(ObjectOrVarName)
    AIO.assert(type(ObjectOrVarName) == "string" or AIO:IsObject(ObjectOrVarName), "#1 object or string expected", 2)
    if (type(ObjectOrVarName) == "table") then
        ObjectOrVarName = ObjectOrVarName:GetName()
    end
    return AIO.Global..AIO:ToByte(ObjectOrVarName)
end

-- Converts a value to string using special characters to represent the value if needed
function AIO:ToMsgVal(val)
    local Type = type(val)
    if (Type == "string") then
        -- if(val:match("^"..AIO.String.."%x*$") == 1) then error("Reconverting string to string:"..val, 1) end
        return AIO:ToString(val)
    elseif (Type == "number") then
        return AIO:ToNumber(val)
    elseif (Type == "boolean") then
        return AIO:ToBoolean(val)
    elseif (Type == "nil") then
        return AIO:ToNil()
    elseif (Type == "function") then
        AIO.assert(false, "#1 Cant pass function, use AIO:ToFunction(FuncAsString) to pass a function parameter", 2)
    elseif (Type == "table") then
        if (AIO:IsFrame(val)) then
            return AIO:ToFrame(val:GetName())
        end
        if (AIO:IsObject(val)) then
            return AIO:ToGlobal(val:GetName())
        end
        if (AIO:IsFunction(val)) then
            return AIO.Function..table.tostring(val)
        end
        return AIO:ToTable(val)
    else
        AIO.assert(false, "#1 Invalid value type ".. Type, 2)
    end
end

-- Converts a string value from a message to the actual value it represents
function AIO:ToRealVal(val)
    AIO.assert(type(val) == "string", "#1 string expected", 2)
    
    local Type, data = val:match("(.)(.*)")
    data = AIO:FromByte(data)
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
    elseif (Type == AIO.Function) then
        if (AIO.SERVER) then
            return nil -- ignore on server side, unsafe
        end
        -- Note that we dont use data here since table itself is not bytecode, only its contents
        -- we also need to take the type tag off from the val
        local tbl = table.fromstring(val:sub(Type:len()+1))
        if (not AIO:IsFunction(tbl)) then
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
        -- Note that we dont use data here since table itself is not bytecode, only its contents
        -- we also need to take the type tag off from the val
        return table.fromstring(val:sub(Type:len()+1))
    elseif(Type == AIO.Global) then
        if (AIO.SERVER) then
            return nil -- ignore on server side, unsafe
        end
        return _G[data]
    elseif(Type == AIO.Frame) then
        if(AIO.SERVER) then
            return data
        else
            return _G[data]
        end
    end
    
    return nil -- val
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
        AIO.assert(Name, "#1 Block must have name", 2)
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
            AIO.assert(false, "#1 Cant append "..tostring(msg2), 2)
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
    AIO.assert(type(msg) == "string", "#1 string expected", 2)
    
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
local Timers = {}
local Packets = {}
local LongMessages = {}
local function RemoveMsg(eventid, delay, repeats, player)
    local guid = player:GetGUIDLow()
    LongMessages[guid] = nil
    Packets[guid] = nil
    Timers[guid] = nil
end
function AIO:HandleIncomingMsg(msg, player)
    -- Received a long message part (msg split into 255 character parts)
    if (msg:find(AIO.LongMsg)) == 1 then
        local guid = AIO.SERVER and player:GetGUIDLow() or 1
        if (msg:find(AIO.LongMsgStart)) == AIO.LongMsg:len() + 1 then
            -- The first message of a long message received. Erase any previous message (reload can mess etc)
            Packets[guid] = 1
            LongMessages[guid] = msg:sub(3)
            if (AIO.SERVER) then
                if (Timers[guid]) then
                    player:RemoveEventById(Timers[guid])
                end
                Timers[guid] = player:RegisterEvent(RemoveMsg, AIO.MSG_REMOVE_DELAY, 1)
            else
                Timers[guid] = true
            end
        elseif (msg:find(AIO.LongMsgEnd)) == AIO.LongMsg:len() + 1 then
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
            AIO:ParseBlocks(LongMessages[guid]..msg:sub(AIO.LongMsg:len() + AIO.LongMsgEnd:len() + 1), player)
            if (AIO.SERVER and Timers[guid]) then
                player:RemoveEventById(Timers[guid])
            end
            LongMessages[guid] = nil
            Packets[guid] = nil
            Timers[guid] = nil
        else
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
    elseif (msg:find(AIO.ShortMsg) == 1) then
        -- Received <= 255 char msg, direct parse, take out the msg tag first
        AIO:ParseBlocks(msg:sub(AIO.ShortMsg:len() + 1), player)
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
        local guid = player:GetGUIDLow()
        LongMessages[guid] = nil
        Packets[guid] = nil
        Timers[guid] = nil
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
