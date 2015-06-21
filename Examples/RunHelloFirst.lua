local AIO = AIO or require("AIO")

-- All addons are run on client side in the order they are added with
-- AIO.AddAddon or AIO.AddAddonCode. If you want to  control the order, you can
-- simply require the file(s) to load first on the server side
if AIO.IsServer() then
    require("HelloWorld")
end

-- or like this
if AIO.AddAddon() then
    require("HelloWorld")
    return
end

print("'Hello Client' should be above this message, not below")

-- You can also control the order by adding the addons "manually" by using
-- AIO.AddAddon with the custom path or AIO.AddAddonCode
