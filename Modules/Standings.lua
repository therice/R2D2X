--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibGuildStorage
local GuildStorage  = AddOn:GetLibrary("GuildStorage")
--- @type Models.Award
local Award = AddOn.Package('Models').Award
--- @type Models.Subject
local Subject = AddOn.Package('Models').Subject

--- @class Standings
local Standings = AddOn:NewModule('Standings',  "AceTimer-3.0")
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

local function Name(name)
    return Util.Objects.IsString(name) and name or name:GetName()
end

function Standings:_AddEntry(name, entry)
    self.subjects[Name(name)] = entry
    self.pendingUpdate = true
end

function Standings:_RemoveEntry(name)
    self.subjects[Name(name)] = nil
    self.pendingUpdate = true
end

--- @return Models.Subject
function Standings:GetEntry(name)
    return self.subjects[Name(name)]
end

function Standings.Points(name)
    local e = Standings:GetEntry(name)
    -- Logging:Trace("Points(%s) : %s", name, tostring(e and true or false))
    if e then return e:Points() end
    -- todo : just nil?
    return 0, 0, 0
end

-- todo : need to handle addition and removal of members to scrolling table
-- this is currently only invoked as part of officer's note changing, nothing else
function Standings:MemberModified(_, name, note)
    Logging:Trace("MemberModified(%s) : '%s'", name, note)
    -- don't need to remove, it overwrites
    -- name with be character-realm
    self:_AddEntry(name, Subject:FromGuildMember(GuildStorage:GetMember(name)))
end

function Standings:MemberDeleted(_, name)
    Logging:Trace("MemberDeleted(%s)", name)
    self._RemoveEntry(name)
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

function Standings:ShouldPersist()
    -- don't apply to actual officer notes in test mode or if persistence mode is disabled
    -- it will also fail if we cannot edit officer notes
    return (not AddOn:TestModeEnabled() and AddOn:PersistenceModeEnabled()) and CanEditOfficerNote()
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

    local shouldPersist = self:ShouldPersist()
    -- subject is a tuple of (name, class)
    for _, subject in pairs(award.subjects) do
        local target = self:GetEntry(subject[1])
        if target then
            -- Logging:Debug("Adjust() : Processing %s", Objects.ToString(target:toTable()))
            apply(target, award.actionType, award.resourceType, award.resourceQuantity)
            if shouldPersist then
                -- todo : we probably need to see if this is successful, otherwise could be lost
                error("Nope, shouldn't be happening yet in this version")
                GuildStorage:SetOfficeNote(target.name, target:ToNote())
            else
                Logging:Warn(
                    "Adjust(%d, %d, %.2f) : Skipping persistence of EP/GP adjustment for '%s' ",
                    award.actionType, award.resourceType, award.resourceQuantity, target.name
                )
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

function Standings:BulkAdjust(...)
    local awards = Util.Tables.New(...)
    Logging:Debug("BulkAdjust(%d)", #awards)
    if #awards == 0 then return end

    local shouldPersist = self:ShouldPersist()

    -- we do decay in multiple awards, one for EP and one for GP
    -- if we try to do them too quickly, the updates to player's officer note won't
    -- be written yet and could encounter a conflict
    --
    -- therefore, this function will manage that via performing adjustment
    -- and waiting for callbacks to determine that all have been completed before
    -- moving to next award
    local function adjust(awards, index)
        Logging:Trace("adjust() : %d / %d", #awards, index)

        -- we make no checks on index vs award count in callback, so check here
        if index <= #awards then
            local award = awards[index]
            Logging:Debug("adjust() : Processing %s", Util.Objects.ToString(award.resourceType))

            local updated, expected = 0, Util.Tables.Count(award.subjects)
            -- register callback with GuildStorage for notification when the officer note has been written
            -- keep track of updates and then when it matches the expected count, de-register callback
            -- and move on to next award
            if shouldPersist then
                GuildStorage.RegisterCallback(
                        Standings,
                        GuildStorage.Events.GuildOfficerNoteWritten,
                        function(event, _)
                            updated = updated + 1
                            Logging:Debug("%s : %d/%d", tostring(event), tostring(updated), tostring(expected))
                            if updated == expected then
                                Logging:Trace("Unregistering GuildStorage.Events.GuildOfficerNoteWritten and moving to award %d", index + 1)
                                GuildStorage.UnregisterCallback(Standings, GuildStorage.Events.GuildOfficerNoteWritten)
                                adjust(awards, index + 1)
                            end
                        end
                )
            end

            Standings:Adjust(award)
            -- if we were not persisting, the callbacks wont happen
            -- do it manually, could pass a function to Adjust() for callback, but seems excssive
            if not shouldPersist then
                adjust(awards, index + 1)
            end
        end
    end

    adjust(awards, 1)
end