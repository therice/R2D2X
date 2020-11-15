local _, AddOn = ...
local L, Log, Util = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
local Logging = AddOn:NewModule("Logging")
local AceUI = AddOn.Require('UI.Ace')
local accum, configOptions

if not _G.R2D2X_Testing then
    accum = {}
    Log:SetWriter(
        function(msg)
            Util.Tables.Push(accum, msg)
        end
    )
end

local LoggingLevels = {
    [Log:GetThreshold(Log.Level.Disabled)] = Log.Level.Disabled,
    [Log:GetThreshold(Log.Level.Fatal)]    = Log.Level.Fatal,
    [Log:GetThreshold(Log.Level.Error)]    = Log.Level.Error,
    [Log:GetThreshold(Log.Level.Warn)]     = Log.Level.Warn,
    [Log:GetThreshold(Log.Level.Info)]     = Log.Level.Info,
    [Log:GetThreshold(Log.Level.Debug)]    = Log.Level.Debug,
    [Log:GetThreshold(Log.Level.Trace)]    = Log.Level.Trace,
}

function Logging:OnInitialize()
    Log:Debug("OnInitialize(%s)", self:GetName())
    self:BuildFrame()
    --@debug@
    self:Toggle()
    --@end-debug@
end

function Logging:OnEnable()
    Log:Debug("OnEnable(%s)", self:GetName())
    self:SwitchDestination(accum)
    accum = nil
end

function Logging:EnableOnStartup()
    return true
end

function Logging.GetLoggingLevels()
    return Util.Tables.Copy(LoggingLevels)
end

function Logging:SetLoggingThreshold(threshold)
    AddOn:SetDbValue({'logThreshold'}, threshold)
    Log:SetRootThreshold(threshold)
end

function Logging:BuildConfigOptions()
    if not configOptions then
        configOptions =
            AceUI.ConfigBuilder()
                :group(Logging:GetName(), L['logging']):desc(L['logging_desc'])
                :args()
                    :description('help', L['logging_help']):order(1)
                    :select('logThreshold', L['logging_threshold']):desc(L['logging_threshold_desc']):order(2)
                        :set('values', Logging.GetLoggingLevels())
                        :set('get', function() return Log:GetRootThreshold() end)
                        :set('set', function(_, logThreshold) Logging:SetLoggingThreshold(logThreshold) end)
                    :description('spacer', ""):order(3)
                    :execute('toggleWindow', L['logging_window_toggle']):desc(L['logging_window_toggle_desc']):order(4)
                    :set('func', function() Logging:Toggle() end)
                :build()
    end

    return configOptions[self:GetName()], false
end

