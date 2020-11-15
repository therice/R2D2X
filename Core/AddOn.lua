local _, AddOn = ...
local Logging = AddOn:GetLibrary("Logging")

function AddOn:OnInitialize()
    --@debug@
    Logging:SetRootThreshold(Logging.Level.Debug)
    --@end-debug@
    Logging:Debug("OnInitialize(%s)", self:GetName())
    -- convert to a semantic version
    self.version = AddOn.Package('Models').SemanticVersion(self.version)
    -- bitfield which keeps track of our operating mode
    self.mode = AddOn.Package('Core').Mode()

    self.db = self:GetLibrary("AceDB"):New(self:Qualify('DB'), self.Defaults)
    if not _G.R2D2X_Testing then
        Logging:SetRootThreshold(self.db.profile.logThreshold)
    end
    self:AddMinimapButton()
    self:RegisterConfig()
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

    --[[
    self.realmName = 'Atiesh'
    self.player ={
        name = 'Gnomechómsky',
        guid = 'XXXX',
        class = 'Warlock',
        realm = self.realmName
    }
    --]]

    for name, module in self:IterateModules() do
        Logging:Debug("OnEnable(%s) : Examining module (startup) '%s'", self:GetName(), name)

        if module:EnableOnStartup() then
            Logging:Debug("OnEnable(%s) : Enabling module (startup) '%s'", self:GetName(), name)
            module:Enable()
        end
    end
end