#!/bin/sh
# Single source of truth for Luacheck paths (CI + local Unix).
# Keep in sync with scripts/run_luacheck_local.lua.
set -e
luacheck --config .luacheckrc \
  AIO_Server/queue.lua AIO_Client/queue.lua \
  AIO_Server/aio_util.lua AIO_Client/aio_util.lua \
  AIO_Server/aio_framing.lua AIO_Client/aio_framing.lua \
  AIO_Server/aio_reassembler.lua AIO_Client/aio_reassembler.lua \
  AIO_Server/aio_rpc.lua AIO_Client/aio_rpc.lua \
  AIO_Server/aio_core.lua AIO_Client/aio_core.lua \
  tests/run.lua tests/test_queue.lua tests/test_smallfolk.lua \
  tests/test_framing.lua tests/test_util.lua tests/test_stored.lua \
  tests/test_reassembler.lua tests/test_lualzw.lua \
  tests/test_aio_rpc.lua tests/test_aio_core.lua \
  tests/lua_compat.lua tests/wow_stub.lua tests/aio_integration_util.lua \
  tests/test_aio_integration_server.lua tests/test_aio_integration_client.lua

# Syntax-oriented checks (categories 1-6 ignored in .luacheckrc).
luacheck --config .luacheckrc \
  AIO_Server/aio_server_pipeline.lua AIO_Client/aio_client_ui.lua \
  AIO_Server/AIO.lua AIO_Client/AIO.lua
