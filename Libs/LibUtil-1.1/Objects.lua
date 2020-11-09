local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Objects) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
local Self = Util.Objects

function Self.IsEmpty(obj)
    if Self.IsNil(obj) then return true end
    if Self.IsString(obj) then return Util.Strings.IsEmpty(obj) end
    if Self.IsTable(obj) then return Util.Tables.IsEmpty(obj) end
    return false
end

function Self.IsSet(val)
    return not Self.IsEmpty(val)
end

function Self.IsString(obj)
    return type(obj) == 'string'
end

function Self.IsTable(obj)
    return type(obj) == 'table'
end

function Self.IsFunction(obj)
    return type(obj) == 'function'
end

function Self.IsNil(obj)
    return obj == nil
end

function Self.IsNumber(obj)
    return type(obj) == 'number'
end

function Self.IsBoolean(obj)
    return type(obj) == 'boolean'
end

function Self.IsCallable(obj)
    return (Self.IsFunction(obj) or (Self.IsTable(obj) and getmetatable(obj) and getmetatable(obj).__call ~= nil)) or false
end

function Self.Equals(a, b)
    return a == b
end

-- Get string representation of various object types
function Self.ToString(val, depth)
    depth = depth or 3
    local t = type(val)

    if t == "nil" then
        return "nil"
    elseif t == "table" then
        local fn = val.ToString or val.toString or val.tostring
        if depth == 0 then
            return "{...}"
        elseif type(fn) == "function" and fn ~= Self.ToString then
            return fn(val, depth)
        else
            local j = 1
            return Util.Tables.FoldL(
                    val,
                    function (s, v, i)
                        if s ~= "{" then s = s .. ", " end
                        if i ~= j then
                            if type(i) == 'table' then
                                s = s .. Self.ToString(i, depth - 1) .. " = "
                            else
                                s = s .. i .. " = "
                            end
                        end
                        j = j + 1
                        
                        return s .. Self.ToString(v, depth-1)
                    end,
                    "{", true
            ) .. "}"
        end
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "function" then
        return "(fn)"
    elseif t == "string" then
        return val
    elseif t == "userdata" then
        return "(userdata)"
    else
        return val
    end
end