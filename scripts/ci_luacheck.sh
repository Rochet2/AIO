#!/bin/sh
set -e
files="
AIO_Server/queue.lua
AIO_Client/queue.lua
AIO_Server/aio_util.lua
AIO_Client/aio_util.lua
AIO_Server/aio_framing.lua
AIO_Client/aio_framing.lua
AIO_Server/aio_reassembler.lua
AIO_Client/aio_reassembler.lua
AIO_Server/aio_rpc.lua
AIO_Client/aio_rpc.lua
AIO_Server/aio_core.lua
AIO_Client/aio_core.lua
AIO_Server/aio_server_pipeline.lua
AIO_Client/aio_client_ui.lua
AIO_Server/AIO.lua
AIO_Client/AIO.lua
tests/run.lua
tests/test_queue.lua
tests/test_smallfolk.lua
tests/test_framing.lua
tests/test_util.lua
tests/test_stored.lua
tests/test_path_legacy.lua
tests/test_reassembler.lua
tests/test_lualzw.lua
tests/test_aio_rpc.lua
tests/test_aio_core.lua
"
for f in $files; do
    echo "==> luacheck $f"
    luacheck --config .luacheckrc --codes "$f"
done
