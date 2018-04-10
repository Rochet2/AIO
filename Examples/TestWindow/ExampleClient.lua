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
This file is a client file and it handles all client side code. It is added on server
side to a list of files to send to the client when the client reloads UI or logs in.
This means that the file is run on server side and then on client side.
This file should be placed somewhere in the lua_scripts folder so Eluna can load it.
You can of course design your own addons and codes in some other way.

Few tips:
Size matters. The final compressed and obfuscated code will be sent to the client and
if it is very large, it will take more messages and more work to send.
Obfuscation will be done on startup so it will not slow down the sending process.
AIO has a cache system that avoids unnecessary resending of unchanged addons
between relogging. You can reset all client side saved information with /aio reset
Type /aio help to see all other commands.

Message compression and obfuscation should be turned on in AIO.lua files on server
and client. If you want to debug your code and need to see the correct line numbers
on error messages, disable obfuscation.
Use locals! local variables will be shortened by obfuscation, so you should prefer
local variables over global and you should try make functions, methods and variables local.
Make functions out of repetitive code to make the code smaller.
Obfuscation removes comments so you can have as much comments as you want in your code
to keep it clear.

After getting some base understanding of how things work, it is suggested to read all the AIO files.
They contain a lot of new functions and information and everything has comments about what it does.
]]


-- Note that getting AIO is done like this since AIO is defined on client
-- side by default when running addons and on server side it may need to be
-- required depending on the load order.
local AIO = AIO or require("AIO")

-- This will add this file to the server side list of addons to send to players.
-- The function is coded to get the path and file name automatically,
-- but you can also provide them yourself. AIO.AddAddon will return true if the
-- addon was added to the list of loaded addons, this means that if the
-- function returns true the file is being executed on server side and we
-- return since this is a client file. On client side the file will be executed
-- entirely.
if AIO.AddAddon() then
    return
end

-- AIO.AddHandlers adds a new table of functions as handlers for a name and returns the table.
-- This is used to add functions for a specific "channel name" that trigger on specific messages.
-- At this point the table is empty, but MyHandlers table will be filled soon.
local MyHandlers = AIO.AddHandlers("AIOExample", {})
-- You can also call this after filling the table. like so:
--  local MyHandlers = {}; ..fill MyHandlers table.. AIO.AddHandlers("AIOExample", MyHandlers)

-- Lets create some UI frames for the client.
-- Note that this code is executed on addon side - you can use any addon API function etc.

-- Create the base frame.
FrameTest = CreateFrame("Frame", "FrameTest", UIParent, "UIPanelDialogTemplate")
local frame = FrameTest

-- Some basic method usage..
-- Read the wow addon widget API for what each function does:
-- http://wowwiki.wikia.com/Widget_API
frame:SetSize(200, 200)
frame:RegisterForDrag("LeftButton")
frame:SetPoint("CENTER")
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
-- Enable dragging of frame
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnHide", frame.StopMovingOrSizing)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- This enables saving of the position of the frame over reload of the UI or restarting game
AIO.SavePosition(frame)

-- A handler triggered by using AIO.Handle(player, "AIOExample", "ShowFrame")
-- on server side.
function MyHandlers.ShowFrame(player)
    frame:Show()
end

-- Creating an input:
local input = CreateFrame("EditBox", "InputTest", frame, "InputBoxTemplate")
input:SetSize(100, 30)
input:SetAutoFocus(false)
input:SetPoint("CENTER", frame, "CENTER", 0, 50)
input:SetScript("OnEnterPressed", input.ClearFocus)
input:SetScript("OnEscapePressed", input.ClearFocus)

-- Creating a slider:
local slider = CreateFrame("Slider", "SlideTest", frame, "OptionsSliderTemplate")
slider:SetSize(100, 17)
slider:SetPoint("CENTER", frame, "CENTER", 0, -50)
slider:SetValueStep(0.5)
slider:SetMinMaxValues(0, 100)
slider:SetValue(50)
slider.tooltipText = 'This is the Tooltip hint'
_G[slider:GetName() .."Text"]:SetText(50)
slider:SetScript("OnValueChanged", function(self) _G[slider:GetName() .."Text"]:SetText(self:GetValue()) end)
_G[slider:GetName().."High"]:Hide()
_G[slider:GetName().."Low"]:Hide()
slider:Show()

-- Creating a child, a button:
local button = CreateFrame("Button", "ButtonTest", frame)
button:SetSize(100, 30)
button:SetPoint("CENTER", frame, "CENTER")
button:EnableMouse(true)
-- Small script to clear the focus from input on click
button:SetScript("OnMouseUp", function() input:ClearFocus() end)
-- Usually I use UIPanelButtonTemplate for buttons, but I wanted to show and test some custom color texture here:
local texture = button:CreateTexture("TextureTest")
texture:SetAllPoints(button)
texture:SetTexture(0.5, 1, 1, 0.5)
button:SetNormalTexture(texture)
-- Set the font, could use GameFontNormal template, but I wanted to create my own
local fontstring = button:CreateFontString("FontTest")
fontstring:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
fontstring:SetShadowOffset(1, -1)
button:SetFontString(fontstring)
button:SetText("Test")

-- You can do a lot of things on client side events.
-- You can find all events for different frame types here: http://wowwiki.wikia.com/Widget_handlers
-- Here I send a message to the server that executes the print handler
-- See the ExampleServer.lua file for the server side print handler.
local function OnClickButton(btn)
    AIO.Handle("AIOExample", "Print", btn:GetName(), input:GetText(), slider:GetValue())
end
button:SetScript("OnClick", OnClickButton)
