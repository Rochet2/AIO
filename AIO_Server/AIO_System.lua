local AIO = require("AIO")

-- use simple pattern to remove comments and whitespace
local simplestrip = true
local addons = {
    "Hello world.lua",
    "GOMoveFunctions.lua",
    "GOMoveScripts.lua",
}

local message = AIO.Msg():Add("Addons")
for k, path in ipairs(addons) do
    local code = AIO.ReadFile("AIO_addons/"..path)
    if simplestrip then
        code = code:gsub("[%s\n]*%-%-%[(=*)%[.-%]%1%][%s\n]*", "\n"):gsub("[%s\n]*%-%-.-\n", "\n"):gsub("^[%s\n]*(.-)[%s\n]*$", "%1")
    end
    message:AddVal(code)
end
AIO.AddInitMsg(message)
