-- library for compatibility between different wow lua versions
-- this is used to provide a consistent interface for functions

if AIO_LuaCompat ~= nil then
    error("AIO_LuaCompat already defined")
end
AIO_LuaCompat = {}

function AIO_LuaCompat.print(...)
    -- create message by concatenating all arguments from last to first
    -- and ignoring nils until the first non-nil value encountered
    local msg = ""
    local printedSomething = false
    for i = arg.n, 1, -1 do
        if printedSomething or arg[i] ~= nil then
            msg = (i == 1 and "" or " ") .. tostring(arg[i]) .. msg
            printedSomething = true
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end
-- setglobal("print", AIO_LuaCompat.print)

local len
if table.getn then
	local getn = table.getn
	local strlen = string.len
	function len(t)
		if type(t) == 'table' then
			return getn(t)
		end
		if type(t) == 'string' then
			return strlen(t)
		end
		error('len function does not support ' .. type(t))
	end
else
	len = loadstring("function(t) return #t end")
end
AIO_LuaCompat.len = len

AIO_LuaCompat.math_huge = math.huge or 1E+308 * 1E+308