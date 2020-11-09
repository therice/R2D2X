local _, AddOn = ...
local Class = LibStub("LibClass-1.0")
local components = {}

local Component = Class('Component')
function Component:initialize(name)
    self.name  = name
end

function AddOn.NewComponent(name)
    assert(type(name) == 'string')
    if components[name] then
        error(format("Component '%s' already exists", name))
    end
    
    local component = Component(name)
    components[name] = component
    return component
end

function AddOn.GetComponent(name)
    assert(type(name) == "string")
    local component = components[name]
    if not component then
        error(format("Component '%s' does not exist", name))
    end
    return component
end
