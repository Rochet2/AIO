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

-- First create the frames and set up the codes for them..
-- Notice the similarity to Addon API
-- After getting base understanding of how this works, it is suggested to read the server and addon files.
-- They contain a lot of new functions and information and everything has comments about what it does.

-- Create the base frame. Note that using nil as parent defaults to UIParent
local Frame = AIO:CreateFrame("Frame", "FrameTest", nil, "UIPanelDialogTemplate")

-- Some basic method usage..
Frame:SetSize(200, 200)
Frame:SetMovable(true)
Frame:SetEnabledMouse(true)
Frame:RegisterForDrag("LeftButton")
Frame:SetPoint("CENTER")
Frame:SetToplevel(true)
Frame:SetClampedToScreen(true)

-- Setting scripts and passing functions around:
-- Since you cant send an actual function to the client, there is a little workaround with that..
-- Functions to be sent to client need to be as strings. There is also a special case that a method function can be just the function name
-- StartMoving is called on client side as Frame.StartMoving(...)
Frame:SetScript("OnDragStart", "StartMoving")
-- A function containing the code passed here is ran. The function will have all passed arguments accessible with vararg ...
-- Functions passed as strings NEED to use AIO:ToFunction(func[, retfunc]) to make them distinct from normal strings.
Frame:SetScript("OnHide", AIO:ToFunction("select(1, ...):StopMovingOrSizing()"))
-- The returned function is called. The reason this is handy is that you can create a complex function that returns the result function
-- or you can make a function and name the parameters instead of trying to use the vararg ...
-- The true in the end marks that this function returns a function
Frame:SetScript("OnDragStop", AIO:ToFunction("return function(self) self:StopMovingOrSizing() end", true))

-- Creating an input:
local Input = AIO:CreateFrame("EditBox", "InputTest", Frame, "InputBoxTemplate")
Input:SetSize(100, 30)
Input:SetAutoFocus(false)
Input:SetPoint("CENTER", Frame, "CENTER", 0, 50)
Input:SetScript("OnEnterPressed", "ClearFocus")
Input:SetScript("OnEscapePressed", "ClearFocus")
Input:SetVar("tooltipText", 'This is the Tooltip hint')

-- Creating a slider:
local Slider = AIO:CreateFrame("Slider", "SlideTest", Frame, "OptionsSliderTemplate")
Slider:SetSize(100, 17)
Slider:SetPoint("CENTER", Frame, "CENTER", 0, -50)
Slider:SetValueStep(0.5)
Slider:SetMinMaxValues(0, 100)
Slider:SetValue(50)
Slider:SetVar("tooltipText", 'This is the Tooltip hint')
Slider:AddBlock("Method", Slider:GetName() .."Text", "SetText", 50)
Slider:SetScript("OnValueChanged", AIO:ToFunction("return function(self) _G[self:GetName()..'Text']:SetText(self:GetValue()) end", true))
Slider:AddBlock("Method", Slider:GetName() .."High", "Hide")
Slider:AddBlock("Method", Slider:GetName() .."Low", "Hide")
Slider:Show()

-- Creating a child, a button:
local Button = AIO:CreateFrame("Button", "ButtonTest", Frame)
Button:SetSize(100, 30)
Button:SetPoint("CENTER", Frame, "CENTER")
Button:SetEnabledMouse(true)
-- Small script to clear the focus from input on click
Button:SetScript("OnMouseUp", AIO:ToFunction("_G.InputTest:ClearFocus()"))
-- Usually I use UIPanelButtonTemplate for buttons, but I wanted to show and test some custom color texture here:
local texture = Button:CreateTexture("TextureTest")
texture:SetAllPoints(Button)
texture:SetTexture(0.5, 1, 1, 0.5)
Button:SetNormalTexture(texture)
-- Set the font, could use GameFontNormal template, but I wanted to create my own
local fontstring = Button:CreateFontString("FontTest")
fontstring:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
fontstring:SetShadowOffset(1, -1)
Button:SetFontString(fontstring)
Button:SetText("Test")

-- Making a server side function to trigger on button click
-- Using AIO:ObjDo(...) to get some data from server elements
local function OnClickButton(Player, Event, EventParamsTable, ClientFuncRet)
    -- Prints the returned data
    print(AIO.unpack(ClientFuncRet))
end
-- This is another special case. You are trying to execute a server side function when a button is clicked.
-- For this you may want some data to be returned from the server.
-- SetScript accepts the Event, ServerFunc, FuncStr. The FuncStr is a string that is executed on server side.
-- FuncStr is not a function, it is the content of a function and all return values will be passed to ClientFuncRet table for the ServerFunc,
-- in this case OnClickButton(Player, Event, EventParamsTable, ClientFuncRet)
Button:SetScript("OnClick", OnClickButton, AIO:ObjDo(Input, ":GetText()", Slider, ":GetValue()"))

-- At this stage nothing is sent to the client yet. All done is server side.
-- You have just made a bunch of strings containing what to do.
-- Now you can make a single message (string) that you can use over and over again to send the frames in one big block
-- This will store our whole frame creation code so we can send it to client in one big block and use Frame variables for editing the frames (show/hide etc)
local ExampleUI = AIO:CreateMsg() -- Create new message
ExampleUI:Append(Frame) -- Add all Frame blocks code and child blocks to it
Frame:Clear() -- Clear the blocks from Frame and childs

-- When a player uses command .test, show the UI to player
local function OnCommand(event, player, command)
    if(command == "test") then
        -- Send the UI to the player
        -- Using SendIgnore, since we wouldnt want to reset the position of the frame for example if the frame already exists.
        -- SendIgnore will ignore the whole message if the first parameter returns true on client side, so in this case if the rame exists on server.
        -- Alternatively you can keep track of players who you have sent the frame to
        -- or you can send the frames on login and hide them, then show them when needed
        -- /reload will cause issues then though, as the reload will erase all frames from player
        ExampleUI:SendIgnoreIf(Frame, player)
        -- Incase the player closed/hid the frame, we need to show it.
        -- You can send changes to frames for players like this, just do the commands for the frame and send.
        Frame:Show()
        Frame:Send(player)
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)
