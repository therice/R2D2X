local _, AddOn = ...
local L, Logging, Util = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
local GP = AddOn:NewModule('GearPoints')

GP.Defaults = {
    profile = {
        enabled = true,
        -- this is the minimum value for GP
        gp_min = 1,
        -- these are the inputs for GP formula
        formula = {
            gp_base             = 4.8,
            gp_coefficient_base = 2.5,
            gp_multiplier       = 1,
        },
    }
}

function GP:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())
    self.db = AddOn.db:RegisterNamespace(self:GetName(), GP.Defaults)
end

function GP:OnEnable()
    Logging:Debug("OnEnable(%s)", self:GetName())
end

function GP:OnDisable()
    Logging:Debug("OnDisable(%s)", self:GetName())
end