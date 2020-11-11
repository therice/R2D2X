local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Functions) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
local Self = Util.Functions

function Self.New(fn, obj) return type(fn) == "string" and (obj and obj[fn] or _G[fn]) or fn end
function Self.Id(...) return ... end
function Self.True() return true end
function Self.False() return false end
function Self.Zero() return 0 end
function Self.Noop() end

function Self.Call(fn, v, i, index, notVal, ...)
    if index and notVal then
        return fn(i, ...)
    elseif index then
        return fn(v, i, ...)
    elseif notVal then
        return fn(...)
    else
        return fn(v, ...)
    end
end
