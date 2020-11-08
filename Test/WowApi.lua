_G.getfenv = function() return _G end
_G.format = string.format
-- https://wowwiki.fandom.com/wiki/API_debugstack
-- debugstack([thread, ][start[, count1[, count2]]]])
-- ignoring count2 currently (lines at end)
_G.debugstack = function (start, count1, count2)
    -- UGH => https://lua-l.lua.narkive.com/ebUKEGpe/confused-by-lua-reference-manual-5-3-and-debug-traceback
    -- If message is present but is neither a string nor nil, this function returns message without further processing.
    -- Otherwise, it returns a string with a traceback of the call stack. An optional message string is appended at the
    -- beginning of the traceback. An optional level number tells at which level to start the traceback
    -- (default is 1, the function calling traceback).
    local stack = debug.traceback()
    local chunks = {}
    for chunk in stack:gmatch("([^\n]*)\n?") do
        -- remove leading and trailing spaces
        local stripped = string.gsub(chunk, '^%s*(.-)%s*$', '%1')
        table.insert(chunks, stripped)
    end

    -- skip first line that looks like 'stack traceback:'
    local start_idx = math.min(start + 2, #chunks)
    -- where to stop, it's the start index + count1 - 1 (to account for counting line where we start)
    local end_idx = math.min(start_idx + count1 - 1, #chunks)
    return table.concat(chunks, '\n', start_idx, end_idx)
end
_G.strmatch = string.match
_G.strjoin = function(delimiter, ...)
    return table.concat({...}, delimiter)
end
_G.string.trim = function(s)
    -- from PiL2 20.4
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end
_G.strfind = string.find
_G.gsub = string.gsub
_G.date = os.date
_G.time = os.time
_G.difftime = os.difftime
_G.unpack = table.unpack
_G.tinsert = table.insert
_G.tremove = table.remove
_G.floor = math.floor
_G.mod = function(a,b) return a - math.floor(a/b) * b end

C_CreatureInfo = {}
C_CreatureInfo.ClassInfo = {
    [1] = {
        "Warrior", "WARRIOR"
    },
    [2] = {
        "Paladin", "PALADIN"
    },
    [3] = {
        "Hunter", "HUNTER"
    },
    [4] = {
        "Rogue", "ROGUE"
    },
    [5] = {
        "Priest", "PRIEST"
    },
    [6] = nil,
    [7] = {
        "Shaman", "SHAMAN"
    },
    [8] = {
        "Mage", "MAGE"
    },
    [9] = {
        "Warlock", "WARLOCK"
    },
    [10] = nil,
    [11] = {
        "Druid", "DRUID"
    },
    [12] = nil,
}
