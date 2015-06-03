# LuaSerializer
LuaSerializer is a pure lua serializer that does not use loadstring or pcall for table deserialization. Works with Lua 5.1 and 5.2.  
Backlink: https://github.com/Rochet2/LuaSerializer

#Limitations
- Tables with cycles can not be serialized.
- Metatables are not serialized.
- Userdata can not be serialized
- Functions can not be serialized, but you can try serialize string.dump or the function contents as string
- Compression safety is questionable for unknown source data, use it only for server->client or otherwise safe assumed data

#Serializing
LuaSerializer serializes data into a string and is able to then deserialize the data without using loadstring or pcall (safely, not calling functions).  
LuaSerializer is capable of safely serializing and deserializing:
- nil
- bool
- string
- number including nan and inf
- tables with no unserializable data and no cycles

#API
```lua
local LuaSerializer = LuaSerializer or require("LuaSerializer")

-- Some lua compatibility between 5.1 and 5.2
local unpack = unpack or table.unpack

-- Takes in values and returns a string with them serialized
-- Uses LZW compression, use LuaSerializer.serialize_nocompress if you dont want this
-- LuaSerializer.serialize(...)

-- Takes in a string of serialized data and returns a table with the values in it and the amount of values
-- The data must have been serialized with LuaSerializer.serialize_nocompress
-- LuaSerializer.unserialize(serializeddata)

local serialized = LuaSerializer.serialize(55, "test", {1,2, y = 66}, nil, true)
local data, n = LuaSerializer.unserialize(serialized)
print(unpack(data, 1, n))
-- prints:
-- 55      test    table: 491A9920 nil     true

-- Takes in values and returns a string with them serialized
-- Does not compress the result
-- LuaSerializer.serialize_nocompress(...)

-- Takes in a string of serialized data and returns a table with the values in it and the amount of values
-- The data must have been serialized with LuaSerializer.serialize
-- LuaSerializer.unserialize_nocompress(serializeddata)

local serialized = LuaSerializer.serialize_nocompress(55, "test", {1,2, y = 66}, nil, true)
local data, n = LuaSerializer.unserialize_nocompress(serialized)
print(unpack(data, 1, n))
-- prints:
-- 55      test    table: 491A9920 nil     true
```

#Included dependencies
You do not need to get these, they are already included
- Compression for string data: https://love2d.org/wiki/TLTools

#Special thanks
- Kenuvis < [Gate](http://www.ac-web.org/forums/showthread.php?148415-LUA-Gate-Project), [ElunaGate](https://github.com/ElunaLuaEngine/ElunaGate) >
- Laurea (alexeng) < https://github.com/Alexeng >
- Lua contributors < http://www.lua.org/ >
