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
	AddOn:SyncModule():AddHandler(
			self:GetName(),
			L['traffic_history'],
			function () return self:GetDataForSync() end,
			function(data) self:ImportDataFromSync(data) end
	)
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
			self:OnTrafficHistoryAdd(entry)
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

function TrafficHistory:GetDataForSync()
	Logging:Debug("TrafficHistory:GetDataForSync()")
	if AddOn:DevModeEnabled() then
		Logging:Debug("TrafficHistory:GetDataForSync() : count=%d", Util.Tables.Count(self.db.factionrealm))

		local db = self.db.factionrealm
		local send = {}

		while Util.Tables.Count(send) < math.min(10, Util.Tables.Count(db)) do
			local v = Util.Tables.Random(db)
			if Util.Objects.IsString(v) then
				table.insert(send, v)
			end
		end


		Logging:Debug("TrafficHistory:GetDataForSync() : randomly selected entries count is %d", #send)
		return send
	else
		return self.db.factionrealm
	end
end

function TrafficHistory:ImportDataFromSync(data)
	Logging:Debug("TrafficHistory:ImportDataFromSync() : current history count is %d, import history count is %d",
	              Util.Tables.Count(self.db.factionrealm),
	              Util.Tables.Count(data)
	)

	local persist = (not AddOn:DevModeEnabled() and AddOn:PersistenceModeEnabled()) or AddOn._IsTestContext()
	if Util.Tables.Count(data) > 0 then
		-- make a copy of current history and sort it by timestamp
		-- will take a one time hit here, but will make searching able to be short circuited when
		-- timestamp of existing history is past any import entry
		local orderedHistory = {}
		for _, e in cpairs(self.history) do table.insert(orderedHistory, e) end
		Util.Tables.Sort(orderedHistory, function(a, b) return a.timestamp < b.timestamp end)

		local function FindExistingEntry(importe)
			for i , e in pairs(orderedHistory) do
				-- if we've gone further into future than import record, it won't be found
				if e.timestamp > importe.timestamp then
					Logging:Debug(
							"TrafficHistory:FindExistingEntry(%s) : current history ts '%d' is after import ts '%d', aborting search...",
							e.id, e.timestamp, importe.timestamp
					)
					break
				end

				if e.timestamp == importe.timestamp then
					Logging:Debug(
							"TrafficHistory:FindExistingEntry(%s) : current history ts '%d' is equal to import ts '%d', performing final evaluation",
							e.id, e.timestamp, importe.timestamp
					)

					-- possibly too precise checking all of these, but ...
					if  (e.subjectType == importe.subjectType) and
						(e.resourceType == importe.resourceType) and
						(e.actionType == importe.actionType) and
						(#e.subjects == #importe.subjects) then
						return i, e
					end
				end
			end
		end

		local cdb = CDB(data)
		local imported, skipped = 0, 0
		for _, entryTable in cpairs(cdb) do
			Logging:Debug("TrafficHistory:ImportDataFromSync(%s) : examining import entry", entryTable.id)
			local _, existing = FindExistingEntry(entryTable)
			if existing then
				Logging:Debug("TrafficHistory:ImportDataFromSync(%s) : found existing entry in history, skipping...", entryTable.id)
				skipped = skipped + 1
			else
				Logging:Debug("TrafficHistory:ImportDataFromSync(%s) : entry does not exist in history, adding...", entryTable.id)
				if persist then
					self.history:insert(entryTable)
				end
				imported = imported + 1
			end
		end

		if imported > 0 then
			self.stats.stale = true
			if self:IsEnabled() and self.frame and self.frame:IsVisible() then
				self:BuildData()
			end
		end

		Logging:Debug("TrafficHistory:ImportDataFromSync(%s) : imported %s history entries, skipped %d import history entries, new history entry count is %d",
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