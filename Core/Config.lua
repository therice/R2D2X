local _, AddOn = ...
local L, Logging, Util, AceConfig, ACD =
    AddOn.Locale, AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('AceConfig'), AddOn:GetLibrary('AceConfigDialog')

ACD:SetDefaultSize(AddOn.Constants.name, 850, 700)

-- todo : memoize
local function BuildConfigOptions()
    local ConfigOptions = Util.Tables.Copy(AddOn.BaseConfigOptions)

    -- setup some basic configuration options that don't belong to any module (but the add-on itself)
    -- todo : option builder
    ConfigOptions.args = {
        header =  {
            order = 0,
            type = 'header',
            name = L["version"] .. format(": |cff99ff33%s|r", tostring(AddOn.version)),
            width = 'full'
        },
        general = {
            order = 1,
            type = 'group',
            name = _G.GENERAL,
            args = {

            }
        }
    }
    return ConfigOptions
end

function AddOn:RegisterConfig()
    AceConfig:RegisterOptionsTable(
            AddOn.Constants.name,
            function (uiType, uiName, appName)
                Logging:Trace("Building configuration for '%s', '%s', '%s'", tostring(uiType), tostring(uiName), tostring(appName))
                return BuildConfigOptions()
            end
    )
end

local function ConfigFrame()
    local f = ACD.OpenFrames[AddOn.Constants.name]
    return not Util.Objects.IsNil(f), f
end

function AddOn.ToggleConfig()
    if ConfigFrame() then AddOn.HideConfig() else AddOn.ShowConfig() end
end

function AddOn.ShowConfig()
    ACD:Open(AddOn.Constants.name)
end

function AddOn.HideConfig()
    local _, f = ConfigFrame()
    if f then
        -- local gpm = AddOn:GearPointsCustomModule()
        -- if gpm.addItemFrame then gpm.addItemFrame:Hide() end
        ACD:Close(AddOn.Constants.name)
        return true
    end

    return false
end