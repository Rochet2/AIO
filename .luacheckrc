std = "lua51"

exclude_files = {
    "AIO_Server/Dep_*",
    "AIO_Client/Dep_*",
    "AIO_Server/lualzw-zeros/**",
    "AIO_Client/lualzw-zeros/**",
    "Examples/**",
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
    "require",
    "package",
    "debug",
}

files["AIO_Server/aio_util.lua"] = {}
files["AIO_Client/aio_util.lua"] = {}

files["AIO_Server/queue.lua"] = {}
files["AIO_Client/queue.lua"] = {}

files["AIO_Server/aio_framing.lua"] = {}
files["AIO_Client/aio_framing.lua"] = {}

files["AIO_Server/aio_reassembler.lua"] = {}
files["AIO_Client/aio_reassembler.lua"] = {}

files["AIO_Server/aio_rpc.lua"] = {}
files["AIO_Client/aio_rpc.lua"] = {}

files["AIO_Server/aio_core.lua"] = {
    ignore = {"2.", "3.", "4.", "5.", "6."},
}
files["AIO_Client/aio_core.lua"] = {
    ignore = {"2.", "3.", "4.", "5.", "6."},
}

files["AIO_Server/aio_server_pipeline.lua"] = {
    ignore = {"1.", "2.", "3.", "4.", "5.", "6."},
}

files["AIO_Client/aio_client_ui.lua"] = {
    ignore = {"1.", "2.", "3.", "4.", "5.", "6."},
}

files["AIO_Server/AIO.lua"] = {
    -- Syntax + unused locals; 3.x-6.x deferred (WoW globals, style).
    ignore = {"113", "3.", "4.", "5.", "6."},
}

files["AIO_Client/AIO.lua"] = {
    ignore = {"113", "3.", "4.", "5.", "6."},
}

files["tests/run.lua"] = {
    globals = {"dofile", "os"},
}

files["tests/test_aio_core.lua"] = {
    ignore = {"113"},
}

files["tests/test_aio_rpc.lua"] = {
    ignore = {"113"},
}
