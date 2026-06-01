# Changelog

All notable changes to the AIO core (server/client `AIO.lua` and shared modules) are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.76] - 2026-05-31

### Added

- Shared modules: `aio_framing`, `aio_reassembler`, `aio_rpc`, `aio_util` (server and client copies kept in sync; CI enforces `diff`).
- Pure Lua test suite under `tests/` and GitHub Actions CI (unit tests, Luacheck, module sync checks).
- `SECURITY.md`, `DEPENDENCIES.md`, `CHANGELOG.md`, and `FUTURE_WORK.md`.
- `scripts/run_luacheck_local.lua` for running Luacheck on Windows without a full luarocks install.

### Changed

- **Version** `AIO_VERSION` is now `1.76` (was `1.75`). Server and client must match; clients show a mismatch warning until versions align.
- Vendored **lualzw** upgraded to [v1.1.0](https://github.com/Rochet2/lualzw/releases/tag/v1.1.0) with `skip = { [0] = true }` for the former `zeros` wire format.
- `AIO_FORCE_RELOAD_ON_STARTUP` default is **`true`** (reload-all on server startup is opt-out).
- Examples: KaevStatTest server messages translated to English.

### Fixed

- `Queue.clear` in both `queue.lua` files (wrong variable names; would error if called).
- Client cache / version handling and related edge cases from the 1.76 maintenance pass.
- Windows path handling for addon basenames (`aio_util.basename`).

### Upgrade notes

1. Deploy **both** `AIO_Server` and `AIO_Client` together so `AIO_VERSION` matches.
2. After the lualzw upgrade, players with a stale client cache may need **`/aio reset`** (or your usual cache clear) if compressed addons fail to load.
3. Client `.toc` load order must list the new modules before `AIO.lua` (see `DEPENDENCIES.md`).

## [1.75] and earlier

See git history and [releases](https://github.com/Rochet2/AIO/releases) before this changelog was introduced.
