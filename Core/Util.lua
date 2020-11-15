local _, AddOn = ...
local Logging, Util = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util')
local Mode = AddOn.Package('Core'):Class('Mode')

local function bbit(p) return 2 ^ (p - 1) end
local function hasbit(x, p) return x % (p + p) >= p end
local function setbit(x, p) return hasbit(x, p) and x or x + p end
local function clearbit(x, p) return hasbit(x, p) and x - p or x end

function Mode:initialize()
    self.bitfield = bbit(AddOn.Constants.Modes.Standard)
end

function Mode:Enable(...)
    for _, p in Util.Objects.Each(...) do
        self.bitfield = setbit(self.bitfield, p)
    end
end

function Mode:Disable(...)
    for _, p in Util.Objects.Each(...) do
        self.bitfield = clearbit(self.bitfield, p)
    end
end

function Mode:Enabled(flag)
    return bit.band(self.bitfield, flag) == flag
end

function Mode:Disabled(flag)
    return bit.band(self.bitfield, flag) == 0
end

function Mode:__tostring()
    return Util.Numbers.BinaryRepr(self.bitfield)
end

function AddOn:Qualify(...)
    return Util.Strings.Join('_', self.Constants.name, ...)
end


function AddOn:IsInNonInstance()
    local instanceType = select(2, IsInInstance())
    if Util.Objects.In(instanceType, 'pvp', 'arena') then
        return true
    else
        return false
    end
end


-- Custom, better UnitIsUnit() function.
-- Blizz UnitIsUnit() doesn't know how to compare unit-realm with unit.
-- Seems to be because unit-realm isn't a valid unitid.
function AddOn:UnitIsUnit(unit1, unit2)
    if not unit1 or not unit2 then return false end
    if unit1.name then unit1 = unit1.name end
    if unit2.name then unit2 = unit2.name end

    -- Remove realm names, if any
    if strfind(unit1, "-", nil, true) ~= nil then
        unit1 = Ambiguate(unit1, "short")
    end
    if strfind(unit2, "-", nil, true) ~= nil then
        unit2 = Ambiguate(unit2, "short")
    end
    -- There's problems comparing non-ascii characters of different cases using UnitIsUnit()
    -- I.e. UnitIsUnit("Foo", "foo") works, but UnitIsUnit("Æver", "æver") doesn't.
    -- Since I can't find a way to ensure consistent returns from UnitName(), just lowercase units here
    -- before passing them.
    return UnitIsUnit(unit1:lower(), unit2:lower())
end


-- Gets a unit's name formatted with realmName.
-- If the unit contains a '-' it's assumed it belongs to the realmName part.
-- Note: If 'unit' is a playername, that player must be in our raid or party!
-- @param unit Any unit, except those that include '-' like "name-target".
-- @return Titlecased "unitName-realmName"
function AddOn:UnitName(unit)
    -- First strip any spaces
    unit = gsub(unit, " ", "")
    -- Then see if we already have a realm name appended
    local find = strfind(unit, "-", nil, true)
    if find and find < #unit then -- "-" isn't the last character
        -- Let's give it same treatment as below so we're sure it's the same
        local name, realm = strsplit("-", unit, 2)
        name = name:lower():gsub("^%l", string.upper)
        return name.."-"..realm
    end
    -- Apparently functions like GetRaidRosterInfo() will return "real" name, while UnitName() won't
    -- always work with that (see ticket #145). We need this to be consistent, so just lowercase the unit:
    unit = unit:lower()
    -- Proceed with UnitName()
    local name, realm = UnitName(unit)
    -- Extract our own realm
    if not realm or realm == "" then realm = self.realmName or "" end
    -- if the name isn't set then UnitName couldn't parse unit, most likely because we're not grouped.
    if not name then
        name = unit
    end
    -- Below won't work without name
    -- We also want to make sure the returned name is always title cased (it might not always be! ty Blizzard)
    name = name:lower():gsub("^%l", string.upper)
    return name and name.."-"..realm
end
