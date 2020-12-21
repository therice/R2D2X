local _, AddOn = ...
local L, Util = AddOn.Locale, AddOn:GetLibrary("Util")
local HistoryPkg = AddOn.ImportPackage('Models.History')
local Date, History = AddOn.ImportPackage('Models').Date, HistoryPkg.Traffic
-- lazy memoization, only require once used
-- local UI = AddOn.RequireOnUse('UI.Util')

local ResponseOrigin = {
    Unknown             = 0,
    CandidateResponse   = 1,
    AwardReason         = 2,
}

--- @class Models.History.Loot
local Loot = HistoryPkg:Class('Loot', History)
Loot.ResponseOrigin = ResponseOrigin

--[[
Examples of Loot instance(s)
{
    {
        class = WARLOCK,
        instanceId = 469,
        encounterId = 612,
        item = |cffa335ee|Hitem:19374::::::::60:::::::|h[Bracers of Arcane Accuracy]|h|r,
        responseOrigin = 1,
        id = 1590803573-562,
        owner = Gnomechómsky-Atiesh,
        response = Main-Spec (Need),
        version = {minor = 0, patch = 0, major = 1},
        responseId = 1,
        timestamp = 1590803573,
    },
    {
        class = WARLOCK,
        instanceId = 469,
        encounterId = 617,
        item = |cffa335ee|Hitem:19376::::::::60:::::::|h[Archimtiros' Ring of Reckoning]|h|r,
        responseOrigin = 2,
        id = 1592017553-4948,
        owner = Gnomechómsky-Atiesh,
        response = Bank,
        version = {minor = 0, patch = 0, major = 1},
        responseId = 3
        timestamp = 1592017553,
    },
    {
        class = WARLOCK,
        instanceId = 469,
        encounterId = 614,
        item = |cffa335ee|Hitem:19407::::::::60:::::::|h[Ebony Flame Gloves]|h|r,
        mapId = 469,
        responseOrigin = 1,
        id = 1593225862-8223,
        owner = Gnomechómsky-Atiesh,
        response = Main-Spec (Need),
        version = {minor = 0, patch = 0, major = 1},
        timestamp = 1593225862,
        responseId = 1
    },
    {
        class = WARLOCK,
        instanceId = 531
        encounterId = nil,
        boss = Unknown,
        item = |cff0070dd|Hitem:21324::::::::60:::::::|h[Yellow Qiraji Resonating Crystal]|h|r,
        responseOrigin = 2,
        id = 1598058749-1270,
        owner = Gnomechómsky-Atiesh,
        response = Free,
        version = {minor = 0, patch = 0, major = 1},
        timestamp = 1598058749,
        responseId = 2,
    }
--]]
function Loot:initialize(instant)
    History.initialize(self, instant)
    -- link to the awarded item
    self.item = nil
    -- who received the item
    self.owner = nil
    -- the class of the winner
    self.class = nil
    -- identifier for map (instance id)
    self.instanceId = nil
    -- identifier for the encounter
    self.encounterId = nil
    -- number indicating if response was taken award reason (e.g. not from candidate's response)
    self.responseOrigin = ResponseOrigin.Unknown
    -- the text of the candidate's response or award reason
    self.response = nil
    -- the id of the candidate's response or award reason
    self.responseId = nil
end

function Loot:IsCandidateResponse()
    return self.responseOrigin == ResponseOrigin.CandidateResponse
end

function Loot:IsAwardReason()
    return self.responseOrigin == ResponseOrigin.AwardReason
end

function Loot:SetOrigin(fromAwardReason)
    self.responseOrigin =
        Util.Objects.Check(fromAwardReason, ResponseOrigin.AwardReason, ResponseOrigin.CandidateResponse)
end

function Loot:GetResponseId()
    -- see LootAllocate for the addition of 400
    return self:IsCandidateResponse() and self.responseId or self.responseId + 400
end

--function Loot:FormattedResponse()
--    return UI().ColoredDecorator(self.color):decorate(self.response)
--end
--
--function Loot:Description()
--    return format("[%s] %s %s",
--            self:FormattedTimestamp(),
--            UI().ClassColorDecorator(self.class):decorate(AddOn.Ambiguate(self.owner)),
--            self.item
--    )
--end

--- @class Models.History.LootStatistics
local LootStatistics = HistoryPkg:Class('LootStatistics')
--- @class Models.History.LootStatisticsEntry
local LootStatisticsEntry = HistoryPkg:Class('LootStatisticsEntry')
-- Loot Statistics
function LootStatistics:initialize()
    -- mapping from character name to associated stats
    self.entries = {}
end

function LootStatistics:Get(name)
    return self.entries[name]
end

function LootStatistics:GetOrAdd(name)
    local entry
    if not Util.Tables.ContainsKey(self.entries, name) then
        entry = LootStatisticsEntry()
        self.entries[name] = entry
    else
        entry = self.entries[name]
    end
    return entry
end


-- @param name the character's name
-- @param the loot history entry
-- @param the index of entry in the loot history
function LootStatistics:ProcessEntry(name, entry, entryIndex)
    -- force entry into class instance
    if not Loot:isInstanceOf(entry) then
        entry = Loot:reconstitute(entry)
    end
    
    -- Logging:Debug("ProcessEntry(%s) : %d => %s", name, entryIndex, Util.Objects.ToString(entry, 2))
    local currentTs = Date()
    local id = entry:GetResponseId()
    
    -- track the response
    local statEntry = self:GetOrAdd(name)
    -- Logging:Debug("ProcessEntry(%s) : AddResponse(%d, %d)", name, id, entryIndex)
    statEntry:AddResponse(
            id,
            entry.response,
            entryIndex
    )

    -- track the award (only numeric responses - ones that were presented to players)
    if Util.Objects.IsNumber(id) and not entry:IsAwardReason() then
        -- Logging:Debug("ProcessEntry(%s) : AddAward(%d, %s)", name, entryIndex, entry.item)
        local ts = entry:TimestampAsDate()
        statEntry:AddAward(
                entry.item,
                format(L["n_ago"], AddOn.ConvertIntervalToString(currentTs:diff(ts):Duration())),
                entryIndex
        )
    end
    
    -- Logging:Debug("ProcessEntry(%s) : %s", name,  entry.instance)
    statEntry:AddRaid(entry)
    return entry
end

function LootStatisticsEntry:initialize()
    -- array of awarded items
    self.awards = {}
    -- map of response id to array of responses
    self.responses = {}
    -- array of raids (with true as value place holder)
    self.raids = {}
    
    self.totals = {
        responses = {

        },
        raids = {

        }
    }
    self.totalled = false
end

function LootStatisticsEntry:AddRaid(entry)
    local instanceId = entry.instanceId
    -- not all awards will be from a raid
    if instanceId then
        if not self.raids[instanceId] then
            self.raids[instanceId] = {}
        end

        -- consider combination of instance id and date as a raid occurrence
        -- fuzzy as could be in the same raid across a change in day, but close neough
        if not Util.Tables.ContainsValue(self.raids[instanceId], entry:FormattedDate()) then
            Util.Tables.Push(self.raids[instanceId], entry:FormattedDate())
        end


        self.totalled = false
    end
end

function LootStatisticsEntry:AddResponse(id, response, historyIndex)
    if not Util.Tables.ContainsKey(self.responses, id) then
        self.responses[id] = {}
    end
    
    -- Logging:Debug("AddResponse(%d) : %s, %s, %d", id, Util.Objects.ToString(response),  Util.Objects.ToString(color), historyIndex)
    Util.Tables.Push(self.responses[id],
                     {
                         response,
                         historyIndex
                     }
    )
    
    self.totalled = false
end

function LootStatisticsEntry:AddAward(item, intervalText, historyIndex)
    Util.Tables.Push(self.awards,
                     {
                         item,
                         intervalText,
                         historyIndex
                     }
    )
    self.totalled = false
end

function LootStatisticsEntry:CalculatePending()
    return not self.totalled and
            (Util.Tables.Count(self.awards) > 0 or Util.Tables.Count(self.responses) > 0 or Util.Tables.Count(self.raids) > 0)
end

function LootStatisticsEntry:CalculateTotals()
    if self:CalculatePending() then
        -- the responses and number of responses
        for responseId, responses in pairs(self.responses) do
            local first = responses[1]
            local responseText = first[1]
            local count = Util.Tables.Count(responses)
            
            Util.Tables.Push(self.totals.responses,
                             {
                                 responseText,
                                 count,
                                 responseId
                             }
            )
        end
        
        self.totals.count = Util.Tables.CountFn(
                self.responses,
                function(r)
                    return Util.Tables.Count(r)
                end
        )

        local totalRaids = 0
        for raid, dates in pairs(self.raids) do
            local raidCount = Util.Tables.Count(dates)
            self.totals.raids[raid] = raidCount
            totalRaids = totalRaids + raidCount
        end
        self.totals.raids.count = totalRaids

        self.totalled = true
    end

    -- {raids = {409 = 1, 249 = 2, count = 10, 469 = 5, 531 = 2}, responses = {{Main-Spec (Need), 6, 1}, {Off-Spec (Greed), 1, 2}, {Disenchant, 3, 401}, {Free, 2, 402}, {Bank, 2, 403}}, count = 14}
    return self.totals
end

function LootStatisticsEntry:GetTotals()
    return self:CalculateTotals()
end