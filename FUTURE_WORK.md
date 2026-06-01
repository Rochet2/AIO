# Future work

Ideas and larger tasks that are **out of scope** for the 1.76 maintenance release but worth tracking. Not a commitment to implement.

## Product / protocol features

### Multi-file addons ([PR #14](https://github.com/Rochet2/AIO/pull/14) direction)

- Today: one Lua blob per addon name; `AddAddon` / `AddAddonCode` and client cache keys assume a single string per addon.
- Desired: multiple files per logical addon, optional namespaces, less boilerplate than manual `require` strings in one blob.
- **Backwards compatibility** is the hard part. Reasonable approaches:
  - **Dual protocol**: old clients keep single-blob cache keys; new clients understand a manifest (file list + hashes) while server can still serve legacy blobs.
  - **Optional namespace layer** on top of current API without changing wire cache format (Rochet2-style lighter API only).
- Do **not** merge PR #14 as-is: it changes cache keys and breaks existing `AddAddon` / `AddAddonCode` callers.

### Further split of `AIO.lua`

- **Done (1.76):** server addon pipeline (`aio_server_pipeline.lua`) and client cache/UI (`aio_client_ui.lua`) extracted; `AIO.lua` stays identical on both sides and delegates with `require`.
- Remaining in `AIO.lua`: shared config, messaging, RPC wiring, `AIO_HandleBlock`, slash commands, handler registration.

### Eluna / C++ CAIO

- Document or test against [SaiFi0102’s CAIO fork](https://github.com/SaiFi0102/TrinityCore/blob/CAIO-3.3.5/CAIO_README.md) if users rely on non-Eluna paths.

## Repository setup

| Improvement | Why |
|-------------|-----|
| **GitHub Releases** tied to `AIO_VERSION` | Tag `v1.76` with `CHANGELOG.md` excerpt so server owners know what changed. |
| **PR / issue templates** | `.github/PULL_REQUEST_TEMPLATE.md` reminding contributors to sync server/client copies and run `tests/run.lua`. |
| **Dependabot or yearly vendored audit** | Remind to bump Smallfolk, lualzw, LuaSrcDiet; record versions in `DEPENDENCIES.md`. |
| **Optional: pre-commit hook** | Run `tests/run.lua` + `scripts/run_luacheck_local.lua` (or `luacheck` on Linux) before push. |
| **Squash / linear history on `master`** | Many small CI-fix commits on feature branches; squash on merge for readable `master`. |
| **`.github/workflows` on all branches** | CI already runs on PRs; consider `workflow_dispatch` for manual re-runs. |

## Test coverage

### Covered today (pure Lua, no WoW)

- `queue`, Smallfolk, `aio_framing`, `aio_util`, `aio_reassembler`, lualzw, `aio_rpc`, `aio_core` (pcall + `HandleBlock` rules; see `tests/`).

### Gaps (high value)

| Area | Notes |
|------|--------|
| **`AIO.lua` integration** | Init/version mismatch, cache hit/miss, `AddAddon` pipeline—needs heavy mocking of WoW/Eluna globals or in-game tests. |
| **Server-only paths** | LuaSrcDiet obfuscation, crc32, compression flags—could unit-test with fixtures if extracted. |
| **Client-only paths** | SavedVariables, `/aio` commands, `ForceReload` / `ForceReset`—mostly UI; manual or headless WoW. |
| **Fuzz / property tests** | Random round-trips through framing + reassembler + Smallfolk at scale. |
| **Regression fixtures** | Golden compressed addon blobs per lualzw version so upgrades cannot silently break cache. |

### Not worth chasing soon

- Full `AIO.lua` load tests without a WoW mock harness (pipeline/UI still side-effect heavy).
- Linting `Examples/` or vendored `Dep_*` trees.

## Luacheck on `AIO.lua`

- CI now runs Luacheck on `AIO.lua` with **syntax + unused locals (1.x, 2.x)**; globals (3.x) and style (4–6) still ignored until WoW/Eluna std is expanded.
- Next: add remaining Eluna/WoW globals and enable 3.x; then line length (611).

## Documentation

- Per-addon author guide: minimal server + client example using 1.76 module layout.
- Troubleshooting: version mismatch, cache reset after lualzw upgrade, `.toc` order mistakes.
