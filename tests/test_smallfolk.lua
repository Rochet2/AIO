local smallfolk = require("smallfolk")

test("smallfolk roundtrip string", function()
    local value = "hello world"
    assert_eq(smallfolk.loads(smallfolk.dumps(value)), value)
end)

test("smallfolk roundtrip number", function()
    local value = 42.5
    assert_eq(smallfolk.loads(smallfolk.dumps(value)), value)
end)

test("smallfolk roundtrip boolean and nil", function()
    assert_eq(smallfolk.loads(smallfolk.dumps(true)), true)
    assert_eq(smallfolk.loads(smallfolk.dumps(false)), false)
    assert_eq(smallfolk.loads(smallfolk.dumps(nil)), nil)
end)

test("smallfolk roundtrip table", function()
    local value = {1, "two", nested = {a = true, b = 2}}
    local restored = smallfolk.loads(smallfolk.dumps(value))
    assert_eq(restored[1], 1)
    assert_eq(restored[2], "two")
    assert_eq(restored.nested.a, true)
    assert_eq(restored.nested.b, 2)
end)

test("smallfolk roundtrip message params", function()
    local params = {{2, "PingPong", "ping"}, {1, "AIO", "Init"}}
    local restored = smallfolk.loads(smallfolk.dumps(params))
    assert_eq(restored[1][2], "PingPong")
    assert_eq(restored[1][3], "ping")
    assert_eq(restored[2][2], "AIO")
end)
