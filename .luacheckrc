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

files["AIO_Server/aio_core.lua"] = {}
files["AIO_Client/aio_core.lua"] = {}

files["AIO_Server/aio_server_pipeline.lua"] = {
    ignore = {"1.", "2.", "3.", "4.", "5.", "6."},
}

files["AIO_Client/aio_client_ui.lua"] = {
    ignore = {"1.", "2.", "3.", "4.", "5.", "6."},
}

files["AIO_Server/AIO.lua"] = {
    -- WoW/Eluna globals (3.x) and style (4–6) deferred; syntax + unused locals enforced.
    ignore = {"3.", "4.", "5.", "6."},
    globals = {
        "AIO_sv",
        "AIO_sv_char",
        "AIO_sv_Addons",
        "AIO_FRAMEPOSITIONS",
        "AIO_FRAMEPOSITIONSCHAR",
        "AIO_RESET",
        "PrintInfo",
        "message",
        "WorldFrame",
        "GetBuildInfo",
        "RegisterAddonMessagePrefix",
        "SLASH_AIO1",
        "SlashCmdList",
    },
}

files["AIO_Client/AIO.lua"] = {
    ignore = {"3.", "4.", "5.", "6."},
    globals = {
        "AIO_sv",
        "AIO_sv_char",
        "AIO_sv_Addons",
        "AIO_FRAMEPOSITIONS",
        "AIO_FRAMEPOSITIONSCHAR",
        "AIO_RESET",
        "PrintInfo",
        "message",
        "WorldFrame",
        "GetBuildInfo",
        "RegisterAddonMessagePrefix",
        "SLASH_AIO1",
        "SlashCmdList",
    },
}

files["tests/run.lua"] = {
    globals = {"dofile", "os"},
}
