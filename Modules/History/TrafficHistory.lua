--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.CompressedDb
local CDB = AddOn.ImportPackage('Models').CompressedDb
--- @type Models.History.Traffic
local Traffic =  AddOn.ImportPackage('Models.History').Traffic
--- @type Models.History.TrafficStatistics
local TrafficStatistics =  AddOn.ImportPackage('Models.History').TrafficStatistics
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')

--- @class TrafficHistory
local TrafficHistory = AddOn:NewModule("TrafficHistory", "AceEvent-3.0", "AceTimer-3.0")

TrafficHistory.defaults = {
	profile = {
		enabled = true,
	}
}

TrafficHistory.StatsIntervalInDays = 90

function TrafficHistory:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('TrafficDB'), TrafficHistory.defaults)
	self.history = CDB(self.db.factionrealm)
	self.stats = {stale = true, value = nil}
	self:SubscribeToPermanentComms()
end

function TrafficHistory:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self.frame = self:GetFrame()
	self:BuildData()
	self:Show()
end

function TrafficHistory:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:Hide()
end

function TrafficHistory:EnableOnStartup()
	return false
end

--- @return Models.CompressedDb
function TrafficHistory:GetHistory()
	return self.history
end

--- @param award Models.Award
--- @param lhEntry Models.History.Loot
function TrafficHistory:CreateFromAward(award, lhEntry)
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end

	local entry = Traffic(award.timestamp, award)
	entry.actor = AddOn.player:GetName()
	entry.actorClass = AddOn.player.class
	entry:Finalize()

	-- if we have a loot history entry associated with traffic (awards)
	if lhEntry then
		-- copy over attributes to traffic entry which are relevant
		-- could ignore them and rely upon loot history for later retrieval, but there's no guarantee
		-- the loot and traffic histories are not pruned independently
		entry.lootHistoryId = lhEntry.id
		entry.item = lhEntry.item
		entry.responseId = lhEntry.responseId
		entry.response = lhEntry.response
	end

	if award.item then
		entry.baseGp = entry.item.baseGp
		entry.awardScale = entry.item.awardScale
	end

	AddOn:Send(C.group, C.Commands.TrafficHistoryAdd, entry)
	return entry
end

--- @param entry Models.History.Traffic
function TrafficHistory:OnTrafficHistoryAdd(entry)
	self:GetHistory():insert(entry:toTable())
	self.stats.stale = true
end

function TrafficHistory:SubscribeToPermanentComms()
	Logging:Debug("SubscribeToPermanentComms(%s)", self:GetName())
	Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.TrafficHistoryAdd] = function(data, sender)
			Logging:Debug("TrafficHistoryAdd from %s", tostring(sender))
			local entry = Traffic:reconstitute(unpack(data))
			self:OnLootHistoryAdd(entry)
		end
	})
end

local cpairs = CDB.static.pairs
--- @return Models.History.TrafficStatistics
function TrafficHistory:GetStatistics()
	local check, ret = pcall(
			function()
				--Logging:Debug("GetStatistics() : %s", Objects.ToString(stats, 2))
				if self.stats.stale or Util.Objects.IsNil(self.stats.value) then
					local cutoff = Date()
					cutoff:add{day = -TrafficHistory.StatsIntervalInDays}
					Logging:Debug("GetStatistics() : Processing History after %s", tostring(cutoff))

					local s = TrafficStatistics()
					for _, entryTable in cpairs(self:GetHistory()) do
						-- Logging:Debug("GetStatistics() : Processing Entry")
						local entry = Traffic:reconstitute(entryTable)
						local ts = Date(entry.timestamp)

						if ts > cutoff then
							s:ProcessEntry(entry)
						end
					end

					self.stats.stale = false
					self.stats.value = s
				end

				return self.stats.value
			end
	)

	if not check then
		Logging:Warn("Error processing Traffic History : %s", tostring(ret))
		AddOn:Print("Error processing Traffic History")
	else
		return ret
	end
end

