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

--[[
CLIENT FILE
This file handles the saved variables and character specific saved variables
At the bottom there is also code for all slash commands
]]

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
                AIO.debug("Overwriting global var _G["..k.."] with a saved var")
            end
            _G[k] = v
        end
        for k,v in pairs(AIO_sv_char) do
            if _G[k] then
                AIO.debug("Overwriting global var _G["..k.."] with a saved character var")
            end
            _G[k] = v
        end

        -- Request initialization of UI if not done yet
        -- works by timer for every second. Timer shut down after inited.
        -- initmsg consists of the version and all known crc codes for cached addons.
        local initmsg = AIO.Msg():Add("Init", AIO.Version)
        local rem = {}
        for name, data in pairs(AIO_sv_Addons) do
            if type(name) ~= 'string' or type(data) ~= 'table' or type(data.crc) ~= 'number' or type(data.code) ~= 'string' then
                table.insert(rem, name)
            else
                initmsg:AddVal(name)
                initmsg:AddVal(data.crc)
            end
        end
        for _,name in ipairs(rem) do
            AIO_sv_Addons[name] = nil -- remove invalid addons
        end

        local reset = 1
        local timer = reset
        local function ONUPDATE(self, diff)
            if(AIO.INITED) then
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
        for _,key in ipairs(AIO.SAVEDVARS) do
            AIO_sv[key] = _G[key]
        end
        AIO_sv_char = {} -- discard vars that no longer exist
        for _,key in ipairs(AIO.SAVEDVARSCHAR) do
            AIO_sv_char[key] = _G[key]
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
    AIO_sv = nil
    AIO_sv_char = nil
    AIO_sv_Addons = nil
    ReloadUI()
end
