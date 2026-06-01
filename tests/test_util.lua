local aio_util = require("aio_util")

test("basename unix path", function()
    assert_eq(aio_util.basename("/server/lua_scripts/MyAddon.lua"), "MyAddon.lua")
end)

test("basename windows backslash path", function()
    assert_eq(aio_util.basename("C:\\server\\lua_scripts\\MyAddon.lua"), "MyAddon.lua")
end)

test("basename windows forward slash path", function()
    assert_eq(aio_util.basename("C:/server/lua_scripts/MyAddon.lua"), "MyAddon.lua")
end)

test("basename plain filename", function()
    assert_eq(aio_util.basename("MyAddon.lua"), "MyAddon.lua")
end)

test("getMessageStoredSize sums part lengths", function()
    local data = {
        parts = {
            n = 3,
            [1] = "abc",
            [2] = "de",
            [3] = "f",
        },
    }
    assert_eq(aio_util.getMessageStoredSize(data), 6)
end)

test("getMessageStoredSize ignores missing parts", function()
    local data = {
        parts = {
            n = 3,
            [1] = "abc",
            [3] = "f",
        },
    }
    assert_eq(aio_util.getMessageStoredSize(data), 4)
end)

test("isMessageExpired uses milliseconds", function()
    assert_true(not aio_util.isMessageExpired(1000, 10000, 15000))
    assert_true(aio_util.isMessageExpired(1000, 17000, 15000))
    assert_true(aio_util.isMessageExpired(1000, 16000, 15000))
end)
