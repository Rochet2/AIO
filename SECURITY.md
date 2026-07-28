# Security

AIO is a server–client messaging layer for Eluna and WoW. This document describes the threat model, built-in protections, and what you must enforce in your own handler code.

## Threat model

| Direction | Trust level | What happens |
|-----------|-------------|--------------|
| Server → client (addon code) | Server is fully trusted | Addon Lua is compressed, optionally obfuscated, and executed on the client with `loadstring`. This is equivalent to remote code execution by design. |
| Server → client (handler messages) | Server is trusted | Deserialized data is passed to registered handlers. |
| Client → server (handler messages) | Client is **not** trusted | Data is deserialized only (no `loadstring`). Handlers must validate every field before use. |

Anyone who can modify server scripts can push arbitrary code to connected clients. Treat server-side AIO scripts like production server code with full review and access control.

## Built-in protections

AIO includes several safeguards (see `AIO.lua` config block):

- **Safe deserialization** — Smallfolk does not use `loadstring` when loading messages from the wire.
- **pcall wrapping** — Handler execution is wrapped by default (`AIO_ENABLE_PCALL`).
- **Instruction timeout** — Server-side message handling can abort runaway code (`AIO_TIMEOUT_INSTRUCTIONCOUNT`).
- **Message cache limits** — Per-player caps on incomplete and stored message data (`AIO_MSG_CACHE_SPACE`, `AIO_MSG_CACHE_TIME`).
- **Init rate limiting** — Limits how often full addon lists can be requested (`AIO_UI_INIT_DELAY`).
- **Version check** — Client and server must share the same `AIO_VERSION`.
- **Addon channel filter** — Server rejects addon messages with wrong prefix, sender/target mismatch, or length ≥ 510.

These reduce abuse and accidental hangs but do **not** replace input validation in your handlers.

## Your responsibilities

### Validate all client input

Never trust types or ranges from the client. Example checks:

```lua
function MyHandlers.DoThing(player, statId, amount)
    if type(statId) ~= "number" or statId < 1 or statId > 5 then
        return
    end
    if type(amount) ~= "number" or amount ~= math.floor(amount) or amount < 1 or amount > 100 then
        return
    end
    -- safe to use statId and amount
end
```

See `Examples/KaevStatTest/Server.lua` for a fuller pattern (bounds checks, nil guards, combat gates).

Avoid copying `Examples/PingPong.lua` as a server handler template — it echoes client data without validation.

### Treat server addons as signed code

- Review all code passed to `AIO.AddAddon()` / `AIO.AddAddonCode()`.
- Disable obfuscation (`AIO_CODE_OBFUSCATE = false`) while debugging so stack traces stay useful.
- Do not load untrusted third-party server scripts into AIO without review.

### Production settings

Recommended server defaults for live realms:

| Setting | Recommended |
|---------|-------------|
| `AIO_ENABLE_PCALL` | `true` |
| `AIO_ENABLE_DEBUG_MSGS` | `false` |
| `AIO_ENABLE_MSGPRINT` | `false` |
| `AIO_TIMEOUT_INSTRUCTIONCOUNT` | non-zero (default `1e8`) |
| `AIO_MSG_CACHE_SPACE` | tuned to your traffic |
| `AIO_FORCE_RELOAD_ON_STARTUP` | `true` by default; set to `false` if you do not want all online clients to reload when the server script reloads |

Client-side errors are sent when `AIO_ERROR_LOG` is enabled on the client. The server logs them via `PrintInfo` when received.

Client slash commands (`/aio pcall`, `/aio debug`, etc.) change runtime behavior. Restrict who can use them on production clients if that matters for your setup.

### Client-side limits

There is no instruction timeout on the client. A malicious or buggy **server** addon can still freeze the client Lua VM. Server-side review is the primary control.

## Reporting issues

If you find a security issue in AIO itself, report it privately to the maintainers rather than opening a public issue with exploit details.
