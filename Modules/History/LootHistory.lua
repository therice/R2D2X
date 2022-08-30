--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Models.CompressedDb
local CDB = AddOn.ImportPackage('Models').CompressedDb
--- @type Models.History.Loot
local Loot =  AddOn.ImportPackage('Models.History').Loot
--- @type Models.History.LootStatistics
local LootStatistics =  AddOn.ImportPackage('Models.History').LootStatistics
--- @type Models.Date
local Date = AddOn.ImportPackage('Models').Date
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')

--- @class LootHistory
local LootHistory = AddOn:NewModule("LootHistory")

LootHistory.defaults = {
	profile = {
		enabled = true,
	}
}
LootHistory.StatsIntervalInDays = 90

function LootHistory:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.Libs.AceDB:New(AddOn:Qualify('LootDB'), LootHistory.defaults)
	self.history = CDB(self.db.factionrealm)
	self.stats = {stale = true, value = nil}
	self:SubscribeToPermanentComms()
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			L['loot_history'],
			function() return self:GetDataForSync() end,
			function(data) self:ImportDataFromSync(data) end
	)
end

function LootHistory:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self.frame = self:GetFrame()
	self:BuildData()
	self:Show()
end

function LootHistory:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:Hide()
end

function LootHistory:EnableOnStartup()
	return false
end

--- @return Models.CompressedDb
function LootHistory:GetHistory()
	return self.history
end

--- @param award Models.Award
function LootHistory:CreateFromAward(award)
	-- if in test mode and not development mode, return
	if (AddOn:TestModeEnabled() and not AddOn:DevModeEnabled()) then return end
	if not award.item then error("award has not associated item") end

	--- @type Models.Item.ItemAward
	local itemAward = award.item
	local entry = Loot(award.timestamp)
	entry.item = itemAward.link
	entry.owner = itemAward.owner
	entry.class = itemAward.class
	entry.instanceId = award.instanceId
	entry.encounterId = award.encounterId
	entry.note = itemAward.note
	local nr = itemAward:NormalizedReason()
	entry:SetOrigin(Util.Objects.Check(Util.Objects.IsEmpty(itemAward.reason), false, true))
	entry.response = nr.text
	entry.responseId = nr.id

	AddOn:Send(C.group, C.Commands.LootHistoryAdd, entry)

	return entry
end

--- @param entry Models.History.Loot
function LootHistory:OnLootHistoryAdd(entry)
	local winner, history = entry.winner, self:GetHistory()
	local winnerHistory = history:get(winner)
	if winnerHistory then
		winnerHistory:insert(entry:toTable(), winner)
	else
		winnerHistory:put(winner, {entry:toTable()})
	end
	self.stats.stale = true
end

function LootHistory:SubscribeToPermanentComms()
	Logging:Debug("SubscribeToPermanentComms(%s)", self:GetName())
	Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.LootHistoryAdd] = function(data, sender)
			Logging:Debug("LootHistoryAdd from %s", tostring(sender))
			local entry = Loot:reconstitute(unpack(data))
			self:OnLootHistoryAdd(entry)
		end
	})
end

local cpairs = CDB.static.pairs
--- @return Models.History.LootStatistics
function LootHistory:GetStatistics()
	Logging:Trace("GetStatistics()")
	local check, ret = pcall(
			function()
				if self.stats.stale or Util.Objects.IsNil(self.stats.value) then
					local cutoff = Date()
					cutoff:add{day = -LootHistory.StatsIntervalInDays}
					Logging:Debug("GetStatistics() : Processing History after %s", tostring(cutoff))

					local s = LootStatistics()
					for name, data in cpairs(self:GetHistory()) do
						for i = #data, 1, -1 do
							local entry = Loot:reconstitute(data[i])
							local ts = Date(entry.timestamp)
							if ts > cutoff then
								s:ProcessEntry(name, entry, i)
							end
						end
					end

					self.stats.stale = false
					self.stats.value = s
				end

				return self.stats.value
			end
	)

	if not check then
		Logging:Warn("Error processing Loot History : %s", tostring(ret))
		AddOn:Print("Error processing Loot History")
	else
		return ret
	end
end

function LootHistory:GetDataForSync()
	Logging:Debug("LootHistory:GetDataForSync()")
	if AddOn:DevModeEnabled() then
		Logging:Debug("LootHistory:GetDataForSync() : %d", Util.Tables.Count(self.db.factionrealm))

		local db = self.db.factionrealm
		local rkeys = {}

		while Util.Tables.Count(rkeys) < math.min(4, Util.Tables.Count(db)) do
			local rkey = Util.Tables.RandomKey(db)
			if not Util.Tables.ContainsKey(rkey) then
				rkeys[rkey] = true
			end
		end

		Logging:Debug("LootHistory:GetDataForSync() : randomly selected keys are %s", Util.Objects.ToString(Util.Tables.Keys(rkeys)))
		return Util.Tables.CopySelect(db, unpack(Util.Tables.Keys(rkeys)))
	else
		return self.db.factionrealm
	end
end


function LootHistory:ImportDataFromSync(data)
	Logging:Debug("LootHistory:ImportDataFromSync() : current history player count is %d, import history player count is %d",
	              Util.Tables.Count(self.db.factionrealm),
	              Util.Tables.Count(data)
	)

	local persist = (not AddOn:DevModeEnabled() and AddOn:PersistenceModeEnabled()) or AddOn._IsTestContext()
	if Util.Tables.Count(data) > 0 then
		local cdb = CDB(data)
		local imported, skipped = 0, 0
		for name, history in cpairs(cdb) do
			local charHistory = self.history:get(name)

			Logging:Debug("LootHistory:ImportDataFromSync(%s)", tostring(name))

			if not charHistory then
				Logging:Debug("LootHistory:ImportDataFromSync(%s) : no previous history, creating and populating", name)
				if persist then
					self.history:put(name, history)
				end
				imported = imported + #history
			else
				Logging:Debug("LootHistory:ImportDataFromSync(%s) : pre-existing history (count=%d), examining each entry", name, #charHistory)
				local function FindExistingEntry(importe)
					return Util.Tables.FindFn(
							charHistory,
							function(e)
								-- Logging:Debug("%d == %d, %s == %s", e.timestamp, importe.timestamp, tostring(e.item), tostring(importe.item))
								return e.timestamp == importe.timestamp and Util.Strings.Equal(e.item, importe.item)
							end
					)
				end

				for _, entryTable in pairs(history) do
					Logging:Debug("LootHistory:ImportDataFromSync(%s, %s) : examining import entry", name, entryTable.id)
					local _, existing = FindExistingEntry(entryTable)
					if existing then
						Logging:Debug("LootHistory:ImportDataFromSync(%s, %s) : found existing entry in history, skipping...", name, entryTable.id)
						skipped = skipped + 1
					else
						Logging:Debug("LootHistory:ImportDataFromSync(%s, %s) : entry does not exist in history, adding...", name, entryTable.id)
						if persist then
							self.history:insert(entryTable, name)
						end
						imported = imported + 1
					end
				end
			end
		end

		if imported > 0 then
			self.stats.stale = true
			if self:IsEnabled() and self.frame and self.frame:IsVisible() then
				self:BuildData()
			end
		end

		Logging:Debug("LootHistory:ImportDataFromSync(%s) : imported %s history entries, skipped %d import history entries, new history player entry count is %d",
		              tostring(persist),
		              imported,
		              skipped,
		              Util.Tables.Count(self.db.factionrealm)
		)
		AddOn:Print(format(L['import_successful_with_count'], AddOn.GetDateTime(), self:GetName(), imported))
	else
		AddOn:Print(format(L['import_successful_with_count'], AddOn.GetDateTime(), self:GetName(), 0))
	end
end