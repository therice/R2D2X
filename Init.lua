local AceAddon, AceAddonMinor = LibStub('AceAddon-3.0')
local AddOnName, AddOn = ...

AddOn = AceAddon:NewAddon(AddOn, AddOnName, 'AceConsole-3.0', 'AceEvent-3.0', "AceHook-3.0", "AceTimer-3.0", "AceBucket-3.0")
AddOn:SetDefaultModuleState(false)
_G.R2D2X = AddOn

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
    AddOn:AddLibrary('Base64', 'LibBase64-1.0')
    AddOn:AddLibrary('Rx', 'LibRx-1.0')
    AddOn:AddLibrary('AceAddon', AceAddon, AceAddonMinor)
    AddOn:AddLibrary('AceEvent', 'AceEvent-3.0')
    AddOn:AddLibrary('AceTimer', 'AceTimer-3.0')
    AddOn:AddLibrary('AceHook', 'AceHook-3.0')
    AddOn:AddLibrary('AceLocale', 'AceLocale-3.0')
    AddOn:AddLibrary('AceConsole', 'AceConsole-3.0')
    AddOn:AddLibrary('AceComm', 'AceComm-3.0')
    AddOn:AddLibrary('AceSerializer', 'AceSerializer-3.0')
    AddOn:AddLibrary('AceGUI', 'AceGUI-3.0')
    AddOn:AddLibrary('AceDB', 'AceDB-3.0')
    AddOn:AddLibrary('AceBucket', 'AceBucket-3.0')
    AddOn:AddLibrary('AceConfig', 'AceConfig-3.0')
    AddOn:AddLibrary('AceConfigCmd', 'AceConfigCmd-3.0')
    AddOn:AddLibrary('AceConfigDialog', 'AceConfigDialog-3.0')
    AddOn:AddLibrary('AceConfigRegistry', 'AceConfigRegistry-3.0')
    AddOn:AddLibrary('ItemUtil', 'LibItemUtil-1.1')
    AddOn:AddLibrary('Window', 'LibWindow-1.1')
    AddOn:AddLibrary('ScrollingTable', 'ScrollingTable')
    AddOn:AddLibrary('Dialog', 'LibDialog-1.0')
    AddOn:AddLibrary('DataBroker', 'LibDataBroker-1.1')
    AddOn:AddLibrary('DbIcon', 'LibDBIcon-1.0')
    AddOn:AddLibrary('GuildStorage', 'LibGuildStorage-1.3')
    AddOn:AddLibrary('JSON', 'LibJSON-1.0')
end

AddOn.Locale = AddOn:GetLibrary("AceLocale"):GetLocale(AddOn.Constants.name)

local Logging, Util = AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
--@debug@
Logging:SetRootThreshold(AddOn._IsTestContext() and Logging.Level.Trace or Logging.Level.Debug)
--@end-debug@

local function GetDbValue(self, i)
    Logging:Debug("GetDbValue(%s, %s)", self:GetName(), tostring(i[#i]))
    return Util.Tables.Get(self.db.profile, tostring(i[#i]))
end

local function SetDbValue(self, i, v)
    Logging:Debug("SetDbValue(%s, %s, %s)", self:GetName(), tostring(i[#i]), tostring(v or 'nil'))
    Util.Tables.Set(self.db.profile, tostring(i[#i]), v)
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
    -- specifies if module should be enabled on startup
    EnableOnStartup = function (self)
        local enable = (self.db and ((self.db.profile and self.db.profile.enabled) or self.db.enabled)) or false
        Logging:Debug("EnableOnStartup(%s) : %s", self:GetName(), tostring(enable))
        return enable
    end,
    -- return a tuple
    --  1, table which contains the module's configuration options
    --  2, boolean indicating if enable/disable support should be enabled
    --
    -- by default, no options are returned
    BuildConfigOptions = function(self)
        return nil, false
    end,
    -- implement to provide data import functionality for a module
    ImportData = function(self, data)

    end,

    ModuleSettings = function(self)
        return AddOn:ModuleSettings(self:GetName())
    end
}

AddOn:SetDefaultModulePrototype(ModulePrototype)

-- stuff below here is strictly for use during tests of addon
-- not to be confused with addon test mode
local function _testNs(name) return  Util.Strings.Join('_', name, 'Testing')  end
local AddOnTestNs = _testNs(AddOnName)
function AddOn._IsTestContext(name)
    if _G[AddOnTestNs] then
        return true
    end
    if Util.Strings.IsSet(name) then
        if _G[_testNs(name)] then
            return true
        end
    end

    return false
end