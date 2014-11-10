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

local AIO = require("AIO")

local type = type

-- Check if loaded
-- Try to avoid multiple loads with require etc
if (AIO.Mod_BlockHandle) then
    return AIO.Mod_BlockHandle
end
AIO.Mod_BlockHandle = true

-- Table that contains block handler functions
-- You can create your own custom things to do with this
-- Example: BlockHandle["Test"] = function(...) print("Test", ...) end
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
            BlockHandle[HandleName](Player, DiscardFirst(AIO.unpack(block, 1, AIO.maxn(block))))
        else
            error("Unknown blockhandle "..HandleName)
        end
    -- end
end

-- This handles OnClick events that are registered to execute server side code
function BlockHandle.ServerEvent(Player, Event, EventParamsTable, ClientFuncRet)
    if(type(Player) ~= "userdata" or type(Event) ~= "string" or type(EventParamsTable) ~= "table" or type(ClientFuncRet) ~= "table") then
        return
    end
    local Frame = AIO:GetObject(EventParamsTable[1])
    if(not Frame) then
        return
    end
    local Script = Frame:GetScript(Event)
    if(not Script) then
        return
    end
    Script(Player, Event, EventParamsTable, ClientFuncRet)
end

-- This restricts player's ability to request the initial UI to some set time
local timers = {}
local function RemoveInitTimer(eventid, playerguid)
    if(type(playerguid) == "number") then
        timers[playerguid] = nil
    end
end
-- This handles sending initial UI to player and calling the on UI init hooks
local InitMsg;
function BlockHandle.Init(Player)
    if(type(Player) ~= "userdata" or type(Player.GetObjectType) ~= "function" or Player:GetObjectType() ~= "Player") then
        return
    end
    local guid = Player:GetGUIDLow()
    if (timers[guid]) then
        return
    end
    timers[guid] = CreateLuaEvent(function(e) RemoveInitTimer(e, guid) end, 4000, 1) -- the timer here (4000) is the min time in ms between inits the player can do
    if (not InitMsg) then
        AIO.INITED = true
        AIO.INIT_MSG = AIO.INIT_MSG or AIO:CreateMsg()
        AIO.INIT_MSG:AddBlock("Init", AIO.Version)
        InitMsg = AIO.INIT_MSG
    end
    local send = true
    for k, v in ipairs(AIO.PRE_INIT_FUNCS) do
        if (v(Player) == false) then
            send = false
        end
    end
    if (send) then
        InitMsg:Send(Player)
        for k, v in ipairs(AIO.POST_INIT_FUNCS) do
            v(Player)
        end
    end
end
