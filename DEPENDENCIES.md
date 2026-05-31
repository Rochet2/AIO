# Dependencies

AIO vendors its dependencies inside `AIO_Server/` and `AIO_Client/`. You do not need to install them separately for normal use.

## First-party modules

| Module | Server path | Client path | Notes |
|--------|-------------|-------------|-------|
| AIO core | `AIO_Server/AIO.lua` | `AIO_Client/AIO.lua` | Must stay identical; CI checks with `diff` |
| aio_util | `AIO_Server/aio_util.lua` | `AIO_Client/aio_util.lua` | Shared helpers (basename, cache accounting); CI checks with `diff` |
| Queue | `AIO_Server/queue.lua` | `AIO_Client/queue.lua` | Based on PIL 11.4, with AIO modifications |
| Smallfolk | `AIO_Server/Dep_Smallfolk/` | `AIO_Client/Dep_Smallfolk/` | Wire serialization |
| lualzw | `AIO_Server/lualzw-zeros/` | `AIO_Client/lualzw-zeros/` | [Rochet2/lualzw](https://github.com/Rochet2/lualzw) **v1.1.0** (2026-05-31), configured with `skip = { [0] = true }` for the former `zeros` branch wire format |

## Server-only dependencies

| Module | Path | Upstream | License |
|--------|------|----------|---------|
| crc32lua | `AIO_Server/Dep_crc32lua/` | [davidm/lua-digest-crc32lua](https://github.com/davidm/lua-digest-crc32lua) | See `COPYRIGHT` |
| LuaSrcDiet | `AIO_Server/Dep_LuaSrcDiet/` | [LuaSrcDiet](http://luasrcdiet.luaforge.net/) | See `COPYRIGHT`, `COPYRIGHT_Lua51` |

## Client-only dependencies

| Module | Path | Upstream | License |
|--------|------|----------|---------|
| LibStub | `AIO_Client/Dep_LibWindow-1.1/LibStub.lua` | [LibStub](https://www.wowace.com/projects/libstub) | Public domain |
| LibWindow-1.1 | `AIO_Client/Dep_LibWindow-1.1/LibWindow-1.1/` | [LibWindow-1.1 r12](https://www.wowace.com/projects/libwindow-1-1) | See addon TOC |

LibWindow is loaded for `AIO.SavePosition()` frame persistence on the client.

## WoW addon load order

The client `.toc` file lists Lua files in load order. Each file must be loaded before anything that `require()`s it:

```
Dep_LibWindow-1.1\LibStub.lua
Dep_LibWindow-1.1\LibWindow-1.1\LibWindow-1.1.lua
Dep_Smallfolk\smallfolk.lua      → require("smallfolk")
lualzw-zeros\lualzw.lua          → require("lualzw")
queue.lua                        → require("queue")
aio_util.lua                     → require("aio_util")
AIO.lua                          → require("AIO") in other addons; loads deps above
```

Server-side Eluna resolves `require("smallfolk")`, `require("lualzw")`, `require("queue")`, `require("LuaSrcDiet")`, and `require("crc32lua")` from paths under `lua_scripts/` (same folder layout as `AIO_Server/`).

## Upgrading vendored libraries

1. Replace the vendored folder with the new upstream version.
2. Re-test addon push, client cache, compression, and message round-trips.
3. Run `lua tests/run.lua` and CI locally if possible.
4. Update this file with the new upstream URL or version if known.

No version pins are recorded in-repo today; note the commit or release you vendor when upgrading.

## Development / CI tools (not shipped to players)

| Tool | Purpose |
|------|---------|
| [Luacheck](https://github.com/luarocks/luacheck) | Static analysis (see `.luacheckrc`) |
| Lua 5.1 | Runs `tests/run.lua` outside WoW |

See `.github/workflows/ci.yml` for the CI setup.
