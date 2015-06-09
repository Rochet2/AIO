local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    -- we are on server
    print("Hello Server")
else
    -- we are on client
    print("Hello Client")
end
