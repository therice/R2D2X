local AceAddon, AceAddonMinor = LibStub('AceAddon-3.0')
local AddOnName, AddOn = ...

AddOn = AceAddon:NewAddon(AddOn, AddOnName, 'AceConsole-3.0', 'AceEvent-3.0',  "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0")
AddOn:SetDefaultModuleState(false)

-- just capture version here, it will be turned into semantic version later
-- as we don't have access to that model yet here
AddOn.version = GetAddOnMetadata(AddOnName, "Version")
--@debug@
-- if local development and not substituted, then use a dummy version
if AddOn.version == '@project-version@' then
    AddOn.version = '2.0-dev'
end
--@end-debug@

do
    AddOn:AddLibrary('Class', 'LibClass-1.0')
    AddOn:AddLibrary('Logging', 'LibLogging-1.0')
    AddOn:AddLibrary('Util', 'LibUtil-1.1')
    AddOn:AddLibrary('Deflate', 'LibDeflate')
    AddOn:AddLibrary('AceAddon', AceAddon, AceAddonMinor)
    AddOn:AddLibrary('AceEvent', 'AceEvent-3.0')
    AddOn:AddLibrary('AceTimer', 'AceTimer-3.0')
    AddOn:AddLibrary('AceHook', 'AceHook-3.0')
    AddOn:AddLibrary('AceLocale', 'AceLocale-3.0')
    AddOn:AddLibrary('AceConsole', 'AceConsole-3.0')
    AddOn:AddLibrary('AceComm', 'AceComm-3.0')
    AddOn:AddLibrary('AceSerializer', 'AceSerializer-3.0')
end

local Logging = AddOn:GetLibrary("Logging")
local Tables = AddOn:GetLibrary("Util").Tables

local function GetDbValue(self, i)
    return Tables.Get(self.db.profile, tostring(i[#i]))
end

local function SetDbValue(self, i, v)
    Tables.Set(self.db.profile, tostring(i[#i]), v)
    -- AddOn:ConfigTableChanged(self:GetName(), i[#i])
end

AddOn.GetDbValue = GetDbValue
AddOn.SetDbValue = SetDbValue

local ModulePrototype = {
    IsDisabled = function (self, i)
        Logging:Trace("Module:IsDisabled(%s) : %s", self:GetName(), tostring(not self:IsEnabled()))
        return not self:IsEnabled()
    end,
    SetEnabled = function (self, i, v)
        if v then
            Logging:Trace("Module:SetEnabled(%s) : Enabling module", self:GetName())
            self:Enable()
        else
            Logging:Trace("Module:SetEnabled(%s) : Disabling module ", self:GetName())
            self:Disable()
        end
        self.db.profile.enabled = v
        Logging:Trace("Module:SetEnabled(%s) : %s", self:GetName(), tostring(self.db.profile.enabled))
    end,
    GetDbValue = GetDbValue,
    SetDbValue = SetDbValue,
    EnableOnStartup = function (self)
        local enable = (self.db and ((self.db.profile and self.db.profile.enabled) or self.db.enabled)) or false
        Logging:Debug("EnableOnStartup(%s) : %s", self:GetName(), tostring(enable))
        return enable
    end,
    ImportData = function(self, data)
    end
}

AddOn:SetDefaultModulePrototype(ModulePrototype)
