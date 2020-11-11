local _, AddOn = ...
local Logging = AddOn:GetLibrary('Logging')
local Util = AddOn:GetLibrary('Util')

function AddOn:Qualify(...)
    return Util.Strings.Join('_', self.Constants.name, ...)
end