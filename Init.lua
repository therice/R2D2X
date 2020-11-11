local AceAddon, AceAddonMinor = LibStub('AceAddon-3.0')
local AddOnName, AddOn = ...

AddOn = AceAddon:NewAddon(AddOn, AddOnName, 'AceConsole-3.0', 'AceEvent-3.0',  "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0")
AddOn:SetDefaultModuleState(false)

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