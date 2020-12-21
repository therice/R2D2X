--- @type AddOn
local _, AddOn = ...
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
local HistoryPkg = AddOn.ImportPackage('Models.History')
--- @type Models.Award
local Award = AddOn.ImportPackage('Models').Award
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Models.History.History
local History = HistoryPkg.History

-- lazy memoization, only require once used
-- local UI = AddOn.RequireOnUse('UI.Util')

--- @class Models.History.Traffic
local Traffic = HistoryPkg:Class('Traffic', History)
--- @param data Models.Award
function Traffic:initialize(instant, data)
    History.initialize(self, instant)
    
    -- the name of the actor which performed the action
    self.actor = nil
    -- the class of the actor which performed the action
    self.actorClass = nil
    -- the value of the resource before the action
    self.resourceBefore = nil
    -- an optional identifier for the loot history entry associated with this traffic entry
    -- this will only be set for GP resource types and as a result of that loot
    -- being awarded to this entry's subject
    self.lootHistoryId = nil
    
    if data then
        if not data.clazz or not data:isInstanceOf(Award) then
            -- type was table
            Logging:Error("The specified data was not of the correct type - %s", Util.Objects.ToString(data))
            error("The specified data was not of the correct type : " .. type(data))
        end
        Util.Tables.CopyInto(self, data:toTable())
        -- if there was an item with data, nil it out - we don't need entire thing
        self.item = nil
    end
    
    --[[
    There are additional (optional) attributes which may be set based upon origin of traffic. Examples are below

    E.G. EP/GP awards from encounter will have instanceId and encounterId attributes
    E>G. GP award from an item allocation will have item (link), response attributes (id, text), before/after resource values, and id of loot history entry
    
    If a traffic entry is created from a user initiated action, such as manual award of GP/EP, then these
    attributes won't be present

    {
        resourceQuantity = 15,
        description = Awarded 15 EP for Razorgore the Untamed (Victory),
        instanceId = 469,
        encounterId = 610,
        id = 1602461696-0,
        subjects = {{...}, {...}, ...},
        resourceType = 1,
        version = {minor = 0, patch = 0, major = 1},
        subjectType = 3,
        timestamp = 1602461696,
        actionType = 1,
        actor = Gnomechómsky-Atiesh,
        actorClass = WARLOCK
    }
    {
        resourceQuantity = 0.1,
        description = Decay on 10/13/2020,
        id = 1602616150-1904,
        subjects = {{...}, {...}, ...},
        resourceType = 1,
        version = {minor = 0, patch = 0, major = 1},
        subjectType = 2,
        timestamp = 1602616150,
        actionType = 4,
        actor = Gnomechómsky-Atiesh,
        actorClass = WARLOCK
    }
    {
        baseGp = 34,
        description = Awarded |cffa335ee|Hitem:16934::::::::60:::::::|h[Nemesis Bracers]|h|r for |cff3fc6eaDisenchant|r,
        subjects = {{Avalona-Atiesh, WARLOCK}},
        instanceId = 469,
        encounterId = 610,
        item = |cffa335ee|Hitem:16934::::::::60:::::::|h[Nemesis Bracers]|h|r,
        resourceBefore = 68,
        actorClass = WARLOCK,
        resourceQuantity = 0,
        id = 1602461756-1840,
        responseId = 1,
        timestamp = 1602461756,
        response = Disenchant,
        resourceType = 2,
        lootHistoryId = 1602461756-1839,
        version = {minor = 0, patch = 0, major = 1},
        awardScale = 0, a
        actor = Gnomechómsky-Atiesh,
        actionType = 1,
        subjectType = 1
    }
    {
        baseGp = 52,
        description = Awarded |cffa335ee|Hitem:19336::::::::60:::::::|h[Arcane Infused Gem]|h|r for |cfffff468Off-Spec (Greed)|r,
        subjects = {{Keelut-Atiesh, HUNTER}},
        instanceId = 469,
        encounterId = 610,
        item = |cffa335ee|Hitem:19336::::::::60:::::::|h[Arcane Infused Gem]|h|r,
        resourceBefore = 15,
        actorClass = WARLOCK,
        resourceQuantity = 20,
        id = 1602461770-3692,
        responseId = 2,
        timestamp = 1602461770,
        response = Off-Spec (Greed),
        resourceType = 2,
        lootHistoryId = 1602461770-3691,
        version = {minor = 0, patch = 0, major = 1},
        awardScale = 0.5,
        actor = Gnomechómsky-Atiesh,
        actionType = 1,
        subjectType = 1
    }
    --]]
end

function Traffic:Finalize()
    -- this step only applicable for individual characters
    if self.subjectType == Award.SubjectType.Character and Util.Tables.Count(self.subjects) == 1 then
        if self.resourceType then
            --Logging:Debug('Finalize(%s) : %s', self.subjects[1], AddOn.Ambiguate(self.subjects[1]))
            local ep, gp, _ = AddOn:StandingsModule().Points(self.subjects[1][1])
            if self.resourceType == Award.ResourceType.Ep then
                self.resourceBefore = ep
            elseif self.resourceType == Award.ResourceType.Gp then
                self.resourceBefore = gp
            end
        end
    end
end

--[[
function Traffic:Description()
    local subject = ""
    if self.subjectType == Award.SubjectType.Character then
        subject = UI().ClassColorDecorator(self.subjects[1][2]):decorate(AddOn.Ambiguate(self.subjects[1][1]))
    else
        subject = UI().SubjectTypeDecorator(self.subjectType):decorate(Award.TypeIdToSubject[self.subjectType])
    end

    return format("[%s] %s (%s %s)",
            self:FormattedTimestamp(),
            subject,
            UI().ActionTypeDecorator(self.actionType):decorate(Award.TypeIdToAction[self.actionType]),
            UI().ResourceTypeDecorator(self.resourceType):decorate(Award.TypeIdToResource[self.resourceType]:upper())
    )
end
--]]

--- @class Models.History.TrafficStatistics
local TrafficStatistics = HistoryPkg:Class('TrafficStatistics')
--- @class Models.History.TrafficStatisticsEntry
local TrafficStatisticsEntry = HistoryPkg:Class('TrafficStatisticsEntry')
-- Traffic Statistics summary (useful for total raids)
TrafficStatistics.Summary = "summary"

function TrafficStatistics:initialize()
    -- mapping from character name to associated stats
    self.entries = {}
    self.entries[TrafficStatistics.Summary] = TrafficStatisticsEntry()
end

function TrafficStatistics:Get(name)
    return self.entries[name]
end

function TrafficStatistics:GetOrAdd(name)
    local entry
    
    --Logging:Debug("GetOrAdd(%s) : %s", name,  AddOn:UnitName(name))
    -- a previous regression existed where names were stored without realm
    -- so we need to patch up the name to make sure we get the actual data
    name = AddOn:UnitName(name)
    
    if not Util.Tables.ContainsKey(self.entries, name) then
        entry = TrafficStatisticsEntry()
        self.entries[name] = entry
    else
        entry = self.entries[name]
    end
    return entry
end

function TrafficStatistics:ProcessEntry(entry)
    -- force entry into class instance
    if not Traffic:isInstanceOf(entry) then
        entry = Traffic:reconstitute(entry)
    end
    
    local appliesTo = Util(entry.subjects):Copy(function(subject) return subject[1] end):Flip()()
    local stats = Util(appliesTo):Copy(function(_, name) return self:GetOrAdd(name) end, true)()
    for _, si in pairs(stats) do
        si:AddAward(entry)
        si:AddRaid(entry)
    end

    -- add to the summary, we don't do this with awards
    self:Get(self.Summary):AddRaid(entry)
end

function TrafficStatisticsEntry:initialize()
    self.awards = {
        [Award.ResourceType.Ep] = {},
        [Award.ResourceType.Gp] = {},
    }

    self.raids = {

    }

    self.totals = {
        awards = {
            [Award.ResourceType.Ep] = {},
            [Award.ResourceType.Gp] = {},
        },
        raids = {

        }
    }
    self.totalled = false
end

function TrafficStatisticsEntry:AddRaid(award)
    local instanceId = award.instanceId
    -- not all awards will be from a raid
    if instanceId then
        if not self.raids[instanceId] then
            self.raids[instanceId] = {}
        end

        -- consider combination of instance id and date as a raid occurrence
        -- fuzzy as could be in the same raid across a change in day, but close neough
        if not Util.Tables.ContainsValue(self.raids[instanceId], award:FormattedDate()) then
            Util.Tables.Push(self.raids[instanceId], award:FormattedDate())
        end
    end

    self.totalled = false
end

function TrafficStatisticsEntry:AddAward(award)
    if not Util.Tables.ContainsKey(self.awards, award.resourceType) then
       self.awards[award.resourceType] = {}
    end
    
    -- print(Objects.ToString(award, 2))
    -- this tracks resource type to action and amount
    Util.Tables.Push(
            self.awards[award.resourceType],{
                award.actionType,
                award.resourceQuantity,
    })

    self.totalled = false
end

function TrafficStatisticsEntry:CalculatePending()
    return not self.totalled and Util.Tables.Count(self.awards) > 0
end

function TrafficStatisticsEntry:CalculateTotals()
    if self:CalculatePending() then
        for rt, actions in pairs(self.awards) do
            local totals = 0
            local awards = 0
            local decays = 0
            local resets = 0
            
            for _, op in pairs(actions) do
                local o, q = unpack(op)
                if o == Award.ActionType.Add then
                    totals = totals + q
                    awards = awards + 1
                elseif o == Award.ActionType.Subtract then
                    totals = totals - q
                    awards = awards + 1
                elseif o == Award.ActionType.Reset then
                    resets = resets + 1
                elseif o == Award.ActionType.Decay then
                    decays = decays + 1
                end
            end

            self.totals.awards[rt] = {
                count  = 0,
                total  = 0,
                resets = 0,
                decays = 0,
            }
            
            self.totals.awards[rt].count = awards
            self.totals.awards[rt].total = totals
            self.totals.awards[rt].resets = resets
            self.totals.awards[rt].decays = decays
        end

        local totalRaids = 0
        for raid, dates in pairs(self.raids) do
            local raidCount = Util.Tables.Count(dates)
            self.totals.raids[raid] = raidCount
            totalRaids = totalRaids + raidCount
        end

        self.totals.raids.count = totalRaids
        self.totalled = true
    end
    
    -- index for wards is the resource type (i.e. EP and GP)
    -- {awards = {{decays = 1, total = 275, count = 16, resets = 0}, {decays = 1, total = 0, count = 0, resets = 0}}, raids = {count = 8, 533 = {count = 2}, 469 = {count = 2}, 409 = {count = 2}, 531 = {count = 2}}}
    return self.totals
end