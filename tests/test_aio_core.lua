local unpack = assert(_G.unpack)
local aio_core = require("aio_core")

test("aio_core extract_n", function()
    local n, a, b = aio_core.extract_n(true, "x", 3)
    assert_eq(n, 3)
    assert_eq(a, true)
    assert_eq(b, "x")
end)

test("aio_core pcall returns values on success", function()
    local fn = aio_core.make_pcall({
        unpack = unpack,
        pcall = pcall,
        xpcall = xpcall,
        enable_pcall = true,
        server = true,
        enable_traceback = false,
        on_error = function()
            error("on_error should not run")
        end,
    })
    local sum = fn(function(a, b)
        return a + b
    end, 2, 5)
    assert_eq(sum, 7)
end)

test("aio_core pcall returns nil on failure", function()
    local err_msg
    local fn = aio_core.make_pcall({
        unpack = unpack,
        pcall = pcall,
        xpcall = xpcall,
        enable_pcall = true,
        server = true,
        enable_traceback = false,
        on_error = function(err)
            err_msg = err
        end,
    })
    local result = fn(function()
        error("boom")
    end)
    assert_eq(result, nil)
    assert_true(err_msg and err_msg:find("boom", 1, true))
end)

test("aio_core pcall disabled calls through", function()
    local fn = aio_core.make_pcall({
        unpack = unpack,
        pcall = pcall,
        xpcall = xpcall,
        enable_pcall = false,
        server = false,
        enable_traceback = false,
        on_error = function()
            error("on_error should not run")
        end,
    })
    assert_eq(fn(function()
        return 99
    end), 99)
end)

test("aio_core handle_block queues pre-init messages", function()
    local seen = {}
    local client_state = { AIO_INITED = false, AIO_VERSION_MISMATCH = false }
    local handle_block = aio_core.make_handle_block({
        unpack = unpack,
        client_state = client_state,
        block_handlers = {
            Ping = function(_, msg)
                seen[#seen + 1] = msg
            end,
            AIO = function() end,
        },
        server = false,
        max_block_args = 15,
        debug = function() end,
    })

    handle_block(1, { 1, "Ping", "early" })
    assert_eq(#seen, 0)

    client_state.AIO_INITED = true
    handle_block(1, { 1, "AIO", "Init" })
    assert_eq(#seen, 1)
    assert_eq(seen[1], "early")
end)

test("aio_core handle_block ignores when version mismatch", function()
    local seen = {}
    local client_state = { AIO_INITED = true, AIO_VERSION_MISMATCH = true }
    local handle_block = aio_core.make_handle_block({
        unpack = unpack,
        client_state = client_state,
        block_handlers = {
            Ping = function(_, msg)
                seen[#seen + 1] = msg
            end,
        },
        server = false,
        max_block_args = 15,
        debug = function() end,
    })

    handle_block(1, { 1, "Ping", "blocked" })
    assert_eq(#seen, 0)
end)

test("aio_core handle_block server max args", function()
    local handle_block = aio_core.make_handle_block({
        unpack = unpack,
        client_state = nil,
        block_handlers = { H = function() end },
        server = true,
        max_block_args = 2,
        debug = function() end,
    })
    local ok = pcall(handle_block, 1, { 3, "H", 1, 2, 3 })
    assert_true(not ok)
end)
