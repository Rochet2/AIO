-- LibCompress.lua
--
-- Authors: jjsheets and Galmok of European Stormrage (Horde)
-- Email: sheets.jeff@gmail.com and galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
--
-- Hacked severely by Taehl (SelfMadeSpirit@gmail.com)
----------------------------------------------------------------------------------
TLibCompress = {}

local unpack = unpack or table.unpack

local function encode(x)
    local bytes = {}
    for k = 1, #bytes do bytes[k] = nil end
    local xmod
    x, xmod = math.modf(x/255)
    xmod = xmod * 255
    bytes[#bytes + 1] = xmod
    while x > 0 do
        x, xmod = math.modf(x/255)
        xmod = xmod * 255
        bytes[#bytes + 1] = xmod
    end
    if #bytes == 1 and bytes[1] > 0 and bytes[1] < 250 then
        return string.char(bytes[1])
    else
        for i = 1, #bytes do bytes[i] = bytes[i] + 1 end
        return string.char(256 - #bytes, unpack(bytes))
    end
end

local function decode(ss,i)
    i = i or 1
    local a = string.byte(ss,i,i)
    if a > 249 then
        local r = 0
        a = 256 - a
        for n = i+a, i+1, -1 do
            r = r * 255 + string.byte(ss,n,n) - 1
        end
        return r, a + 1
    else
        return a, 1
    end
end

local dict = {}
function TLibCompress.CompressLZW(uncompressed)
    local dict_size = 256
    for k in pairs(dict) do
        dict[k] = nil
    end
    local result = {"\222"}
    local w = ''
    local ressize = 1
    for i = 0, 255 do
        dict[string.char(i)] = i
    end
    for i = 1, #uncompressed do
        local c = uncompressed:sub(i,i)
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
        return table.concat(result)
    else
        return string.char(1)..uncompressed
    end
end

function TLibCompress.DecompressLZW(compressed)
    if type(compressed) == "string" then
        if compressed:sub(1,1) == string.char(1) then
            return compressed:sub(2)
        end
        if compressed:sub(1,1) ~= "\222" then
            return nil, "Can only decompress LZW compressed data ("..tostring(compressed:sub(1,1))..")"
        end
        compressed = compressed:sub(2)
        local dict_size = 256
        for k in pairs(dict) do
            dict[k] = nil
        end
        for i = 0, 255 do
            dict[i] = string.char(i)
        end
        local result = {}
        local t = 1
        local delta, k
        k, delta = decode(compressed,t)
        t = t + delta
        result[#result+1] = dict[k]
        local w = dict[k]
        local entry
        while t <= #compressed do
            k, delta = decode(compressed,t)
            t = t + delta
            entry = dict[k] or (w..w:sub(1,1))
            result[#result+1] = entry
            dict[dict_size] = w..entry:sub(1,1)
            dict_size = dict_size + 1
            w = entry
        end
        return table.concat(result)
    else
        error("Can only uncompress strings")
    end
end

return TLibCompress
