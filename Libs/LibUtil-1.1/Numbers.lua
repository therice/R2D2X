local MAJOR_VERSION = "LibUtil-1.1"
local MINOR_VERSION = 11305

local lib, minor = LibStub(MAJOR_VERSION, true)
if not lib or next(lib.Numbers) or (minor or 0) > MINOR_VERSION then return end

local Util = lib
local Self = Util.Numbers