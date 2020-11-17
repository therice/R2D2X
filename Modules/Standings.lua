local _, AddOn = ...
local Standings = AddOn:NewModule('Standings')
local L, Logging, Util, GuildStorage =
    AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"), AddOn:GetLibrary("GuildStorage")
local Subject = AddOn.Package('Models').Subject

function Standings:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())

    self.subjects = {}
    self.pendingUpdate = false

    -- register callbacks with LibGuildStorage for events in which we are interested
    GuildStorage.RegisterCallback(self, GuildStorage.Events.GuildOfficerNoteChanged, "MemberModified")
    GuildStorage.RegisterCallback(self, GuildStorage.Events.GuildMemberDeleted, "MemberDeleted")
    GuildStorage.RegisterCallback(self, GuildStorage.Events.StateChanged, "DataChanged")
    GuildStorage.RegisterCallback(self, GuildStorage.Events.Initialized, "DataChanged")
end

function Standings:OnEnable()
    Logging:Debug("OnEnable(%s)", self:GetName())
    self:BuildFrame()
    self:BuildData()
    self:Show()
end

function Standings:OnDisable()
    Logging:Debug("OnDisable(%s)", self:GetName())
    self:Hide()
end

function Standings:EnableOnStartup()
    return false
end

function Standings:_AddEntry(name, entry)
    self.subjects[name] = entry
    self.pendingUpdate = true
end

function Standings:_RemoveEntry(name)
    self.subjects[name] = nil
    self.pendingUpdate = true
end

function Standings:GetEntry(name)
    return self.subjects[name]
end

function Standings.Points(name)
    local e = Standings:GetEntry(name)
    if e then return e:Points() end

    -- todo : just nil?
    return 0, 0, 0
end


-- todo : need to handle addition and removal of members to scrolling table
-- this is currently only invoked as part of officer's note changing, nothing else
function Standings:MemberModified(_, name, note)
    -- don't need to remove, it overwrites
    -- name with be character-realm
    self:_AddEntry(name, Subject:FromGuildMember(GuildStorage:GetMember(name)))
    Logging:Trace("MemberModified(%s) : '%s'", name, note)
end

function Standings:MemberDeleted(_, name)
    self._RemoveEntry(name)
    Logging:Trace("MemberDeleted(%s)", name)
end

-- todo : maybe it's better to just fire from individual events
function Standings:DataChanged(event, state)
    Logging:Trace("DataChanged(%s) : %s, %s", event, tostring(state), tostring(self.pendingUpdate))
    -- will get this once everything settles
    -- individual events will have collected the appropriate point entries
    if event == GuildStorage.Events.Initialized then
        -- no-op for now
    elseif event == GuildStorage.Events.StateChanged then
        if state == GuildStorage.States.Current then
            self:Update()
        end
    end
end

function Standings:Update(forceUpdate)
    Logging:Trace("Update(%s)", tostring(forceUpdate or false))
    -- if module isn't enabled, no need to perform update
    if not self:IsEnabled() then return end
end