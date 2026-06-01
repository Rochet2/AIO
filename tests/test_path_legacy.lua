-- Documents why basename must handle both separators on Windows.
local old_basename = function(path)
    return string.match(path, "([^/]*)$")
end

local new_basename = function(path)
    return string.match(path, "([^/\\]*)$")
end

test("legacy basename fails on windows backslash paths", function()
    local path = "C:\\server\\lua_scripts\\MyAddon.lua"
    assert_eq(old_basename(path), path)
    assert_eq(new_basename(path), "MyAddon.lua")
end)

test("legacy basename works on forward slash paths", function()
    local path = "lua_scripts/MyAddon.lua"
    assert_eq(old_basename(path), "MyAddon.lua")
    assert_eq(new_basename(path), "MyAddon.lua")
end)
