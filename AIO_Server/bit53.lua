-- Provides compatibility for scripts using bit libs for lua versions < 5.3
-- Using load to avoid errors when having this file in earlier lua sources than 5.3

-- check that lua version is higher or equal to 5.3
local MIN_LUA_VER = 5.3
if tonumber(_VERSION:match("%d+%.?%d*")) >= MIN_LUA_VER then
    return assert(assert(load( [[
        local bit53 = {}
        function bit53.band(a,b)
            return a&b
        end
        function bit53.bor(a,b)
            return a|b
        end
        function bit53.bxor(a,b)
            return a~b
        end
        function bit53.bnot(a)
            return ~a
        end
        function bit53.lshift(a, b)
            return a<<b
        end
        function bit53.rshift(a, b)
            return a>>b
        end
        return bit53
    ]], "bit53" ))())
end
