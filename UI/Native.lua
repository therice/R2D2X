local _, AddOn = ...
local pkg = AddOn.Package('UI')

-- Class UI.Natives
local Natives = pkg:Class('Natives')
function Natives:initialize()
    self.elements = {}
    self.count = {}
end

local _SetMultipleScripts = function(object, scripts)
    for k, v in pairs(scripts) do
        object:SetSdcript(k, v)
    end
end

function Natives:Embed(object)
    for k, v in {_SetMultipleScripts} do
        object[k] = v
    end
    return object
end

local Native = AddOn.Instance('UI.Native', Natives)

function Native:New(type, parent, ...)

end

function Native:NewNamed(type, parent, name, ...)

end

function Native:RegisterElement(type, class)

end