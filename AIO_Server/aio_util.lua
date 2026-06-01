local M = {}

function M.basename(path)
    assert(type(path) == "string", "#1 string expected")
    return string.match(path, "([^/\\]*)$") or path
end

function M.getMessageStoredSize(data)
    if not data or not data.parts then
        return 0
    end
    local stored = 0
    for i = 1, data.parts.n do
        local part = data.parts[i]
        if part then
            stored = stored + #part
        end
    end
    return stored
end

function M.isMessageExpired(stamp, now, cacheTimeMs)
    return (now - stamp) >= cacheTimeMs
end

return M
