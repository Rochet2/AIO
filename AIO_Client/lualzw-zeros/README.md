# lualzw (vendored)

Vendored from [Rochet2/lualzw](https://github.com/Rochet2/lualzw) **v1.1.0** (`6cbf8ab`, 2026-05-31).

AIO loads this folder as `require("lualzw")` and uses the null-safe codec (`skip = { [0] = true }`), which matches the historical `zeros` branch wire format used by this project.

Upstream docs, API, and benchmarks: https://github.com/Rochet2/lualzw
