local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Functions) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
--- @class LibUtil.Functions
local Self = Util.Functions

function Self.New(fn, obj) return type(fn) == "string" and (obj and obj[fn] or _G[fn]) or fn end
function Self.Id(...) return ... end
function Self.True() return true end
function Self.False() return false end
function Self.Zero() return 0 end
function Self.Noop() end

-- index and notVal = function(index, ...)
-- index = function(value, index, ...)
-- notVal = function(...)

---@param index boolean
---@param notVal boolean
---@return any
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

-- Get a value directly or as return value of a function
---@param fn function
function Self.Val(fn, ...)
    return (type(fn) == "function" and Util.Push(fn(...)) or Util.Push(fn)).Pop()
end

-- Some math
---@param i number
function Self.Inc(i)
    return i+1
end

---@param i number
function Self.Dec(i)
    return i-1
end

---@param a number
---@param b number
function Self.Add(a, b)
    return a+b
end

---@param a number
---@param b number
function Self.Sub(a, b)
    return a-b
end

---@param a number
---@param b number
function Self.Mul(a, b)
    return a*b
end

---@param a number
---@param b number
function Self.Div(a, b)
    return a/b
end

function Self.Dispatch(...)
    local funcs = {...}
    return function (...)
        for _, f in ipairs(funcs) do
            local r = { f(...) }
            if #r > 0 then return unpack(r) end
        end
    end
end

function Self.Filter(predicate_func, f, s, v)
    return function(s, v)
        local tmp = { f(s, v) }
        while tmp[1] ~= nil and not predicate_func(unpack(tmp)) do
            v = tmp[1]
            tmp = { f(s, v) }
        end
        return unpack(tmp)
    end, s, v
end


-- MODIFY

-- Throttle a function, so it is executed at most every n seconds
---@param fn function
---@param n number
---@param leading boolean
function Self.Throttle(fn, n, leading)
    local Timer = LibStub("AceTimer-3.0")
    local Fn, handle, called
    Fn = function (...)
        if not handle then
            if leading then fn(...) end
            handle = Timer:ScheduleTimer(function (...)
                handle = nil
                if not leading then fn(...) end
                if called then
                    called = nil
                    Fn(...)
                end
            end, n, ...)
        else
            called = true
        end
    end
    return Fn
end

-- Debounce a function, so it is executed only n seconds after the last call
function Self.Debounce(fn, n, leading)
    local Timer = LibStub("AceTimer-3.0")
    local handle, called
    return function (...)
        if not handle then
            if leading then fn(...) end
            handle = Timer:ScheduleTimer(function (...)
                handle = nil
                if not leading or called then
                    called = nil
                    fn(...)
                end
            end, n, ...)
        else
            called = true
            Timer:CancelTimer(handle)
            handle = Timer:ScheduleTimer(handle.func, n, unpack(handle, 1, handle.argsCount))
        end
    end
end