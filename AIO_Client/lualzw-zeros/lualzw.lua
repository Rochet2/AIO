--[[
MIT License

Copyright (c) 2016 Rochet2

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local VERSION = "1.1.0"

local char = string.char
local byte = string.byte
local type = type
local sub = string.sub
local tconcat = table.concat

local function normalizeSkip(skip)
    local skippedcharacters = {}
    if skip then
        for k, v in pairs(skip) do
            if v == true then
                if type(k) == "number" and k >= 0 and k <= 255 then
                    skippedcharacters[k] = true
                end
            elseif type(v) == "number" and v >= 0 and v <= 255 then
                skippedcharacters[v] = true
            end
        end
    end
    return skippedcharacters
end

local function normalizeControl(value, name, default)
    if value == nil then
        return default
    end
    if type(value) ~= "string" or #value ~= 1 then
        error("invalid " .. name .. " control character")
    end
    return value
end

local function validateLimit(name, value)
    if value == nil then
        return true
    end
    if type(value) ~= "number" or value < 0 then
        return nil, "number expected for " .. name .. ", got " .. type(value)
    end
    return true
end

local function buildState(skippedcharacters)
    local function findNextNotSkipped(i)
        repeat
            if not skippedcharacters[i] then
                return i
            end
            i = i + 1
        until false
    end

    local basedictcompress = {}
    local basedictdecompress = {}

    local firstNotSkipped = findNextNotSkipped(0)
    local secondNotSkipped = findNextNotSkipped(firstNotSkipped + 1)
    if firstNotSkipped > 255 or secondNotSkipped > 255 or firstNotSkipped == secondNotSkipped then
        return nil, "invalid configuration, no character can be used in compression"
    end

    for i = 0, 255 do
        local ic, iic = char(i), char(i, firstNotSkipped)
        basedictcompress[ic] = iic
        basedictdecompress[iic] = ic
    end

    local function dictBump(dict, a, b)
        if a >= 256 then
            a, b = firstNotSkipped, findNextNotSkipped(b + 1)
            if b >= 256 then
                dict = {}
                b = secondNotSkipped
            end
        end
        local code = char(a, b)
        a = findNextNotSkipped(a + 1)
        return dict, a, b, code
    end

    return {
        skippedcharacters = skippedcharacters,
        basedictcompress = basedictcompress,
        basedictdecompress = basedictdecompress,
        firstNotSkipped = firstNotSkipped,
        secondNotSkipped = secondNotSkipped,
        dictBump = dictBump,
    }
end

local function createCodec(options)
    options = options or {}

    local uncompressedControl = normalizeControl(options.uncompressed, "uncompressed", "u")
    local compressedControl = normalizeControl(options.compressed, "compressed", "c")
    if uncompressedControl == compressedControl then
        error("uncompressed and compressed control characters must differ")
    end

    local state, err = buildState(normalizeSkip(options.skip))
    if not state then
        error(err)
    end

    local prefixCost = 1

    local function unwrap(input)
        if #input < 1 then
            return nil, "invalid input - not a compressed string"
        end
        return state, char(byte(input, 1)), sub(input, 2)
    end

    local function compress(input, max_input_size)
        if type(input) ~= "string" then
            return nil, "string expected, got " .. type(input)
        end

        local ok, limitErr = validateLimit("max_input_size", max_input_size)
        if not ok then
            return nil, limitErr
        end

        local len = #input
        if max_input_size and len > max_input_size then
            return nil, "input exceeds limit"
        end

        if len <= 1 then
            return uncompressedControl .. input
        end

        local basedictcompress = state.basedictcompress
        local dictBump = state.dictBump
        local dict = {}
        local a, b = state.firstNotSkipped, state.secondNotSkipped
        local dictCode

        local result = {}
        local resultlen = 0
        local n = 1
        local word = ""
        for i = 1, len do
            local c = char(byte(input, i))
            local wc = word .. c
            if not (basedictcompress[wc] or dict[wc]) then
                local write = basedictcompress[word] or dict[word]
                if not write then
                    return nil, "algorithm error, could not fetch word"
                end
                result[n] = write
                resultlen = resultlen + 2
                n = n + 1
                if len <= resultlen + prefixCost then
                    return uncompressedControl .. input
                end
                dict, a, b, dictCode = dictBump(dict, a, b)
                dict[wc] = dictCode
                word = c
            else
                word = wc
            end
        end

        result[n] = basedictcompress[word] or dict[word]
        resultlen = resultlen + 2
        if len <= resultlen + prefixCost then
            return uncompressedControl .. input
        end

        return compressedControl .. tconcat(result)
    end

    local function decompress(input, max_output_size, max_input_size, max_codes)
        if type(input) ~= "string" then
            return nil, "string expected, got " .. type(input)
        end

        local ok, limitErr = validateLimit("max_output_size", max_output_size)
        if not ok then
            return nil, limitErr
        end

        ok, limitErr = validateLimit("max_input_size", max_input_size)
        if not ok then
            return nil, limitErr
        end

        ok, limitErr = validateLimit("max_codes", max_codes)
        if not ok then
            return nil, limitErr
        end

        if max_input_size and #input > max_input_size then
            return nil, "compressed input exceeds limit"
        end

        local decodeState, control, body = unwrap(input)
        if not decodeState then
            return nil, control
        end

        if max_input_size and #body > max_input_size then
            return nil, "compressed input exceeds limit"
        end

        if control == uncompressedControl then
            if max_output_size and #body > max_output_size then
                return nil, "decompressed output exceeds limit"
            end
            return body
        elseif control ~= compressedControl then
            return nil, "invalid input - not a compressed string"
        end

        local len = #body
        if len < 2 or len % 2 == 1 then
            return nil, "invalid input - not a compressed string"
        end

        local basedictdecompress = decodeState.basedictdecompress
        local dictBump = decodeState.dictBump
        local dict = {}
        local a, b = decodeState.firstNotSkipped, decodeState.secondNotSkipped
        local dictCode
        local codeCount = 0

        local function bumpDictionary(value)
            if max_codes and codeCount >= max_codes then
                return nil, "decompression step limit exceeded"
            end
            dict, a, b, dictCode = dictBump(dict, a, b)
            dict[dictCode] = value
            codeCount = codeCount + 1
            return true
        end

        local result = {}
        local n = 1
        local outputlen = 0
        local last = sub(body, 1, 2)
        local firstStr = basedictdecompress[last] or dict[last]
        if not firstStr then
            return nil, "could not find last from dict. Invalid input?"
        end
        result[n] = firstStr
        outputlen = outputlen + #firstStr
        if max_output_size and outputlen > max_output_size then
            return nil, "decompressed output exceeds limit"
        end
        n = n + 1

        for i = 3, len, 2 do
            local inputCode = sub(body, i, i + 1)
            local lastStr = basedictdecompress[last] or dict[last]
            if not lastStr then
                return nil, "could not find last from dict. Invalid input?"
            end
            local toAdd = basedictdecompress[inputCode] or dict[inputCode]
            if toAdd then
                outputlen = outputlen + #toAdd
                if max_output_size and outputlen > max_output_size then
                    return nil, "decompressed output exceeds limit"
                end
                result[n] = toAdd
                n = n + 1
                local bumped, bumpErr = bumpDictionary(lastStr .. sub(toAdd, 1, 1))
                if not bumped then
                    return nil, bumpErr
                end
            else
                local tmp = lastStr .. sub(lastStr, 1, 1)
                outputlen = outputlen + #tmp
                if max_output_size and outputlen > max_output_size then
                    return nil, "decompressed output exceeds limit"
                end
                result[n] = tmp
                n = n + 1
                local bumped, bumpErr = bumpDictionary(tmp)
                if not bumped then
                    return nil, bumpErr
                end
            end
            last = inputCode
        end

        return tconcat(result)
    end

    return {
        compress = compress,
        decompress = decompress,
        configure = createCodec,
        _VERSION = VERSION,
        uncompressed = uncompressedControl,
        compressed = compressedControl,
    }
end

-- AIO uses the former "zeros" branch wire format (no null bytes in dictionary codes).
local codec = createCodec({ skip = { [0] = true } })
lualzw = codec
return codec
