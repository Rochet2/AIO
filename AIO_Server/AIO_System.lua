local AIO = require("AIO")

local addons = {
    "Hello world.lua",
    "GOMoveFunctions.lua",
    "GOMoveScripts.lua",
}

for k, path in ipairs(addons) do
    local code = AIO.ReadFile("AIO_addons/"..path)
    AIO.AddAddon(path, code)
end
