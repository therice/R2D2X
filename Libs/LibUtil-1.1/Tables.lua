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

-- Reusable Tables
--
-- Store unused tables in a cache to reuse them later
-- A cache for temp tables
Self.tblPool = {}
Self.tblPoolSize = 10

-- Get a table (newly created or from the cache), and fill it with values
function Self.New(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...) do
        t[i] = select(i, ...)
    end
    return t
end