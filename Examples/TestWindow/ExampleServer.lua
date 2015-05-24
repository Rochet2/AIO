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
This file is a server file. It is loaded on server side and handles all server side code.
This file should be placed somewhere in the lua_scripts folder so Eluna can load it.
You can of course design your own addons and codes in some other way.

Few tips:
On server side the code size does not matter, however safety does!
On client side safety is not needed, but server safety will avoid nasty behavior and errors.
The client may send ANY data. Be cautious and make sure the data you receive is indeed the type you
expect it to be.

Message compression and obfuscation should be turned on in AIO.lua files on server
and client. If you want to debug your code and need to see the correct line numbers
on error messages, disable obfuscation.

After getting some base understanding of how things work, it is suggested to read all the AIO files.
They contain a lot of new functions and information and everything has comments about what it does.
]]


-- Note that getting AIO is done like this since AIO is defined on client
-- side by default when running addons and on server side it may need to be
-- required depending on the load order. On server only files the require
-- would be enough, but lets just keep it like this for the sake of consistency
local AIO = AIO or require("AIO")

-- AIO.AddHandlers adds a new table of functions as handlers for a name and returns the table.
-- This is used to add functions for a specific "channel name" that trigger on specific messages.
-- At this point the table is empty, but MyHandlers table will be filled soon.
local MyHandlers = AIO.AddHandlers("AIOExample", {})
-- You can also call this after filling the table. like so:
--  local MyHandlers = {}; ..fill MyHandlers table.. AIO.AddHandlers("AIOExample", MyHandlers)

-- An example handler.
-- This prints all the values the client sends with the command
--  AIO.Handle("AIOExample", "print")
function MyHandlers.Print(player, ...)
    print(...)
end

-- When a player uses command .test, show the UI to player
-- The showing is done by sending a message to the client that then does whatever
-- we have coded to be done when receiving the message
local function OnCommand(event, player, command)
    if(command == "test") then
        -- Note that AIO.Handle has two different definitions:
        -- On client side you don't pass the player argument
        AIO.Handle(player, "AIOExample", "ShowFrame")
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)

