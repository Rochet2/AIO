-- luacheck: ignore
local u = dofile((debug.getinfo(1, "S").source:match("@?(.*[/\\])") or "./") .. "aio_integration_util.lua")
local wow_stub = u.wow_stub

test("integration server loads AIO.lua", function()
    wow_stub.reset_log()
    local AIO = u.load_aio_from("AIO_Server/", wow_stub.install_server_deps, wow_stub.install_server)
    assert_true(AIO.IsServer())
    assert_true(AIO.IsMainState())
    assert_eq(AIO.GetVersion(), 1.76)
    assert_true(wow_stub.server_events[30] ~= nil)
end)

test("integration server AIO_Send delivers short addon message", function()
    wow_stub.reset_log()
    local AIO = u.load_aio_from("AIO_Server/", wow_stub.install_server_deps, wow_stub.install_server)
    local player = wow_stub.make_player(42)
    AIO.Msg():Add("Ping", "hello"):Send(player)
    local msg = u.last_addon_msg("server_to_client")
    assert_true(msg ~= nil)
    assert_eq(msg.guid, 42)
    assert_true(#msg.msg > 0)
end)

test("integration server pipeline AddAddonCode and Init push", function()
    wow_stub.reset_log()
    local AIO = u.load_aio_from("AIO_Server/", wow_stub.install_server_deps, wow_stub.install_server)
    local _, client_prefix = u.aio_prefixes()
    local player = wow_stub.make_player(7)
    AIO.AddAddonCode("Demo", "AIO_DemoLoaded = true")
    wow_stub.addon_messages = {}

    local init_wire = u.short_wire(AIO.Msg():Add("AIO", "Init", 1.76, {}):ToString())
    wow_stub.fire_server_addon_msg(player, client_prefix, init_wire, player)

    local out = u.last_addon_msg("server_to_client")
    assert_true(out ~= nil, "server should reply to Init")
    assert_true(#out.msg > 0)
end)

test("integration server slash aio help", function()
    wow_stub.reset_log()
    local AIO = u.load_aio_from("AIO_Server/", wow_stub.install_server_deps, wow_stub.install_server)
    local player = wow_stub.make_player(1)
    wow_stub.fire_player_command(player, "aio help")
    assert_true(#wow_stub.print_log > 0)
end)
