--[[
    Shared helpers for AIO.lua: vararg counting, pcall wrapper, block dispatch rules.
]]

local M = {}

function M.extract_n(...)
    return select("#", ...), ...
end

function M.make_pcall(opts)
    local extract_n = M.extract_n
    local unpack_fn = opts.unpack
    local pcall_fn = opts.pcall
    local xpcall_fn = opts.xpcall

    return function(f, ...)
        assert(type(f) == "function")
        if not opts.enable_pcall then
            return f(...)
        end
        local data
        if opts.server and opts.enable_traceback and opts.debug_traceback then
            data = { extract_n(xpcall_fn(f, opts.debug_traceback, ...)) }
        else
            data = { extract_n(pcall_fn(f, ...)) }
        end
        if not data[2] then
            opts.on_error(data[3])
            return
        end
        return unpack_fn(data, 3, data[1] + 1)
    end
end

-- Returns handle_block(player, data, skipstored) and a table holding queued pre-init blocks.
function M.make_handle_block(opts)
    local preinitblocks = {}
    local unpack_fn = opts.unpack
    local client_state = opts.client_state
    local block_handles = opts.block_handlers
    local debug_fn = opts.debug

    local function handle_block(player, data, skipstored)
        local handle_name = data[2]
        assert(handle_name, "Invalid handle, no handle name")

        if client_state and client_state.AIO_VERSION_MISMATCH and not (handle_name == "AIO" and data[3] == "Init") then
            return
        end

        if client_state and not client_state.AIO_INITED and (handle_name ~= "AIO" or data[3] ~= "Init") then
            preinitblocks[#preinitblocks + 1] = data
            debug_fn("Received block before Init:", handle_name, data[1], data[3])
            return
        end

        local handledata = block_handles[handle_name]
        if not handledata then
            error("Unknown AIO block handle: '" .. tostring(handle_name) .. "'")
        end

        if opts.server and data[1] > opts.max_block_args then
            error("Received AIO block with over " .. opts.max_block_args .. " arguments. Try using tables instead")
        end
        handledata(player, unpack_fn(data, 3, data[1] + 2))

        if not skipstored and client_state and client_state.AIO_INITED and handle_name == "AIO" and data[3] == "Init" then
            for i = 1, #preinitblocks do
                handle_block(player, preinitblocks[i], true)
                preinitblocks[i] = nil
            end
        end
    end

    return handle_block
end

return M
