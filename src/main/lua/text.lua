_G.M = {}

function M.starts_with(text, start)
    return start == string.sub(text, 1, string.len(start))
end

return _G.M