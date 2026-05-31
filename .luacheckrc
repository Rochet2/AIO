std = "lua51"

exclude_files = {
    "AIO_Server/Dep_*",
    "AIO_Client/Dep_*",
    "AIO_Server/lualzw-zeros/**",
    "AIO_Client/lualzw-zeros/**",
}

max_line_length = 120

globals = {
    "AIO",
    "LibStub",
    "GetLuaEngine",
    "GetTime",
    "GetStateMapId",
    "RegisterServerEvent",
    "RegisterPlayerEvent",
    "CreateFrame",
    "CreateLuaEvent",
    "GetPlayersInWorld",
    "SendAddonMessage",
    "UnitName",
    "ReloadUI",
    "SlashCmdList",
    "_ERRORMESSAGE",
    "Smallfolk",
    "NewQueue",
    "lualzw",
    "Ping",
    "test",
    "assert_eq",
    "assert_true",
}

files["AIO_Server/aio_util.lua"] = {}
files["AIO_Client/aio_util.lua"] = {}

files["AIO_Server/AIO.lua"] = {
    -- Monolith with many Eluna/WoW globals; focus on syntax and obvious issues only.
    ignore = {"1", "2", "3", "4", "5", "6"},
}

files["AIO_Client/AIO.lua"] = {
    ignore = {"1", "2", "3", "4", "5", "6"},
}

files["Examples/PingPong.lua"] = {
    globals = {"AIO", "Ping", "time"},
}

files["Examples/HelloWorld.lua"] = {
    globals = {"AIO"},
}

files["Examples/PersistentVariables_Client.lua"] = {
    globals = {"AIO"},
}

files["Examples/RunHelloFirst.lua"] = {
    globals = {"AIO"},
}

files["Examples/TestWindow/ExampleClient.lua"] = {
    globals = {"AIO"},
}

files["Examples/TestWindow/ExampleServer.lua"] = {
    globals = {"AIO", "RegisterPlayerEvent", "GetPlayersInWorld"},
}

files["Examples/KaevStatTest/Server.lua"] = {
    globals = {"AIO", "RegisterPlayerEvent", "GetPlayersInWorld"},
}

files["Examples/KaevStatTest/Client.lua"] = {
    globals = {"AIO"},
}
