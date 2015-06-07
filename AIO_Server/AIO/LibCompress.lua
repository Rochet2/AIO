-- LibCompress.lua
--
-- Authors: jjsheets and Galmok of European Stormrage (Horde)
-- Email: sheets.jeff@gmail.com and galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
--
-- Hacked severely by Taehl (SelfMadeSpirit@gmail.com)
----------------------------------------------------------------------------------

assert(not TLibCompress, "LibCompress already loaded. Possibly loading different versions of LibCompress")

TLibCompress = {}

local assert = assert
local type = type
local unpack = unpack or table.unpack
local tconcat = table.concat
local schar = string.char
local ssub = string.sub
local sbyte = string.byte
local mmodf = math.modf

local function encode(x)
    local bytes = {}
    local xmod
    repeat
        x, xmod = mmodf(x/255)
        xmod = xmod * 255
        bytes[#bytes + 1] = xmod
    until x <= 0
    if #bytes == 1 and bytes[1] > 0 and bytes[1] < 250 then
        return schar(bytes[1])
    else
        for i = 1, #bytes do bytes[i] = bytes[i] + 1 end
        return schar(256 - #bytes, unpack(bytes))
    end
end

local function decode(ss,i)
    i = i or 1
    local a = sbyte(ss,i,i)
    if a > 249 then
        local r = 0
        a = 256 - a
        for n = i+a, i+1, -1 do
            r = r * 255 + sbyte(ss,n,n) - 1
        end
        return r, a + 1
    else
        return a, 1
    end
end

function TLibCompress.CompressLZW(uncompressed)
    assert(type(uncompressed) == 'string')
    local result = {'\222'}
    local ressize = 1
    local w = ''
    local dict = {}
    local dict_size = 256
    for i = 0, 255 do
        dict[schar(i)] = i
    end
    for i = 1, #uncompressed do
        local c = ssub(uncompressed,i,i)
        local wc = w..c
        if dict[wc] then
            w = wc
        else
            dict[wc] = dict_size
            dict_size = dict_size +1
            local r = encode(dict[w])
            ressize = ressize + #r
            result[#result + 1] = r
            w = c
        end
    end
    if w then
        local r = encode(dict[w])
        ressize = ressize + #r
        result[#result + 1] = r
    end
    if (#uncompressed+1) > ressize then
        return tconcat(result)
    else
        return '\1'..uncompressed
    end
end

function TLibCompress.DecompressLZW(compressed)
    assert(type(compressed) == 'string')
    local UC
    UC, compressed = ssub(compressed,1,1), ssub(compressed, 2)
    if UC == '\1' then
        return compressed
    end
    if UC ~= "\222" then
        return nil, "Can only decompress LZW compressed data ("..tostring(UC)..")"
    end
    local dict_size = 256
    local dict = {}
    for i = 0, 255 do
        dict[i] = schar(i)
    end
    local result = {}
    local t = 1
    local delta, k
    k, delta = decode(compressed,t)
    t = t + delta
    result[#result+1] = dict[k]
    local w = dict[k]
    local entry
    local csize = #compressed
    while t <= csize do
        k, delta = decode(compressed,t)
        t = t + delta
        entry = dict[k] or (w..ssub(w,1,1))
        result[#result+1] = entry
        dict[dict_size] = w..ssub(entry,1,1)
        dict_size = dict_size + 1
        w = entry
    end
    return tconcat(result)
end

return TLibCompress
