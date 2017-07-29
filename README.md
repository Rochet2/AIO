# AIO
AIO is a pure lua server-client communication system for Eluna and WoW.  
AIO is designed for sending lua addons and data to player from server and data from player to server.  
Made for [Eluna Lua Engine](https://github.com/ElunaLuaEngine/Eluna). Tested on 3.3.5a and should work on other patches. Tested with Lua 5.1 and 5.2.  
[Third party C++ support is made by SaiFi0102](https://github.com/SaiFi0102/TrinityCore/blob/CAIO-3.3.5/CAIO_README.md). It allows you to use AIO without requiring Eluna.

Backlink: https://github.com/Rochet2/AIO

# Installation
- Make sure you have [Eluna Lua Engine](https://github.com/ElunaLuaEngine/Eluna)
- Copy the `AIO_Client` to your `WoW_installation_folder/Interface/AddOns/`
- Copy the `AIO_Server` to your `server_root/lua_scripts/`
- See configuration settings on AIO.lua file. You can tweak both the server and client file respectively
- When developing an addon it is recommended to have AIO_ENABLE_PCALL off and sometimes you may need AIO_ENABLE_DEBUG_MSGS on to see some information about what is going on.

# About
AIO works so that the server and client have their own lua scripts that handle sending and receiving messages from and to eachother.
When an addon added to AIO as an addon to send to the client, it will be processed (depending on settings, obfuscated and compressed) and stored in memory to wait for sending to players.
All addons that are added are executed on client side in the order they were added to AIO.
AIO is using a cache system to cache the addon codes to client side so they dont need to be sent on every login.
Only if an addon is changed or added the new addon is sent again. The user can also clear his local AIO cache in which case the addons will be sent again.
The full addon code sent to client is executed on client as is. The code has full access to the client side addon API.
The client-server messaging is handled with an AIO message helper class. It holds and manages the data to send over.

# Commands
There are some commands that may be useful.  
On client side use `/aio help` to see a list of them. On server side use `.aio help` to see a list of them.

# Safety
The messaging between server and client is coded to be safe

- you can limit the cache sizes, delays and other in AIO.lua
- data received from client is only deserialized - no compressions etc.
- serialization library is not using loadstring to make deserialization safe
- when receiving messages the code is run in pcall to prevent all user sent data creating errors. Set debug messages on in AIO.lua to see all errors on server side as well
- the code is only as safe as you make it. In your own codes make sure all data the client sends to server and you use is the type you expect it to be and is in the range you expect it to be in. (example: math.huge is a number type, but not a real number)
- make sure your code has asserts in place and is fast. There is a tweakable timeout in AIO.lua just to be sure that the server will not hang if you happen to write bad or abusable code or if a bad user finds a way to hang the system
- Do check the AIO.lua settings and tweak them to your needs for both client and server respectively. This is important to fend off bad users and make things work better with your setup.

# Handlers
AIO has a few handlers by default that are used for the internal codes and you can
use them if you wish.  
You can also code your own handlers and add them to AIO with the functions described in API section. See AIO.RegisterEvent(name, func) and AIO.AddHandlers(name, handlertable)

```lua
-- Force reload of player UI
-- Displays a message that UI is being force reloaded and reloads UI when player
-- clicks anywhere in his screen.
AIO.Handle(player, "AIO", "ForceReload")

-- Force reset of player UI
-- Resets AIO addon saved variables and displays a message that UI is being force
-- reloaded and reloads UI when player clicks anywhere in his screen.
AIO.Handle(player, "AIO", "ForceReset")
```

# API
For example scripts see the Examples folder. The example files are named according to their final execution location. To run the examples place all of their files to `server_root/lua_scripts/`.

There are some client side commands. Use the slash command `/aio` ingame to see list of commands

```lua
-- AIO is required this way due to server and client differences with require function
local AIO = AIO or require("AIO")

-- Returns true if we are on server side, false if we are on client side
isServer = AIO.IsServer()

-- Returns AIO version - note the type is not guaranteed to be a number
version = AIO.GetVersion()

-- Adds the file at given path to files to send to players if called on server side.
-- The addon code is trimmed according to settings in AIO.lua.
-- The addon is cached on client side and will be updated only when needed.
-- Returns false on client side and true on server side. By default the
-- path is the current file's path and name is the file's name
-- 'path' is relative to worldserver.exe but an absolute path can also be given.
-- You should call this function only on startup to ensure everyone gets the same
-- addons and no addon is duplicate.
added = AIO.AddAddon([path, name])
-- The way this is designed to be used is at the top of an addon file so that the
-- file is added and not run if we are on server, and just run if we are on client:
if AIO.AddAddon() then
    return
end

-- Similar to AddAddon - Adds 'code' to the addons sent to players. The code is trimmed
-- according to settings in AIO.lua. The addon is cached on client side and will
-- be updated only when needed. 'name' is an unique name for the addon, usually
-- you can use the file name or addon name there. Do note that short names are
-- better since they are sent back and forth to indentify files.
-- The function only exists on server side.
-- You should call this function only on startup to ensure everyone gets the same
-- addons and no addon is duplicate.
AIO.AddAddonCode(name, code)

-- Triggers the handler function that has the name 'handlername' from the handlertable
-- added with AIO.AddHandlers(name, handlertable) for the 'name'.
-- Can also trigger a function registered with AIO.RegisterEvent(name, func)
-- All triggered handlers have parameters handler(player, ...) where varargs are
-- the varargs in AIO.Handle or msg.Add
-- This function is a shorthand for AIO.Msg():Add(name, handlername, ...):Send()
-- For efficiency favour creating messages once and sending them rather than creating
-- them over and over with AIO.Handle().
-- The server side version.
AIO.Handle(player, name, handlername[, ...])
-- The client side version.
AIO.Handle(name, handlername[, ...])

-- Adds a table of handler functions for the specified 'name'. When a message like:
-- AIO.Handle(name, "HandlerName", ...) is received, the handlertable["HandlerName"]
-- will be called with player and varargs as parameters.
-- Returns the passed 'handlertable'.
-- AIO.AddHandlers uses AIO.RegisterEvent internally, so same name can not be used on both.
handlertable = AIO.AddHandlers(name, handlertable)

-- Adds a new callback function that is called if a message with the given
-- name is recieved. All parameters the sender sends in the message will
-- be passed to func when called.
-- Example message: AIO.Msg():Add(name, ...):Send()
-- AIO.AddHandlers uses AIO.RegisterEvent internally, so same name can not be used on both.
AIO.RegisterEvent(name, func)

-- Adds a new function that is called when the initial message is sent to the player.
-- The function is called before sending and the initial message is passed to it
-- along with the player if available: func(msg[, player])
-- In the function you can modify the passed msg and/or return a new one to be
-- used as initial message. Only on server side.
-- This can be used to send for example initial values (like player stats) for the addons.
-- If dynamic loading is preferred, you can use the messaging API to request the values
-- on demand also.
AIO.AddOnInit(func)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are account bound.
-- Only exists on client side and you should call it only once per key.
-- All saved data is saved to client side.
AIO.AddSavedVar(key)

-- Key is a key for a variable in the global table _G.
-- The variable is stored when the player logs out and will be restored
-- when he logs back in before the addon codes are run.
-- These variables are character bound.
-- Only exists on client side and you should call it only once per key.
-- All saved data is saved to client side.
AIO.AddSavedVarChar(key)

-- Makes the addon frame save it's position and restore it on login.
-- If char is true, the position saving is character bound, otherwise account bound.
-- Only exists on client side and you should call it only once per frame.
-- All saved data is saved to client side.
AIO.SavePosition(frame[, char])

-- AIO message class:
-- Creates and returns a new AIO message that you can append stuff to and send to
-- client or server. Example: AIO.Msg():Add("MyHandlerName", param1, param2):Send(player)
-- These messages handle all client-server communication.
msg = AIO.Msg()

-- The name is used to identify the handler function on receiving end.
-- A handler function registered with AIO.RegisterEvent(name, func)
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

# Included dependencies
You do not need to get these, they are already included
- Lua serializer: https://github.com/gvx/Smallfolk
- Lua crc32: https://github.com/davidm/lua-digest-crc32lua
- Lua queue with modifications: http://www.lua.org/pil/11.4.html
- Compression for string data: https://github.com/Rochet2/lualzw/tree/zeros
- Obfuscation for addon code: http://luasrcdiet.luaforge.net/
- Sent addons' frame position saving: http://www.wowace.com/addons/libwindow-1-1/

# Special thanks
- Kenuvis < [Gate](http://www.ac-web.org/forums/showthread.php?148415-LUA-Gate-Project), [ElunaGate](https://github.com/ElunaLuaEngine/ElunaGate) >
- Laurea/alexeng/Kyromyr < https://github.com/Alexeng, https://github.com/Kyromyr>
- Foereaper < https://github.com/Foereaper >
- SaiF < https://github.com/SaiFi0102 >
- Eluna team < https://github.com/ElunaLuaEngine/Eluna#team >
- Lua contributors < http://www.lua.org/ >
