# Changelog

All notable changes to the AIO core (server/client `AIO.lua` and shared modules) are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.76] - 2026-05-31

### Added

- Shared modules: `aio_framing`, `aio_reassembler`, `aio_rpc`, `aio_util` (server and client copies kept in sync; CI enforces `diff`).
- Asymmetric modules: `aio_server_pipeline` (server), `aio_client_ui` (client); `AIO.lua` delegates to them while staying identical on both sides.
- Shared `aio_core` module (pcall wrapper, block dispatch); unit tests; CI Luacheck on helpers, side modules, and `AIO.lua` (categories 1–6 ignored for WoW/Eluna globals — effectively syntax-oriented until tightened).
- Pure Lua test suite under `tests/` and GitHub Actions CI (unit tests, Luacheck, module sync checks including vendored lualzw and Smallfolk).
- `SECURITY.md`, `DEPENDENCIES.md`, `CHANGELOG.md`, and `FUTURE_WORK.md`.
- `scripts/ci_luacheck.sh` (CI/Unix) and `scripts/run_luacheck_local.lua` (Windows without luarocks).

### Changed

- **Version** `AIO_VERSION` is now `1.76` (was `1.75`). Server and client must match; clients show a mismatch warning until versions align.
- Vendored **lualzw** upgraded to [v1.1.0](https://github.com/Rochet2/lualzw/releases/tag/v1.1.0) with `skip = { [0] = true }` for the former `zeros` wire format.
- `AIO_FORCE_RELOAD_ON_STARTUP` default is **`true`** (reload-all on server startup is opt-out).
- On client version mismatch, Init no longer permanently disables message handling; the client keeps retrying Init instead of going inert.
- Examples: KaevStatTest server messages translated to English.

### Fixed

- `Queue.clear` in both `queue.lua` files (wrong variable names; would error if called).
- Server incomplete-message cache TTL: `AIO_GetTime` now uses milliseconds (`os.time() * 1000`), matching `AIO_MSG_CACHE_TIME` (was seconds vs ms, so expiry effectively took hours).
- Per-peer `stored` byte accounting: message removal/completion now decrements the counter (previously only the eviction path did).
- Long-message reassembly no longer uses `#` on sparse `parts` tables (hole-safe `all_parts_present`).
- `debug.sethook` cleared in timeout/`pcall` cleanup paths so hooks do not linger after timed-out code.
- Windows path handling for addon basenames (`aio_util.basename`).
- Related client cache / init edge cases from the 1.76 maintenance pass.

### Upgrade notes

1. Deploy **both** `AIO_Server` and `AIO_Client` together so `AIO_VERSION` matches.
2. The lualzw v1.1.0 upgrade keeps the former `zeros` wire format (`skip = { [0] = true }`); existing client caches of compressed addons remain valid—no `/aio reset` required for compatibility.
3. Client `.toc` load order must list the new modules before `AIO.lua` (see `DEPENDENCIES.md`).

## [1.75] and earlier

See git history and [releases](https://github.com/Rochet2/AIO/releases) before this changelog was introduced.
