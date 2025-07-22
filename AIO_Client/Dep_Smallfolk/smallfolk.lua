local M = {}
Smallfolk = M
local expect_object, dump_object
local error, tostring, pairs, type, floor, concat = error, tostring, pairs, type, math.floor, table.concat
local string_find = string.find
local gsub = string.gsub
local sub = string.sub
local format = string.format

local dump_type = {}

local len = AIO_LuaCompat.len
local huge = AIO_LuaCompat.math_huge
local print = AIO_LuaCompat.print -- not needed, but useful for debugging

function dump_type:string(nmemo, memo, acc)
	local nacc = len(acc)
	acc[nacc + 1] = '"'
	acc[nacc + 2] = gsub(self, '"', '""')
	acc[nacc + 3] = '"'
	return nmemo
end

function dump_type:number(nmemo, memo, acc)
	acc[len(acc) + 1] = format("%.17g", self)
	return nmemo
end

function dump_type:table(nmemo, memo, acc)
    --[[
	if memo[self] then
		acc[len(acc) + 1] = '@'
		acc[len(acc) + 1] = tostring(memo[self])
		return nmemo
	end
	nmemo = nmemo + 1
    ]]
	memo[self] = nmemo
	acc[len(acc) + 1] = '{'
	local nself = len(self)
	for i = 1, nself do -- don't use ipairs here, we need the gaps
		nmemo = dump_object(self[i], nmemo, memo, acc)
		acc[len(acc) + 1] = ','
	end
	for k, v in pairs(self) do
		if type(k) ~= 'number' or floor(k) ~= k or k < 1 or k > nself then
			nmemo = dump_object(k, nmemo, memo, acc)
			acc[len(acc) + 1] = ':'
			nmemo = dump_object(v, nmemo, memo, acc)
			acc[len(acc) + 1] = ','
		end
	end
	acc[len(acc)] = acc[len(acc)] == '{' and '{}' or '}'
	return nmemo
end

function dump_object(object, nmemo, memo, acc)
	if object == true then
		acc[len(acc) + 1] = 't'
	elseif object == false then
		acc[len(acc) + 1] = 'f'
	elseif object == nil then
		acc[len(acc) + 1] = 'n'
	elseif object ~= object then
		if sub(''..object,1,1) == '-' then
			acc[len(acc) + 1] = 'N'
		else
			acc[len(acc) + 1] = 'Q'
		end
	elseif object == huge then
		acc[len(acc) + 1] = 'I'
	elseif object == -huge then
		acc[len(acc) + 1] = 'i'
	else
		local t = type(object)
		if not dump_type[t] then
			error('cannot dump type ' .. t)
		end
		return dump_type[t](object, nmemo, memo, acc)
	end
	return nmemo
end

function M.dumps(object)
	local nmemo = 0
	local memo = {}
	local acc = {}
	dump_object(object, nmemo, memo, acc)
	return concat(acc)
end

local function invalid(i)
	error('invalid input at position ' .. i)
end

local nonzero_digit = {['1'] = true, ['2'] = true, ['3'] = true, ['4'] = true, ['5'] = true, ['6'] = true, ['7'] = true, ['8'] = true, ['9'] = true}
local is_digit = {['0'] = true, ['1'] = true, ['2'] = true, ['3'] = true, ['4'] = true, ['5'] = true, ['6'] = true, ['7'] = true, ['8'] = true, ['9'] = true}
local function expect_number(string, start)
	local i = start
	local head = sub(string, i, i)
	if head == '-' then
		i = i + 1
		head = sub(string, i, i)
	end
	if nonzero_digit[head] then
		repeat
			i = i + 1
			head = sub(string, i, i)
		until not is_digit[head]
	elseif head == '0' then
		i = i + 1
		head = sub(string, i, i)
	else
		invalid(i)
	end
	if head == '.' then
		local oldi = i
		repeat
			i = i + 1
			head = sub(string, i, i)
		until not is_digit[head]
		if i == oldi + 1 then
			invalid(i)
		end
	end
	if head == 'e' or head == 'E' then
		i = i + 1
		head = sub(string, i, i)
		if head == '+' or head == '-' then
			i = i + 1
			head = sub(string, i, i)
		end
		if not is_digit[head] then
			invalid(i)
		end
		repeat
			i = i + 1
			head = sub(string, i, i)
		until not is_digit[head]
	end
	return tonumber(sub(string, start, i - 1)), i
end

local expect_object_head = {
	t = function(string, i) return true, i end,
	f = function(string, i) return false, i end,
	n = function(string, i) return nil, i end,
	Q = function(string, i) return -(0/0), i end,
	N = function(string, i) return 0/0, i end,
	I = function(string, i) return 1/0, i end,
	i = function(string, i) return -1/0, i end,
	['"'] = function(string, i)
		local nexti = i - 1
		repeat
			if string_find(string, '"', nexti + 1, true) == nil then
				-- print("Unmatched quotes in string:", 'plöö', sub(string, nexti + 1), 'plöö')
				error(string)
			end
			local nexta = nexti
			nexti = string_find(string, '"', nexti + 1, true) + 1
			--print("Q1: ", "'"..sub(string, nexta+1, nexti).."'")
			--print("Q2: ", sub(string, nexti, nexti))
			--print("Q3: ", sub(string, nexti + 1))
		until sub(string, nexti, nexti) ~= '"'
		return gsub(sub(string, i, nexti - 2), '""', '"'), nexti
	end,
	['0'] = function(string, i)
		return expect_number(string, i - 1)
	end,
	['{'] = function(string, i, tables)
		local nt, k, v = {}
		local j = 1
		tables[len(tables) + 1] = nt
		if sub(string, i, i) == '}' then
			return nt, i + 1
		end
		while true do
			k, i = expect_object(string, i, tables)
			if sub(string, i, i) == ':' then
				v, i = expect_object(string, i + 1, tables)
				nt[k] = v
			else
				nt[j] = k
				j = j + 1
			end
			local head = sub(string, i, i)
			if head == ',' then
				i = i + 1
			elseif head == '}' then
				return nt, i + 1
			else
				invalid(i)
			end
		end
	end,
    --[[
	['@'] = function(string, i, tables)
		local match = string:match('^%d+', i)
		local ref = tonumber(match)
		if tables[ref] then
			return tables[ref], i + len(match)
		end
		invalid(i)
	end,
    ]]
}
expect_object_head['1'] = expect_object_head['0']
expect_object_head['2'] = expect_object_head['0']
expect_object_head['3'] = expect_object_head['0']
expect_object_head['4'] = expect_object_head['0']
expect_object_head['5'] = expect_object_head['0']
expect_object_head['6'] = expect_object_head['0']
expect_object_head['7'] = expect_object_head['0']
expect_object_head['8'] = expect_object_head['0']
expect_object_head['9'] = expect_object_head['0']
expect_object_head['-'] = expect_object_head['0']
expect_object_head['.'] = expect_object_head['0']

expect_object = function(string, i, tables)
	local head = sub(string, i, i)
	if expect_object_head[head] then
		return expect_object_head[head](string, i + 1, tables)
	end
	invalid(i)
end

function M.loads(string, maxsize)
	print("M.loads:", len(string), maxsize)
	if len(string) > (maxsize or 10000) then
		error 'input too large'
	end
	return (expect_object(string, 1, {}))
end

-- Tests
local tbl = {1/0, 0/0, -(1/0), -(0/0), huge, -huge, true, false, nil, "example string", 123.345, {"key1", "key2", 3, 4, 5, 6, 7, 8, 9, 10}, {a = "b", c = "d"}, {1, 2, 3}, {1, 2, {3, 4}}, {1, 2, {3, 4}, a = "b", c = "d"}, {}}
local data = M.loads(M.dumps(tbl))
-- print(M.dumps(tbl))
-- print(M.dumps(data))
print("smallfolk works:", M.dumps(tbl) == M.dumps(data))

return M
