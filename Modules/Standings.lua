local _, AddOn = ...
local Standings = AddOn:NewModule('Standings')
local L, Logging, Util, GuildStorage =
    AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"), AddOn:GetLibrary("GuildStorage")
local Award, Subject = AddOn.Package('Models').Award, AddOn.Package('Models').Subject

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
    self:GetFrame()
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

-- todo : do we need to throttle refreshses?
function Standings:Update(forceUpdate)
    Logging:Trace("Update(%s)", tostring(forceUpdate or false))
    -- if module isn't enabled, no need to perform update
    if not self:IsEnabled() then return end
    if not self.frame then return end
    self.frame.st:SortData()
end

function Standings:Adjust(award)
    if not GuildStorage:IsStateCurrent() then
        Logging:Debug("Adjust() : GuildStorage state is not current, scheduling for near future and returning")
        return self:ScheduleTimer("Adjust", 1, award)
    end

    -- local function for forming operation on target
    local function apply(target, action, type, amount)
        -- if a subtract operation flip sign on amount (they are always in positive values)
        if action == Award.ActionType.Subtract then amount = -amount end
        -- if a reset, set flat value based upon resource type
        if action == Award.ActionType.Reset then
            amount = (type == Award.ResourceType.Gp and AddOn:GearPointsModule().db.profile.gp_min or 0)
        end

        local function add(to, amt) return to + amt end
        local function reset(_, _) return amount end
        local function decay(amt, by)
            -- Logging:Debug("%d - math.floor(%d * %s) = %d", amt, amt, tostring(by), (amt - math.floor(amt * by)))
            return Util.Numbers.Round(amt - (amt * by))
        end

        local oper =
            action == Award.ActionType.Add and add or
            action == Award.ActionType.Subtract and add or
            action == Award.ActionType.Reset and reset or
            action == Award.ActionType.Decay and decay or
            nil -- intentional to find missing cases

        local function ep(amt) target.ep = oper(target.ep, amt) end
        local function gp(amt) target.gp = oper(target.gp, amt) end

        local targetFn =
            type == Award.ResourceType.Ep and ep or
            type == Award.ResourceType.Gp and gp or
            nil -- intentional to find missing cases

        targetFn(amount)
    end

    -- todo : if we want to record history entries after point adjustment then needs to be refactored to grab 'before' quantity
    -- todo : could pass in the actual update to be performed before sending

    -- if the award is for GP and there is an associated item that was awarded, create it first
    -- todo
    --[[
    local lhEntry
    if award.resourceType == Award.ResourceType.Gp and award.item then
        lhEntry = AddOn:LootHistoryModule():CreateFromAward(award)
    end
    --]]

    -- just one traffic history entry per award, regardless of number of subjects
    -- to which it applied
    -- todo
    -- AddOn:TrafficHistoryModule():CreateFromAward(award, lhEntry)

    -- subject is a tuple of (name, class)
    for _, subject in pairs(award.subjects) do
        local target = self:GetEntry(subject[1])
        if target then
            -- Logging:Debug("Adjust() : Processing %s", Objects.ToString(target:toTable()))
            apply(target, award.actionType, award.resourceType, award.resourceQuantity)
            -- don't apply to actual officer notes in test mode
            -- it will also fail if we cannot edit officer notes
            if (not AddOn:TestModeEnabled() and AddOn:PersistenceModeEnabled()) and CanEditOfficerNote() then
                -- todo : we probably need to see if this is successful, otherwise could be lost
                GuildStorage:SetOfficeNote(target.name, target:ToNote())
            else
                Logging:Debug("Adjust() : Skipping adjustment of EP/GP for '%s'", target.name)
            end
        else
            Logging:Warn("Adjust() : Could not locate %s for applying %s. Possibly not in guild?",
                    Util.Objects.ToString(subject),  Util.Objects.ToString(award:toTable())
            )
        end
    end

    -- announce what was done
    -- todo
    --[[
    local check, _ = pcall(function() AddOn:SendAnnouncement(award:ToAnnouncement(), AddOn.Constants.group) end)
    if not check then Logging:Warn("Award() : Unable to announce adjustment") end
    --]]

    -- todo : check for visible
    self:BuildData()
end
