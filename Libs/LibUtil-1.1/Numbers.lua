local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Numbers) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
local Self = Util.Numbers

function Self.Between(num, a, b)
    return num > a and num < b
end

function Self.In(num, a, b)
    return num >= a and num <= b
end

function Self.ToHex(num, minLength)
    return ("%." .. (minLength or 1) .. "x"):format(num)
end

function Self.BinaryRepr(n)
    local t = {}
    for i=7,0,-1 do
        t[#t+1] = math.floor(n / 2^i)
        n = n % 2^i
    end
    return table.concat(t)
end