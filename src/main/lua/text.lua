_G.M = {}

---
-- Check if string starts with a substring.
--
-- @param text string to check
--
-- @param start substring
--
-- @return true if text start with mentioned substring
--
function M.starts_with(text, start)
    return start == string.sub(text, 1, string.len(start))
end

return _G.M