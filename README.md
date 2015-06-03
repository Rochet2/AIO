#AIO
AIO is a pure lua server-client communication system for Eluna and WoW.  
AIO is designed for sending lua addons and data to player from server and data from player to server.  
Made for [Eluna Lua Engine](https://github.com/ElunaLuaEngine/Eluna). Tested on 3.3.5a and should work on other patches. Tested with Lua 5.1 and 5.2.

Backlink: https://github.com/Rochet2/AIO

#Installation
- Make sure you have [Eluna Lua Engine](https://github.com/ElunaLuaEngine/Eluna)
- Copy the __contents__ of `AIO_Client` to your `WoW_installation_folder/Interface/AddOns/`
- Copy the __contents__ of `AIO_Server` to your `server_root/lua_scripts/`
- See configuration settings on AIO.lua file. You can tweak both the server and client file respectively

#API
For example scripts see the Examples folder. The example files are named according to their final execution location. To run the examples place all of their files to `server_root/lua_scripts/`.

```lua
-- AIO is required this way due to server and client differences with require function
local AIO = AIO or require("AIO")

-- Adds the file at given path to files to send to players if called on server side.
-- The addon code is trimmed according to settings in AIO.lua.
-- The addon is cached on client side and will be updated only when needed.
-- Returns false on client side and true on server side. By default the
-- path is the current file's path and name is the file's name
-- 'path' is relative to worldserver.exe but an absolute path can also be given.
added = AIO.AddAddon([path, name])

-- Similar to AddAddon - Adds 'code' to the addons sent to players. The code is trimmed
-- according to settings in AIO.lua. The addon is cached on client side and will
-- be updated only when needed. 'name' is an unique name for the addon, usually
-- you can use the file name or addon name there. Do note that short names are
-- better since they are sent back and forth to indentify files.
-- The function only exists on server side.
AIO.AddAddonCode(name, code)

-- Triggers the handler with the 'handlername' from the handlertable added with
-- AIO.AddHandlers(name, handlertable) for the 'name'
-- The server side version.
AIO.Handle(player, name, handlername[, ...])
-- The client side version.
AIO.Handle(name, handlername[, ...])

-- Adds a table of handler functions for the specified 'name'. When a message like
--  AIO.Handle(name, "HandlerName", ...) is received, the handlertable["HandlerName"]
-- will be called with player and varargs as parameters.
-- Returns the passed 'handlertable'
handlertable = AIO.AddHandlers(name, handlertable)

-- Adds a new callback function that is called if a message with the given
-- name is recieved and the message has the correct fmt if given.
-- fmt is a table of lua type strings: {"string", "table", "number", ...}
-- All parameters the sender sends in the message will be passed to func when called
AIO.RegisterEvent(name, func[, fmt])

-- Adds a new function that is called when the initial message is sent to the player.
-- The function is called before sending and the initial message is passed to it
-- along with the player if available: func(msg[, player])
-- In the function you can modify the passed msg and/or return a new one to be
-- used as initial message. Only for server side.
AIO.AddOnInit(func)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are account bound
AIO.AddSavedVar(key)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are character bound.
AIO.AddSavedVarChar(key)

-- Makes the addon frame save it's position over relog.
-- If char is true, the position saving is character bound, otherwise account bound.
-- Only exists on client side and you only call it once per frame.
AIO.SavePosition(frame[, char])
```

```lua
-- Creates and returns a new AIO message that you can append stuff to and send to
-- client or server. Example: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
-- These messages handle all client-server communication.
msg = AIO.Msg()

-- The name is used to identify the handler function on receiving end.
-- A handler function registered with AIO.RegisterEvent(name, func[, fmt])
-- will be called on receiving end with the varargs.
function msgmt:Add(name, ...)

-- Appends messages to eachother, returns self
msg = msg:Append(msg2)

-- Sends the message, returns self
-- Server side version - sends to all players passed
msg = msg:Send(player, ...)
-- Client side version - sends to server
msg = msg:Send()

-- Returns true if the message has something in it
hasmsg = msg:HasMsg()

-- Returns the message as a string
msgstr = msg:ToString()

-- Erases the so far built message and returns self
msg = msg:Clear()

-- Assembles the message string from added and appended data. Mainly for internal use.
-- Returns self
msg = msg:Assemble()
```

#Included dependencies
You do not need to get these, they are already included
- Lua serializer: https://github.com/Rochet2/LuaSerializer
- Compression for string data: https://love2d.org/wiki/TLTools
- Obfuscation for addon code: http://luasrcdiet.luaforge.net/
- Sent addons' frame position saving: http://www.wowace.com/addons/libwindow-1-1/

#Special thanks
- Kenuvis < [Gate](http://www.ac-web.org/forums/showthread.php?148415-LUA-Gate-Project), [ElunaGate](https://github.com/ElunaLuaEngine/ElunaGate) >
- Laurea (alexeng) < https://github.com/Alexeng >
- Foereaper < https://github.com/Foereaper >
- Eluna team < https://github.com/ElunaLuaEngine/Eluna#team >
- Lua contributors < http://www.lua.org/ >
