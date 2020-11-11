local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Strings) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
local Self = Util.Strings

function Self.IsSet(str)
    return type(str) == "string" and str:trim() ~= "" or false
end

function Self.IsEmpty(str)
    return not Self.IsSet(str)
end

function Self.StartsWith(str, str2)
    return  type(str) == "string" and
            type(str2) == "string" and
            str:sub(1, str2:len()) == str2
end

function Self.EndsWith(str, str2)
    return  type(str) == "string" and
            type(str2) == "string" and
            str:sub(-str2:len()) == str2
end

function Self.Equal(str1, str2)
    if str1 == nil or str2 == nil then return str1 == str2 end
    if Self.IsEmpty(str1) then return Self.IsEmpty(str2) end
    return str1 == str2
end

function Self.Wrap(str, before, after)
    if Self.IsEmpty(str) then return "" end
    return (before or " ") .. str .. (after or before or " ")
end

function Self.Prefix(str, prefix)
    return Self.Wrap(str, prefix, "")
end

function Self.Postfix(str, postfix)
    return Self.Wrap(str, "", postfix)
end

-- Split string on delimiter
function Self.Split(str, del)
    local t = Util.Tables.New()
    for v in (str .. del):gmatch("(.-)" .. del:gsub(".", "%%%1")) do
        tinsert(t, v)
    end
    return t
end

function Self.Join(del, ...)
    local s = ""
    for _,v in Util.Each(...) do
        if not Self.IsEmpty(v) then
            s = s .. (s == "" and "" or del or " ") .. v
        end
    end
    return s
end