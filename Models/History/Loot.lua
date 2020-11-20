local _, AddOn = ...
local L, Util = AddOn.Locale, AddOn:GetLibrary("Util")
local HistoryPkg = AddOn.ImportPackage('Models.History')
local Date, History = AddOn.ImportPackage('Models').Date, HistoryPkg.Traffic
-- lazy memoization, only require once used
local UI = AddOn.RequireOnUse('UI.Util')

local ResponseOrigin = {
    Unknown             = 0,
    CandidateResponse   = 1,
    AwardReason         = 2,
}

local Loot = HistoryPkg:Class('Loot', History)
Loot.ResponseOrigin = ResponseOrigin

function Loot:initialize(instant)
    History.initialize(self, instant)
    -- link to the awarded item
    self.item = nil
    self.itemTypeId = nil
    self.itemSubTypeId = nil
    -- who received the item
    self.owner = nil
    -- identifier for map (instance id)
    self.mapId = nil
    -- the instance name
    self.instance = nil
    -- the instance boss (or unknown)
    self.boss = _G.UNKNOWN
    -- the text of the candidate's response or award reason
    self.response = nil
    -- the id of the candidate's response or award reason
    self.responseId = nil
    -- number indicating if response was taken award reason (e.g. not from candidate's response)
    self.responseOrigin = ResponseOrigin.Unknown
    -- the display color of the candidate's response or award reason
    self.color = nil
    -- the class of the winner
    self.class = nil
    -- size of group in which the item ws won
    self.groupSize = nil
    -- any note provided by candidate when responding
    self.note = nil
    -- the response type code
    self.typeCode = nil
end

function Loot:IsCandidateResponse()
    return self.responseOrigin == ResponseOrigin.CandidateResponse
end

function Loot:IsAwardReason()
    return self.responseOrigin == ResponseOrigin.AwardReason
end

function Loot:SetOrigin(fromAwardReason)
    local origin = (fromAwardReason and ResponseOrigin.AwardReason) or ResponseOrigin.CandidateResponse
    self.responseOrigin = origin
end

function Loot:FormattedResponse()
    return UI().ColoredDecorator(self.color):decorate(self.response)
end

function Loot:Description()
    return format("[%s] %s %s",
            self:FormattedTimestamp(),
            UI().ClassColorDecorator(self.class):decorate(AddOn.Ambiguate(self.owner)),
            self.item
    )
end

local LootStatistics = HistoryPkg:Class('LootStatistics')
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
    if not Loot.isInstanceOf(entry, Loot) then
        entry = Loot:reconstitute(entry)
    end
    
    -- Logging:Debug("ProcessEntry(%s) : %d => %s", name, entryIndex, Util.Objects.ToString(entry, 2))
    local currentTs = Date()
    local id = entry.responseId
    if Util.Objects.IsNumber(id) then
        -- Bump to distinguish from normal awards
        if entry:IsAwardReason() then id = id + 100 end
    end
    
    -- track the response
    local statEntry = self:GetOrAdd(name)
    -- Logging:Debug("ProcessEntry(%s) : AddResponse(%d, %d)", name, id, entryIndex)
    statEntry:AddResponse(
            id,
            entry.response,
            #entry.color ~= 0 and #entry.color == 4 and entry.color or { 1, 1, 1 },
            entryIndex
    )
    
    -- todo : respect number of awards to show
    -- track the award (only numeric responses - ones that were presented to players)
    if Util.Objects.IsNumber(id) and not entry:IsAwardReason() then
        -- Logging:Debug("ProcessEntry(%s) : AddAward(%d, %s)", name, entryIndex, entry.item)
        local ts = entry:TimestampAsDate()
        statEntry:AddAward(
                entry.item,
                format(L["n_ago"], AddOn.ConvertIntervalToString(currentTs:diff(ts):Duration())),
                #entry.color ~= 0 and #entry.color == 4 and entry.color or {1,1,1},
                entryIndex
        )
    end
    
    -- Logging:Debug("ProcessEntry(%s) : %s", name,  entry.instance)
    
    statEntry:AddRaid(entry:FormattedDate() .. "_" .. entry.instance)
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

function LootStatisticsEntry:AddRaid(raid)
    if not Util.Tables.ContainsKey(self.raids, raid) then
        self.raids[raid] = true
    end
    
    self.totalled = false
end

function LootStatisticsEntry:AddResponse(id, response, color, historyIndex)
    if not Util.Tables.ContainsKey(self.responses, id) then
        self.responses[id] = {}
    end
    
    -- Logging:Debug("AddResponse(%d) : %s, %s, %d", id, Util.Objects.ToString(response),  Util.Objects.ToString(color), historyIndex)
    Util.Tables.Push(self.responses[id],
                     {
                         response,
                         color,
                         historyIndex
                     }
    )
    
    self.totalled = false
end

function LootStatisticsEntry:AddAward(item, intervalText, color, historyIndex)
    Util.Tables.Push(self.awards,
                     {
                         item,
                         intervalText,
                         color,
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
            local color =  first[2]
            local count = Util.Tables.Count(responses)
            
            Util.Tables.Push(self.totals.responses,
                             {
                                 responseText,
                                 count,
                                 color,
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
        
        -- the raids and number of raids
        self.totals.raids = Util(self.raids):Keys():Copy()()
        self.totals.raids.count = Util.Tables.Count(self.totals.raids)
        self.totalled = true
    end

    return self.totals
end

function LootStatisticsEntry:GetTotals()
    self:CalculateTotals()
    return self.totals
end