local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Tables) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
local Self = Util.Tables

function Self.IsSet(t)
    return type(t) == "table" and next(t) and true or false
end

function Self.IsEmpty(t)
    return not Self.IsSet(t)
end

function Self.FoldL(t, fn, u, index, ...)
    fn, u = Util.Functions.New(fn), u or Self.New()
    for i,v in pairs(t) do
        if index then
            u = fn(u, v, i, ...)
        else
            u = fn(u, v, ...)
        end
    end
    return u
end

function Self.Copy(t, fn, index, notVal, ...)
    local fn, u = Util.Functions.New(fn), Self.New()
    for i,v in pairs(t) do
        if fn then
            u[i] = Util.Functions.Call(fn, v, i, index, notVal, ...)
        else
            u[i] = v
        end
    end
    return u
end

function Self.Push(t, v)
    tinsert(t, v)
    return t
end


-- Reusable Tables
--
-- Store unused tables in a cache to reuse them later
-- A cache for temp tables
Self.tblPool = {}
Self.tblPoolSize = 10

-- For when we need an empty table as noop or special marking
Self.EMPTY = {}
-- For when we need to store nil values in a table
Self.NIL = {}

-- Get a table (newly created or from the cache), and fill it with values
function Self.New(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...) do
        t[i] = select(i, ...)
    end
    return t
end

function Self.Release(...)
    local depth = type(...) ~= "table" and (type(...) == "number" and max(0, (...)) or ... and Self.tblPoolSize) or 0

    for i=1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" and t ~= Self.EMPTY and t ~= Self.NIL then
            if #Self.tblPool < Self.tblPoolSize then
                tinsert(Self.tblPool, t)

                if depth > 0 then
                    for _,v in pairs(t) do
                        if type(v) == "table" then Self.Release(depth - 1, v) end
                    end
                end

                wipe(t)
                setmetatable(t, nil)
            else
                break
            end
        end
    end
end
