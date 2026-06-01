#!/bin/sh
# Same file list as .github/workflows/ci.yml (for local use on Unix).
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
  tests/test_path_legacy.lua tests/test_reassembler.lua tests/test_lualzw.lua \
  tests/test_aio_rpc.lua tests/test_aio_core.lua \
  tests/wow_stub.lua tests/aio_integration_util.lua \
  tests/test_aio_integration_server.lua tests/test_aio_integration_client.lua
luacheck --config .luacheckrc \
  AIO_Server/aio_server_pipeline.lua AIO_Client/aio_client_ui.lua
