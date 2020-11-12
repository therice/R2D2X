_G.getfenv = function() return _G end
_G.random = math.random
-- need to set random seed and invoke once to avoid non-random behavior
math.randomseed(os.time())
math.random()

-- utility function for "dumping" a number of arguments (return a string representation of them)
function dump(...)
    local t = {}
    for i=1,select("#", ...) do
        local v = select(i, ...)
        if type(v)=="string" then
            tinsert(t, string.format("%q", v))
        elseif type(v)=="table" then
            tinsert(t, tostring(v).." #"..#v)
        else
            tinsert(t, tostring(v))
        end
    end
    return "<"..table.concat(t, "> <")..">"
end


require('bit')
_G.bit = bit
_G.tInvert = function(tbl)
    local inverted = {};
    for k, v in pairs(tbl) do
        inverted[v] = k;
    end
    return inverted;
end
_G.getfenv = function() return _G end
-- define required function pointers in global space which won't be available in testing
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
_G.strlower = string.lower
_G.strupper = string.upper
_G.mod = function(a,b) return a - math.floor(a/b) * b end

-- https://wowwiki.fandom.com/wiki/API_strsplit
-- A list of strings. Not a table. If the delimiter is not found in the string, the whole subject string will be returned.
_G.strsplit = function(delimiter, str, max)
    local record = {}
    if string.len(str) > 0 then
        max = max or -1

        local field, start = 1, 1
        local first, last = string.find(str, delimiter, start, true)
        while first and max ~= 0 do
            record[field] = string.sub(str, start, first -1)
            field = field +1
            start = last +1
            first, last = string.find(str, delimiter, start, true)
            max = max -1
        end
        record[field] = string.sub(str, start)
    end

    return unpack(record)
end
string.split = _G.strsplit
_G.strsub = string.sub
_G.strbyte = string.byte
_G.strchar = string.char
_G.pack = table.pack
_G.unpack = table.unpack
_G.sort = table.sort
-- this isn't functionally correct
_G.debugprofilestop = function() return 0 end

local wow_api_locale = 'enUS'
function GetLocale()
    return wow_api_locale
end

function SetLocale(locale)
    wow_api_locale = locale
end

_time = 0
function GetTime()
    return _time
end


C_Timer = {}
function C_Timer.After(duration, callback)  end
function C_Timer.NewTimer(duration, callback)  end
function C_Timer.NewTicker(duration, callback, iterations)  end

if not wipe then
    function wipe(tbl)
        for k in pairs(tbl) do
            tbl[k]=nil
        end
    end

    if not table.wipe then
        table.wipe = wipe
    end
end

function hooksecurefunc(func_name, post_hook_func)
    local orig_func = _G[func_name]
    _G[func_name] =
    function (...)
        local ret = { orig_func(...) }
        post_hook_func(...)
        return unpack(ret)
    end
end

function GetAddOnMetadata(name, attr)
    if string.lower(attr) == 'version' then
        return "2.0.0-beta"
    else
        return nil
    end
end

function GetAddOnInfo()
    return
end

local function _errorhandler(msg)
    print(format("_errorhandler() : %s", dump(msg)))
end

function geterrorhandler()
    return _errorhandler
end

function IsLoggedIn() return false end


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

loadfile('Test/WowApiUI.lua')()