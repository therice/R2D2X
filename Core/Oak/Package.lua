-- Functionality below is intended to provide package/class like semantics to Lua
-- Extremely rudimentary, but provides easy and consistent mechanism to namespace and define classes
-- Both package and class support based upon LibClass library
local _, AddOn = ...
local Class = LibStub("LibClass-1.0")

local pkgs = {}

local Package = Class('Package')
function Package:initialize(name)
    self.name = name
    self.classes = {}
end

function Package:Class(name, super)
    -- class names must always be string
    assert(name and type(name) == 'string', 'Class name was not provided')
    -- if super class provided, must be a table (class)
    if super then assert(type(super) == 'table', format("Superclass was of incorrect type '%s'", type(super))) end
    if self.classes[name] then error(format("Class '%s' already defined in Package '%s'", name, self.name)) end
    local class = Class(name, super)
    self.classes[name] = class
    return class
end

function Package:__index(name)
    -- print(format('__index(%s)', tostring(name)))
    local c = self.classes[name]
    if not c then error(format("Class '%s' does not exist in Package '%s'", name, self.name)) end
    return c
end

function AddOn.Package(name)
    assert(type(name) == 'string')
    local pkg = pkgs[name]
    if not pkg then
        pkg = Package(name)
        pkgs[name] = pkg
    end
    return pkg
end

function AddOn.ImportPackage(name)
    assert(type(name) == "string")
    local pkg = pkgs[name]
    if not pkg then error(format("Package '%s' does not exist", name)) end
    return pkg
end

if _G.Package_Testing or _G.R2D2X_Testing then
    function Package:DiscardClasses()
        self.classes = {}
    end

    function AddOn.DiscardPackages()
        for _, p in pairs(pkgs) do
            p:DiscardClasses()
        end
        pkgs = {}
    end

end