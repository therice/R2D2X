local _, AddOn = ...
local Logging = AddOn:GetLibrary("Logging")

function AddOn:OnInitialize()
    --@debug@
    Logging:SetRootThreshold(Logging.Level.Debug)
    --@end-debug@
    Logging:Debug("OnInitialize(%s)", self:GetName())

    -- convert to a semantic version
    self.version = AddOn.Package('Models').SemanticVersion(self.version)
    Logging:Debug("OnInitialize(%s) : version=%s", AddOn:GetName(), tostring(self.version))

    -- bitfield which keeps track of our operating mode
    self.mode = AddOn.Package('Core').Mode()
end

function AddOn:OnEnable()
    Logging:Debug("OnEnable(%s)", self:GetName())

    --@debug@
    -- this enables certain code paths that wouldn't otherwise be available in normal usage
    self.mode:Enable(AddOn.Constants.Modes.Develop)
    --@end-debug@

    -- this enables flag for persistence of stuff like points to officer's notes, history, and sync payloads
    -- it can be disabled as needed through /r2d2 pm
    self.mode:Enable(AddOn.Constants.Modes.Persistence)
    Logging:Debug("OnEnable(%s) : mode=%s", self:GetName(), tostring(self.mode))

    for name, module in self:IterateModules() do
        Logging:Debug("OnEnable(%s) : Examining module (startup) '%s'", self:GetName(), name)

        if module:EnableOnStartup() then
            Logging:Debug("OnEnable(%s) : Enabling module (startup) '%s'", self:GetName(), name)
            module:Enable()
        end
    end
end