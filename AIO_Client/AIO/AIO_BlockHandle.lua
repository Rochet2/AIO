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
local _G = _G

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
        if(BlockHandle[HandleName]) then
            -- Using of maxn is important instead of # operator since the table contains holes (nil mixed in) and # will then possibly return invalid length
            BlockHandle[HandleName](Player, DiscardFirst(AIO.unpack(block, 1, AIO.maxn(block))))
        else
            error("Unknown blockhandle "..HandleName)
        end
    -- end
end

function BlockHandle.Frame(Player, Type, Name, Parent, Template)
    -- if frame already exists with the name, return
    if (_G[Name]) then
        return
    end
    local Frame = CreateFrame(Type, Name, Parent or UIParent, Template)
end

function BlockHandle.Function(Player, Func, ...)
    if(type(Func) == "string") then
        Func = _G[Func]
    end
    Func(...)
end

function BlockHandle.Init(Player, version)
    if(AIO.Version ~= version) then
        print("You have AIO version "..AIO.Version.." and server uses "..version..". Get the same version")
    end
    AIO.INITED = true
end

-- Table that contains method handler functions for custom frame methods
-- You can create your own custom methods for frames with this
-- Example: MethodHandle["Test"] = function(self, ...) print(self, ...) end
-- Above example will print self (Frame table) along with all passed arguments when server sends a message that uses Test method for a frame
local MethodHandle = {}

function BlockHandle.Method(Player, Frame, FuncName, ...)
    local name
    if (type(Frame) == "string") then
        name = Frame
        Frame = _G[Frame]
    end
    assert(Frame, "Trying to call method ("..FuncName..") on a nonexistant frame "..(name or "nil"))
    if(MethodHandle[FuncName]) then
        MethodHandle[FuncName](Frame, ...)
    elseif(Frame[FuncName]) then
        Frame[FuncName](Frame, ...)
    else
        error("Nonexisting Frame method ("..FuncName..") for type ("..Frame:GetObjectType()..")")
    end
end

function MethodHandle.SetVar(Frame, key, value)
    Frame[key] = value
end

function MethodHandle.SetScript(Frame, handle, func)
    if(type(func) == "string") then
        -- Function was a frame method name
        Frame:SetScript(handle, Frame[func])
    else
        -- Normal function
        Frame:SetScript(handle, func)
    end
end
function MethodHandle.HookScript(Frame, handle, func)
    if(type(func) == "string") then
        -- Function was a frame method name
        Frame:HookScript(handle, Frame[func])
    else
        -- Normal function
        Frame:HookScript(handle, func)
    end
end
