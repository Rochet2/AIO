local lualzw = require("lualzw")

test("lualzw roundtrip repetitive", function()
    local input = string.rep("foo", 500)
    local compressed = assert(lualzw.compress(input))
    local decompressed = assert(lualzw.decompress(compressed))
    assert_eq(decompressed, input)
    assert_true(#compressed < #input)
end)

test("lualzw null-safe compressed output", function()
    local input = string.rep("bar", 500)
    local compressed = assert(lualzw.compress(input))
    assert_true(not compressed:find("\0", 1, true))
end)

test("lualzw version", function()
    assert_eq(lualzw._VERSION, "1.1.0")
end)
