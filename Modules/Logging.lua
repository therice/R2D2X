local _, AddOn = ...
local Log, Util = AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
local Logging = AddOn:NewModule("Logging")
local accum

if not _G.R2D2X_Testing then
    accum = {}
    Log:SetWriter(
        function(msg)
            Util.Tables.Push(accum, msg)
        end
    )
end

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
