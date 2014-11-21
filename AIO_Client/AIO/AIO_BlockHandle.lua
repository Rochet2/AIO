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

local AIO = AIO

local type = type

-- http://www.wowwiki.com/Widget_handlers
-- http://www.wowwiki.com/Widget_API

-- Table that contains block handler functions
-- You can create your own custom block commands with this
-- Example: BlockHandle["Test"] = function(Player, ...) print("Test", ...) end
-- Above example will print Test along with all passed arguments when server sends a message with block added with name Test
local BlockHandle = {}

-- Helper for HandleBlocks to discard handlename
-- Cant use table.remove since it removes nil values
local function DiscardFirst(_, ...)
    return ...
end

-- This will "overwrite" the AIO:HandleBlock function
-- AIO:HandleBlock is not defined in AIO.lua
-- Calls the handler for block
function AIO:HandleBlock(block, Player)
    -- for k, block in ipairs(Blocks) do
        local HandleName = block[1]
        AIO.assert(BlockHandle[HandleName], "Valid blockhandle name expected, got ("..HandleName..")", 1)
        -- Using of maxn is important instead of # operator since the table contains holes (nil mixed in) and # will then possibly return invalid length
        BlockHandle[HandleName](Player, DiscardFirst(AIO.unpack(block, 1, AIO.maxn(block))))
    -- end
end

function BlockHandle.Frame(Player, Type, Name, Parent, Template)
    AIO.assert(type(Name) == "string", "#3 string expected", 1)
    -- if frame already exists with the name, return
    if (_G[Name]) then
        return
    end
    local Frame = CreateFrame(Type, Name, Parent or UIParent, Template)
end

function BlockHandle.Function(Player, Func, ...)
    if(type(Func) ~= "function") then
        AIO.assert(Func ~= nil, "#2 valid table key expected", 1)
        AIO.assert(_G[Func] ~= nil, "#2 table key to valid function expected", 1)
        Func = _G[Func]
    end
    Func(...)
end

function BlockHandle.Init(Player, version)
    AIO.INITED = true
    if(AIO.Version ~= version) then
        print("You have AIO version "..AIO.Version.." and the server uses "..(version or "nil")..". Get the same version")
    end
end

-- Table that contains method handler functions for custom frame methods
-- You can create your own custom methods for frames with this
-- Example: MethodHandle["Test"] = function(self, ...) print(self, ...) end
-- Above example will print self (Frame table) along with all passed arguments when server sends a message that uses Test method for a frame
local MethodHandle = {}

function BlockHandle.Method(Player, Frame, FuncName, ...)
    FuncName = AIO:GetFuncName(FuncName)
    local name
    if (type(Frame) == "string") then
        name = Frame
        Frame = _G[Frame]
    end
    AIO.assert(Frame, "#2 Frame name or frame object expected. Calling method ("..FuncName..") on a nonexistant frame "..(name or "nil"), 2)
    if(MethodHandle[FuncName]) then
        MethodHandle[FuncName](Frame, ...)
    elseif(Frame[FuncName]) then
        Frame[FuncName](Frame, ...)
    else
        AIO.assert(false, "#3 valid function name expected, got ("..FuncName..") for type ("..Frame:GetObjectType()..")", 1)
    end
end

function MethodHandle.SetVar(Frame, key, value)
    AIO.assert(type(Frame) == "table", "#1 table expected", 1)
    AIO.assert(key ~= nil, "#2 valid table key expected", 1)
    Frame[key] = value
end

function MethodHandle.SetScript(Frame, handle, func)
    AIO.assert(type(Frame) == "table", "#1 table expected", 1)
    AIO.assert(type(handle) == "string", "#2 string expected", 1)
    if(type(func) == "string") then
        -- Function was a frame method name
        AIO.assert(Frame[func], "#3 valid Frame function name expected", 1)
        Frame:SetScript(handle, Frame[func])
    elseif(type(func) == "function") then
        -- Normal function
        Frame:SetScript(handle, func)
    elseif(func == nil) then
        Frame:SetScript(handle, nil)
    else
        AIO.assert(false, "#3 valid function or Frame function name expected", 1)
    end
end
function MethodHandle.HookScript(Frame, handle, func)
    AIO.assert(type(Frame) == "table", "#1 table expected", 1)
    AIO.assert(type(handle) == "string", "#2 string expected", 1)
    if(type(func) == "string") then
        -- Function was a frame method name
        AIO.assert(Frame[func], "#3 valid Frame function name expected", 1)
        Frame:HookScript(handle, Frame[func])
    elseif(type(func) == "function") then
        -- Normal function
        Frame:HookScript(handle, func)
    elseif(func == nil) then
        Frame:HookScript(handle, nil)
    else
        AIO.assert(false, "#3 valid function or Frame function name expected", 1)
    end
end
