local _, AddOn = ...
local L, Logging, Util, AceConfig, ACD =
    AddOn.Locale, AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('AceConfig'), AddOn:GetLibrary('AceConfigDialog')
local AceUI = AddOn.Require('UI.Ace')

ACD:SetDefaultSize(AddOn.Constants.name, 850, 700)

-- todo : memoize
local function BuildConfigOptions()
    local ConfigOptions = Util.Tables.Copy(AddOn.BaseConfigOptions)
    local ConfigBuilder = AceUI.ConfigBuilder(ConfigOptions)

    -- base configuration options
    ConfigBuilder:args()
        :header('header', L["version"] .. format(": |cff99ff33%s|r", tostring(AddOn.version)))
            :order(0):set('width', 'full')
        :group('general', _G.GENERAL):order(1)
            :args()
                :group('generalOptions', L["general_options"]):order(0):set('inline', true)
                    :args()
                        :toggle('enable', L["active"]):desc(L["active_desc"]):order(1)
                            :set('set', function() end)
                            :set('get', function() return true end)
                        :toggle('minimizeInCombat', L["minimize_in_combat"]):desc(L["minimize_in_combat_desc"]):order(2)
                        :header('spacer', ""):order(3)
                        :execute('test', L["Test"]):desc(L["test_desc"]):order(4)
                            :set('func', function () end)
                        :execute('verCheck', L["version_check"]):desc(L["version_check_desc"]):order(5)
                            :set('func', function () end)
                        :execute('sync', L["sync"]):desc(L["sync_desc"]):order(6)
                            :set('func', function () end)

    -- set point to location where to add subsequent options
    ConfigBuilder:SetPath('args')

    -- per module configuration options
    local order, options, embedEnableDisable = 100, nil, false
    for name, module in AddOn:IterateModules() do
        Logging:Trace("BuildConfigOptions() : examining Module '%s'", name)

        if module['BuildConfigOptions'] then
            Logging:Trace("BuildConfigOptions(%s) : invoking 'BuildConfigOptions' on module to generate options", name)
            options, embedEnableDisable = module:BuildConfigOptions()
        else
            Logging:Trace("BuildConfigOptions(%s) : no configuration options for module", name)
            options, embedEnableDisable = nil, false
        end

        if options then
            if options.args and embedEnableDisable then
                for n, option in pairs(options.args) do
                    Logging:Trace("BuildConfigOptions() : modifying 'disabled' property for option argument %s.%s", n, option)
                    if option.disabled then
                        local oldDisabled = option.disabled
                        option.disabled = function(i)
                            return Util.Objects.IsFunction(oldDisabled) and oldDisabled(i) or module:IsDisabled()
                        end
                    else
                        option.disabled = "IsDisabled"
                    end
                end

                Logging:Trace("BuildConfigOptions() : adding 'enable' option argument for %s", name)
                options.args['enabled'] = {
                    order = 0,
                    type = "toggle",
                    width = "full",
                    name = _G.ENABLE,
                    get = "IsEnabled",
                    set = "SetEnabled",
                }
            end

            Logging:Trace("BuildConfigOptions() : registering options for module %s -> %s", name, Util.Objects.ToString(options))
            ConfigBuilder
                :group(name, options.name):desc(options.desc):order(order)
                    :set('handler', module)
                    :set('childGroups', options.childGroups and options.childGroups or 'tree')
                    :set('args', options.args)
                    :set('set', 'SetDbValue')
                    :set('get', 'GetDbValue')
            order = order + 1
        end
    end

    return ConfigBuilder:build()
end

function AddOn:RegisterConfig()
    AceConfig:RegisterOptionsTable(
            AddOn.Constants.name,
            function (uiType, uiName, appName)
                Logging:Trace("RegisterConfig() : Building configuration for '%s', '%s', '%s'", tostring(uiType), tostring(uiName), tostring(appName))
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