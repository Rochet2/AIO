local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    -- we are on server
    AIO.print("Hello Server")
else
    -- we are on client
    AIO.print("Hello Client")
end
