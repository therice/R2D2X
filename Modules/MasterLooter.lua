--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Models.Item.LootSlotInfo
local LootSlotInfo = AddOn.Package('Models.Item').LootSlotInfo
--- @type Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item').LootTableEntry
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type MasterLooterDb
local MasterLooterDb = AddOn.Require('MasterLooterDb')

--- @class MasterLooter
local ML = AddOn:NewModule("MasterLooter", "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0", "AceHook-3.0")

local AutoAwardType = {
	Equipable    = 1,
	NotEquipable = 2,
	All          = 99,
}

local AutoAwardRepItemsMode = {
	Person     = 1,
	RoundRobin = 2
}

ML.Defaults = {
	profile = {
		-- various types of usage for add-on
		usage = {
			never  = false,
			ml     = false,
			ask_ml = true,
			state  = "ask_ml",
		},
		-- should it only be enabled in raids
		onlyUseInRaids = true,
		-- is 'out of raid' support enabled (specifies auto-responses when user not in instance, but in raid)
		outOfRaid = false,
		-- should a session automatically be started with all eligible items
		autoStart  = false,
		-- automatically add all eligible equipable items to session
		autoAdd = true,
		-- automatically add all eligible non-equipable items to session (e.g. mounts)
		autoAddNonEquipable = false,
		-- automatically add all BoE (Bind on Equip) items to a session
		autoAddBoe = false,
		-- how long does a candidate have to respond to an item
		timeout = 60,
		-- are player's responses available (shown) in the loot dialogue
		showLootResponses = false,
		-- are whispers supported for candidate responses
		acceptWhispers = true,
		-- are awards announced via specified channel
		announceAwards = true,
		-- where awards are announced, table of channel + message pairs
		announceAwardText =  {
			{ channel = "group", text = "&p was awarded &i for &r (&g GP)"},
		},
		-- are items under consideration announced via specified channel
		announceItems = true,
		-- the prefix/preamble to use for announcing items
		announceItemPrefix = "Items under consideration:",
		-- where items are announced, channel + message
		announceItemText = { channel = "group", text = "&s: &i (&g GP)"},
		-- are player's responses to items announced via specified channel
		announceResponses = true,
		-- where player's responses to items are announced, channel + message
		announceResponseText = { channel = "group", text = L["response_to_item_detailed"]},
		-- enables the auto-awarding of items that meet specific criteria
		autoAward = false,
		-- what types of items should be auto-awarded, supports
		-- equipable, non-equipable, and all currently
		autoAwardType = AutoAwardType.Equipable,
		-- the lower threshold for item quality for auto-award
		autoAwardLowerThreshold = 2,
		-- the upper threshold for item quality for auto-award
		autoAwardUpperThreshold = 2,
		-- to whom any auto-awarded items should be assigned
		autoAwardTo = _G.NONE,
		-- the reason associated with auto-awarding of items
		autoAwardReason = 3, -- bank
		-- enables the auto-awarding of reputation items
		autoAwardRepItems = false,
		-- what is the mode use for auto-award of reputation items
		autoAwardRepItemsMode = AutoAwardRepItemsMode.Person,
		-- for tracking state of auto-awarding of rep items via RR, as needed
		-- this allows reloads/relogs to not lose current status
		autoAwardRepItemsState = {},
		-- to whom any auto-awarded reputation items should be assigned
		autoAwardRepItemsTo = _G.NONE,
		-- the reason associated with auto-awarding of reputation items
		autoAwardRepItemsReason = 3, -- bank
		-- dynamically constructed in BuildConfigOptions()
		-- example data left behind for illustration
		-- we don't support multiple categories/types of buttons, only the 'default'
		buttons = {
		--[[
		  numButtons = 4,
		  { text = L["ms_need"],          whisperKey = L["whisperkey_ms_need"], },
		  { text = L["os_greed"],         whisperKey = L["whisperkey_os_greed"], },
		  { text = L["minor_upgrade"],    whisperKey = L["whisperkey_minor_upgrade"], },
		  { text = L["pvp"],              whisperKey = L["whisperkey_pvp"], },
		--]]
		},
		-- we don't support multiple categories/types of responses, only the 'default'
		responses = {
			AWARDED         =   { color = C.Colors.White,		    sort = 0.1,	text = L["awarded"], },
			NOTANNOUNCED    =   { color = C.Colors.Fuchsia,		    sort = 501,	text = L["not_announced"], },
			ANNOUNCED		=   { color = C.Colors.Fuchsia,		    sort = 502,	text = L["announced_awaiting_answer"], },
			WAIT			=   { color = C.Colors.LuminousYellow,	sort = 503,	text = L["candidate_selecting_response"], },
			TIMEOUT			=   { color = C.Colors.LuminousOrange,	sort = 504,	text = L["candidate_no_response_in_time"], },
			REMOVED			=   { color = C.Colors.Pumpkin,	        sort = 505,	text = L["candidate_removed"], },
			NOTHING			=   { color = C.Colors.Nickel,	        sort = 506,	text = L["offline_or_not_installed"], },
			PASS		    =   { color = C.Colors.Aluminum,	    sort = 800,	text = _G.PASS, },
			AUTOPASS		=   { color = C.Colors.Aluminum,	    sort = 801,	text = L["auto_pass"], },
			DISABLED		=   { color = C.Colors.AdmiralBlue,	    sort = 802,	text = L["disabled"], },
			NOTINRAID		=   { color = C.Colors.Marigold, 	    sort = 803, text = L["not_in_instance"]},
			DEFAULT	        =   { color = C.Colors.LuminousOrange,	sort = 899,	text = L["response_unavailable"] },
			-- dynamically constructed in BuildConfigOptions()
			-- example data left behind for illustration
			--[[
			{ color = {0,1,0,1},        sort = 1,   text = L["ms_need"], },         [1]
			{ color = {1,0.5,0,1},	    sort = 2,	text = L["os_greed"], },        [2]
			{ color = {0,0.7,0.7,1},    sort = 3,	text = L["minor_upgrade"], },   [3]
			{ color = {1,0.5,0,1},	    sort = 4,	text = L["pvp"], },             [4]
			--]]
		}
	}
}

ML.AwardStringsDesc = {
	L["announce_&s_desc"],
	L["announce_&p_desc"],
	L["announce_&i_desc"],
	L["announce_&r_desc"],
	L["announce_&n_desc"],
	L["announce_&l_desc"],
	L["announce_&t_desc"],
	L["announce_&o_desc"],
	L["announce_&m_desc"],
	L["announce_&g_desc"],
}

ML.AnnounceItemStringsDesc = {
	L["announce_&s_desc"],
	L["announce_&i_desc"],
	L["announce_&l_desc"],
	L["announce_&t_desc"],
	L["announce_&o_desc"],
	L["announce_&g_desc"],
}

function ML:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), ML.Defaults)
	self.Send = Comm():GetSender(C.CommPrefixes.Main)
end

function ML:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	-- is the ML's loot window open or closed
	self.lootOpen = false
	-- table of slot to loot information
	-- this is NOT the same as the loot table, as not all available loot
	-- is handled by addon based upon settings and item type
	--- @type table<number, Models.Item.LootSlotInfo>
	self.lootSlots = {}
	-- the ML's current loot table
	--- @type table<number, Models.Item.LootTableEntry>
	self.lootTable = {}
	-- for keeping a backup of loot table on session end
	--- @type table<number, Models.Item.LootTableEntry>
	self.lootTableOld = {}
	-- item(s) the ML has attempted to give out and waiting
	--- @type table<number, Models.Item.LootQueueEntry>
	self.lootQueue = {}
	-- is a session in flight
	self.running = false
	self:SubscribeToEvents()
	self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
	self:SubscribeToComms()
end

function ML:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:UnsubscribeFromEvents()
	self:UnregisterAllBuckets()
	self:UnregisterAllMessages()
	self:UnhookAll()
	self:UnsubscribeFromComms()
end

function ML:EnableOnStartup()
	return false
end

function ML:SubscribeToEvents()
	Logging:Debug("SubscribeToEvents(%s)", self:GetName())
	self.eventSubscriptions = Event():BulkSubscribe({
        [C.Events.ChatMessageWhisper] = function(_, ...) self:OnChatMessageWhisper(...) end,
    })
end

function ML:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.MasterLooterDbRequest] = function(_, sender)
			Logging:Debug("MasterLooterDbRequest from %s", tostring(sender))
			MasterLooterDb:Send(C.group)
		end,
		[C.Commands.Reconnect] = function(_, sender)
			Logging:Debug("Reconnect from %s", tostring(sender))

		end,
		[C.Commands.LootTable] = function(_, sender)
			Logging:Debug("LootTable from %s", tostring(sender))
		end,
		-- todo : standby ping acks
	})
end

local function Unsubscribe(from)
	for _, subscription in pairs(from) do
		subscription:unsubscribe()
	end
end

function ML:UnsubscribeFromEvents()
	Logging:Debug("UnsubscribeFromEvents(%s)", self:GetName())
	if self.eventSubscriptions then
		Unsubscribe(self.eventSubscriptions)
		self.eventSubscriptions = nil
	end
end

function ML:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	if self.commSubscriptions then
		Unsubscribe(self.commSubscriptions)
		self.commSubscriptions = nil
	end
end

-- when the db is changed, need to check if we must broadcast the new MasterLooter Db
-- the msg will be in the format of 'ace serialized message' = 'count of event'
-- where the deserialized message will be a tuple of 'module of origin' (e.g MasterLooter), 'db key name' (e.g. outOfRaid)
function ML:ConfigTableChanged(msg)
	Logging:Debug("ConfigTableChanged(%s)", self:GetName())
end

function ML:OnChatMessageWhisper(...)
	Logging:Debug("OnChatMessageWhisper(%s)", self:GetName())
end

function ML:UpdateDb()
	Logging:Debug("UpdateDb")
	AddOn:OnMasterLooterDbReceived(MasterLooterDb:Get(true))
	MasterLooterDb:Send(C.group)
end


--- @return boolean indicating if ML operations are being handled
function ML:IsHandled()
	-- this module is enabled (and)
	-- we are the master looter (and)
	-- the addon is enabled (and)
	-- the addon is handling loot
	--Logging:Trace("IsHandled() : %s, %s, %s, %s",
	--              tostring(self:IsEnabled()), tostring(AddOn:IsMasterLooter()),
	--              tostring(AddOn.enabled), tostring(AddOn.handleLoot)
	--)
	return self:IsEnabled() and AddOn:IsMasterLooter() and AddOn.enabled and AddOn.handleLoot
end

--- @param ml Models.Player
function ML:NewMasterLooter(ml)
	Logging:Debug("NewMasterLooter(%s)", tostring(ml))
	if AddOn.UnitIsUnit(ml, C.player) then
		self:Send(C.group, C.Commands.PlayerInfoRequest)
		self:UpdateDb()
	else
		self:Disable()
	end
end

function ML:StartSession()
	Logging:Debug("StartSession(%s)", tostring(self.running))

	if self.running then
		self:Send(C.group, C.Commands.LootTableAdd, self:_GetLootTableForTransmit())
	else
		self:Send(C.group, C.Commands.LootTable, self:_GetLootTableForTransmit())
	end

	Util.Tables.Call(self.lootTable, function(e) e.sent = true end)
	self.running = true
	self:AnnounceItems(self.lootTable)
end

function ML:EndSession()
	Logging:Debug("EndSession()")

	self.oldLootTable = self.lootTable
	self.lootTable = {}
	self:Send(C.group, C.Commands.LootSessionEnd)
	self.running = false
	-- todo
	-- self:CancelAllTimers()
	if AddOn:TestModeEnabled() then
		AddOn:ScheduleTimer("NewMasterLooterCheck", 1)
		AddOn.mode:Disable(C.Modes.Test)
	end
end

function ML:AnnounceItems(items)
	if not self:GetDbValue('announceItems') then return end
	local channel, msg = self:GetDbValue('announceItemText.channel'), self:GetDbValue('announceItemText.text')
	AddOn:SendAnnouncement(self:GetDbValue('announceItemPrefix'), channel)
	-- todo
	-- iterate the items and print for each
end

function ML:OnLootReady(...)
	if self:IsHandled() then
		wipe(self.lootSlots)
		if not IsInInstance() then return end
		if GetNumLootItems() <= 0 then return end
		self.lootOpen = true
		self:_ProcessLootSlots(
			function(...)
				return self:ScheduleTimer("OnLootReady", 0, C.Events.LootReady, ...)
			end,
			...
		)
	end
end

function ML:OnLootOpened(...)
	if self:IsHandled() then
		self.lootOpen = true

		local rescheduled =
			self:_ProcessLootSlots(
					function(...)
						-- failure processing loot slots, go no further
						local _, autoLoot, attempt = ...
						if not attempt then attempt = 1 else attempt = attempt + 1 end
						return self:ScheduleTimer("OnLootOpened", attempt / 10, C.Events.LootOpened, autoLoot, attempt)
					end,
					...
			)

		-- we made it through the loot slots (not rescheduled) so we can continue
		-- to processing the loot table
		if Util.Objects.IsNil(rescheduled) then
			wipe(self.lootQueue)
			if not InCombatLockdown() then
				self:_BuildLootTable()
			else
				AddOn:Print(L['cannot_start_loot_session_in_combat'])
			end
		end
	end
end

function ML:OnLootClosed(...)
	if self:IsHandled() then
		self.lootOpen = false
	end
end

function ML:OnLootSlotCleared(...)
	if self:IsHandled() then
		local slot = ...
		local loot = self:_GetLootSlot(slot)
		Logging:Debug("OnLootSlotCleared(%d)", slot)
		if loot and not loot.looted then
			loot.looted = true

			if not self.lootQueue or Util.Tables.Count(self.lootQueue) == 0 then
				Logging:Warn("OnLootSlotCleared() : loot queue is nil or empty")
				return
			end

			for i = #self.lootQueue, 1, -1 do
				local entry = self.lootQueue[i]
				if entry and entry.slot then
					if entry.timer then self:CancelTimer(entry.timer) end
					tremove(self.lootQueue, i)
					entry:Cleared(true, nil)
					-- only one entry in queue which corresponds to slot
					break
				end
			end
		end
	end
end

--- @return Models.Item.LootSlotInfo
function ML:_GetLootSlot(slot)
	return self.lootSlots and self.lootSlots[slot] or nil
end

--- @param onFailure function a function to be invoked should a loot slot be unhandled
--- @return table reference to any schedule that resulted from invoking onFailure
function ML:_ProcessLootSlots(onFailure, ...)
	local numItems = GetNumLootItems()
	Logging:Debug("_ProcessLootSlots(%d)", numItems)
	if numItems > 0 then
		-- iterate through the available items, tracking each individual loot slot
		for slot = 1, numItems do
			-- see if we have already added it, because of callbacks
			local loot = self:_GetLootSlot(slot)
			if (not loot and LootSlotHasItem(slot)) or (loot and not AddOn.ItemIsItem(loot:GetItemLink(), GetLootSlotLink(slot))) then
				Logging:Debug(
						"_ProcessLootSlots(%d): attempting to (re) add loot info at slot, existing=%s",
						slot, tostring(not Util.Objects.IsNil(loot))
				)
				if not self:_AddLootSlot(slot, ...) then
					Logging:Warn(
							"_ProcessLootSlots(%d) : uncached item in loot table, invoking 'onFailure' (function) ...",
							slot
					)
					return onFailure(...)
				end
			end
		end
	end
end

--- @return boolean indicating if loot slot was handled (not necessarily added to loot slots, i.e. currency or blacklisted)
function ML:_AddLootSlot(slot, ...)
	Logging:Debug("_AddLootSlot(%d)", slot)
	-- https://wow.gamepedia.com/API_GetLootSlotInfo
	local texture, name, quantity, currencyId, quality = GetLootSlotInfo(slot)
	-- https://wow.gamepedia.com/API_GetLootSourceInfo
	-- the creature being looted
	local guid = AddOn:ExtractCreatureId(GetLootSourceInfo(slot))
	if texture then
		-- return's the link for item at specified slot
		-- https://wow.gamepedia.com/API_GetLootSlotLink
		local link = GetLootSlotLink(slot)
		if currencyId then
			Logging:Debug("_AddLootSlot(%d) : ignoring %s as it's currency", slot, tostring(link))
		elseif not AddOn:IsItemBlacklisted(link) then
			Logging:Debug("_AddLootSlot(%d) : adding %s from creature %s to loot table", slot, tostring(link), tostring(guid))
			self.lootSlots[slot] = LootSlotInfo(
					slot,
					name,
					link,
					quantity,
					quality,
					guid,
					GetUnitName("target") -- we're looting a creature, so the target will be that creature
			)
		end

		return true
	end

	return false
end

function ML:_UpdateLootSlots()
	Logging:Debug("_UpdateLootSlots()")

	if not self.lootOpen then
		Logging:Warn("UpdateLootSlots() : attempting to update loot slots without an open loot window")
		return
	end

	local updatedLootSlots = {}
	for slot = 1, GetNumLootItems() do
		local item = GetLootSlotLink(slot)
		for session = 1, #self.lootTable do
			local itemEntry = self:_GetLootTableEntry(session)
			if not itemEntry.awarded and not updatedLootSlots[session] then
				if AddOn.ItemIsItem(item, itemEntry.item) then
					if slot ~= itemEntry.slot then
						Logging:Debug("_UpdateLootSlots(%d) : previously at %d, not at %d", session, itemEntry.slot, slot)
					end
					itemEntry.slot = slot
					updatedLootSlots[session] = true
					break
				end
			end
		end
	end

end

--- @return Models.Item.LootTableEntry
function ML:_GetLootTableEntry(session)
	return self.lootTable and self.lootTable[session] or nil
end

function ML:RemoveLootTableEntry(session)
	Logging:Debug("RemoveLootTableEntry(%d)", session)
	Util.Tables.Remove(self.lootTable, session)
end

function ML:_BuildLootTable()
	local numItems = GetNumLootItems()
	Logging:Debug("_BuildLootTable(%d, %s)", numItems, tostring(self.running))

	if numItems > 0 then
		local LS = AddOn:LootSessionModule()
		if self.running or LS:IsRunning() then
			self:_UpdateLootSlots()
		else
			for slot = 1, numItems do
				local item = self:_GetLootSlot(slot)
				if item then
					self:ScheduleTimer("HookLootButton", 0.5, slot)
					local link, quantity, quality = item:GetItemLink(), item.quantity, item.quality
					local autoAward, mode, winner = self:ShouldAutoAward(link, quality)
					if autoAward and quantity > 0 then
						self:AutoAward(slot, link, quality, winner, mode)
					elseif link and quantity > 0 and self:ShouldAddItem(link, quality) then
						-- item that should be added
						self:_AddLootTableEntry(slot, link)
					elseif quantity == 0 then
						-- currency
						LootSlot(slot)
					end
				end
			end

			Logging:Debug("_BuildLootTable(%d, %s)", #self.lootTable, tostring(self.running))

			if #self.lootTable > 0 and not self.running then
				if self.db.profile.autoStart then
					self:StartSession()
				else
					AddOn:CallModule(LS:GetName())
					LS:Show(self.lootTable)
				end
			end
		end
	end
end

--- @param slot number  index of the item within the loot table
--- @param item any  ItemID|ItemString|ItemLink
function ML:_AddLootTableEntry(slot, item)
	Logging:Trace("_AddLootTableEntry(%d, %s)", tostring(slot), tostring(item))

	local entry = LootTableEntry(slot, item)
	Util.Tables.Push(self.lootTable, entry)
	Logging:Debug(
			"_AddLootTableEntry() : %s (slot %d) added to loot table at index %d",
			tostring(item), tostring(slot), tostring(#self.lootTable)
	)

	-- make a call to get item information, it may not be available immediately
	-- but this will submit a query
	local itemRef = entry:GetItem()
	if not itemRef or not itemRef:IsValid() then
		-- no need to schedule another invocation of this
		-- the call to GetItem() submitted a query, it should be available by time it's needed
		Logging:Trace("_AddLootTableEntry() : item info unavailable for %s, but query has been initiated", tostring(item))
	else
		AddOn:SendMessage(C.Messages.MasterLooterAddItem, item, entry)
	end
end

function ML:_GetLootTableForTransmit(overrideSent)
	overrideSent = Util.Objects.Default(overrideSent, false)
	Logging:Trace("_GetLootTableForTransmit(%s)", tostring(overrideSent))
	local lt =
		Util(self.lootTable)
			:Copy()
			:Map(
				function(e)
					if not overrideSent and e.sent then
						return nil
					else
						return e:ForTransmit()
					end
				end
			)()
	Logging:Trace("_GetLootTableForTransmit() : %s", Util.Objects.ToString(lt))
	return lt
end

function ML:HookLootButton(slot)
	local lootButton = getglobal("LootButton".. slot)
	-- ElvUI
	if getglobal("ElvLootSlot".. slot) then lootButton = getglobal("ElvLootSlot".. slot) end
	local hooked = self:IsHooked(lootButton, "OnClick")
	if lootButton and not hooked then
		Logging:Debug("HookLootButton(%d)", slot)
		self:HookScript(lootButton, "OnClick", "LootOnClick")
	end
end

function ML:LootOnClick(button)
	if not IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then return end
	Logging:Debug("LootOnClick(%s)", Util.Objects.ToString(button))

	if getglobal("ElvLootFrame") then button.slot = button:GetID() end

	-- check that we're not already looting that item
	for _, v in ipairs(self.lootTable) do
		if button.slot == v.slot then
			AddOn:Print(L["loot_already_on_list"])
			return
		end
	end

	local LS = AddOn:LootSessionModule()
	self:_AddLootTableEntry(button.slot, GetLootSlotLink(button.slot))
	AddOn:CallModule(LS:GetName())
	LS:Show(self.lootTable)
end

---@param item any
---@param quality number
---@return boolean
function ML:ShouldAddItem(item, quality)
	local addItem = false

	-- item is available (AND)
	-- auto-adding of items is enabled (AND)
	-- item is equipable or auto-adding non-equipable items is enabled (AND)
	-- quality is set and >= our threshold (AND)
	-- item is not BOE or auto-adding of BOE is enabled
	if item and quality then
		if self.db.profile.autoAdd and
			(IsEquippableItem(item) or self.db.profile.autoAddNonEquipable) and
			quality >= GetLootThreshold() then
			addItem = self.db.profile.autoAddBoe or not AddOn.IsItemBoe(item)
		end
	end

	Logging:Debug("ShouldAddItem(%s, %s) : %s", tostring(item), tostring(quality), tostring(addItem))
	return addItem
end

---@param item any
---@param quality number
---@return boolean
---@return string
---@return string
function ML:ShouldAutoAward(item, quality)
	if not item then return false end
	Logging:Debug("ShouldAutoAward() : item=%s, quality=%d", tostring(item), quality)
	return false, nil, nil
end

--- @return boolean
function ML:AutoAward(slot, item, quality, winner, mode)
	winner = AddOn:UnitName(winner)
	Logging:Debug(
			"AutoAward() : slot=%d, item=%s, quality=%d, winner=%s, mode=%s",
			tonumber(slot), tostring(item), tonumber(quality), winner, tostring(mode)
	)
end

function ML:Test(items)
	Logging:Debug("Test(%d)", #items)

	for session, item in ipairs(items) do
		self:_AddLootTableEntry(session, item)
	end

	if self.db.profile.autoStart then
		AddOn:Print("Auto start isn't supported when testing")
	end

	AddOn:CallModule("LootSession")
	AddOn:GetModule("LootSession"):Show(self.lootTable)
end

local awardReasonsFunc

-- cannot wait until BuildConfigOptions() is called, as these could be used before
-- they are built
do
	-- now add additional dynamic options needed
	local DefaultButtons = ML.Defaults.profile.buttons
	local DefaultResponses = ML.Defaults.profile.responses
	-- AddOn won't be fully initialized yet, so need to go vie GetModule()
	local GP = AddOn:GetModule("GearPoints")

	-- these are the responses available to player when presented with a loot decision
	-- we only select ones that are "user visible", as others are only available to
	-- master looter (e.g. 'Free', 'Disenchant', 'Bank', etc.)
	local UserVisibleResponses =
		Util(GP.Defaults.profile.award_scaling)
				:CopyFilter(function (v) return v.user_visible end, true, nil, true)()
	local UserNonVisibleResponses =
		Util(GP.Defaults.profile.award_scaling)
				:CopyFilter(function (v) return not v.user_visible end, true, nil, true)()

	-- establish the number of user visible buttons
	DefaultButtons.numButtons = Util.Tables.Count(UserVisibleResponses)
	local index = 1
	for response, value in pairs(UserVisibleResponses) do
		-- these are entries that represent buttons available to player at time of loot decision
		Util.Tables.Push(DefaultButtons, {color = value.color, text = L[response], whisperKey = L['whisperkey_' .. response], award_scale = response})
		-- the are entries of the universe of possible responses, which are a super set of ones presented to the player
		Util.Tables.Push(DefaultResponses, { sort = index, color = value.color, text = L[response], award_scale = response})
		index = index + 1
	end

	index = 1
	local AwardReasons = { }
	for response, value in pairs(UserNonVisibleResponses) do
		AwardReasons[index] = UIUtil.ColoredDecorator(value.color):decorate(L[response])
		index = index + 1
	end

	awardReasonsFunc = function() return AwardReasons end
end

-- Configuration related stuff below
--
-- what a mess of settings...
--
local Options = Util.Memoize.Memoize(function(self)
	local builder = AceUI.ConfigBuilder()

	builder:group(ML:GetName(), L["ml"]):desc(L["ml_desc"])
		:args()
			:group('general', _G.GENERAL):order(3)
				:args()
					:group('usageOptions', L['usage_options']):order(1):set('inline', true)
						:args()
							:select('usage', L['usage']):order(1):desc(L['usage_desc']):set('width', 'double')
								:set('values', {ml= L["usage_ml"], ask_ml = L["usage_ask_ml"], never  = L["usage_never"]})
								:set('get', function() return AddOn.GetDbValue(self, {'usage.state'}) end)
								:set('set',
                                     function(_, key)
	                                     for k in pairs(self.db.profile.usage) do
		                                     if k == key then
			                                     self.db.profile.usage[k] = true
		                                     else
			                                     self.db.profile.usage[k] = false
		                                     end
	                                     end
	                                     AddOn.SetDbValue(self, {'usage.state'}, key)
                                     end
								)
							:header('spacer', ''):order(2)
							:toggle('leaderUsage'):desc(L["usage_leader_desc"]):order(3)
								:named(function()  return self.db.profile.usage.ml and L["usage_leader_always"] or L["usage_leader_ask"] end)
								:set('get', function() return self.db.profile.usage.leader or self.db.profile.usage.ask_leader end)
								:set('set',
						             function(_, val)
							             self.db.profile.usage.leader, self.db.profile.usage.ask_leader = false, false
							             if self.db.profile.usage.ml then
								             AddOn.SetDbValue(self, {'usage.leader'}, val)
							             end
							             if self.db.profile.usage.ask_ml then
								             AddOn.SetDbValue(self, {'usage.ask_leader'}, val)
							             end
						             end
								)
								:set('disabled', function() return self.db.profile.usage.never end)
							:toggle('onlyUseInRaids', L['only_use_in_raids']):order(4):desc(L['only_use_in_raids_desc'])
							:toggle('outOfRaid', L['out_of_raid']):order(5):desc(L['out_of_raid_desc'])
						:close()
					:group('lootOptions', L['loot_options']):order(2):set('inline', true)
						:args()
							:toggle('autoStart', L['auto_start']):order(1):desc(L['auto_start_desc'])
							:header('spacer', ''):order(2)
							:toggle('autoAdd', L['auto_add_items']):order(3):desc(L['auto_add_items_desc'])
							:toggle('autoAddNonEquipable', format(L['auto_add_x_items'], L['equipable_not'])):order(4):desc(L['auto_add_non_equipable_desc'])
								:set('disabled', function () return not self.db.profile.autoAdd end)
							:toggle('autoAddBoe', format(L['auto_add_x_items'], 'BOE')):order(5):desc(L['auto_add_boe_desc'])
								:set('disabled', function () return not self.db.profile.autoAdd end)
						:close()
				:close()
			:group('announcements', L["announcements"]):order(1)
				:args()
					:group('awards',  L["awards"]):order(1):set('inline', true)
						:args()
							:toggle('announceAwards', L["announce_awards"]):order(1):desc(L["announce_awards_desc"]):set('width', 'double')
							:description('description',
	                                     function ()
		                                     return L["announce_awards_desc_detail"] .. '\n' ..
		                                        Util.Strings.Join('\n', unpack(ML.AwardStringsDesc))
	                                     end
							):order(2):fontSize('medium'):set('hidden', function() return not self.db.profile.announceAwards end)
							-- additional options are added after, as they are dynamic
						:close()
					:group('considerations', L["considerations"]):order(2):set('inline', true)
						:args()
							:toggle('announceItems', L["announce_items"]):order(1):desc(L["announce_items_desc"]):set('width', 'full')
							:description('description', L["announce_items_desc_detail"]):order(2):fontSize('medium')
								:set('hidden', function() return not self.db.profile.announceItems end)
							:select('announceItemChannel', L['channel']):order(3):desc(L['channel_desc']):set('style', 'dropdown')
								:set('values', Util.Tables.Copy(C.ChannelDescriptions))
								:set('get', function() return AddOn.GetDbValue(self, {'announceItemText.channel'}) end)
								:set('set', function(_,v ) AddOn.SetDbValue(self, {'announceItemText.channel'}, v) end)
								:set('hidden', function() return not self.db.profile.announceItems end)
							:input('announceItemPrefix', L["message_header"]):order(4):desc(L["message_header_desc"]):set('width', 'double')
								:set('hidden', function() return not self.db.profile.announceItems end)
							:description('announceItemMessageDesc',
	                                     function ()
		                                     return L["announce_items_desc_detail2"] .. '\n' ..
				                                     Util.Strings.Join('\n', unpack(ML.AnnounceItemStringsDesc))
	                                     end
							):order(5):fontSize('medium'):set('hidden', function() return not self.db.profile.announceItems end)
							:input('announceItemMessage', L["message_for_each_item"]):order(6):set('width', 'double')
								:set('get', function() return AddOn.GetDbValue(self, {'announceItemText.text'}) end)
								:set('set', function(_,v ) AddOn.SetDbValue(self, {'announceItemText.text'}, v) end)
								:set('hidden', function() return not self.db.profile.announceItems end)
						:close()
					:group('responses', L["responses"]):order(3):set('inline', true)
						:args()
							:toggle('announceResponses', L["announce_responses"]):order(1):desc(L["announce_responses_desc"]):set('width', 'full')
							:description('description', L["announce_responses_desc_details"]):order(2):fontSize('medium')
								:set('hidden', function() return not self.db.profile.announceResponses end)
							:select('announceResponsesChannel', L['channel']):order(3):desc(L['channel_desc']):set('style', 'dropdown')
								:set('values', Util.Tables.Copy(C.ChannelDescriptions))
								:set('get', function() return AddOn.GetDbValue(self, {'announceResponseText.channel'}) end)
								:set('set', function(_,v ) AddOn.SetDbValue(self, {'announceResponseText.channel'}, v) end)
								:set('hidden', function() return not self.db.profile.announceResponses end)
						:close()
				:close()
			:group('awards', L["awards"]):order(2)
				:args()
					:group('autoAward', L["auto_award"]):order(1):set('inline', true)
						:set('disabled', function() return not self.db.profile.autoAward end)
						:args()
							:toggle('autoAward', L["auto_award"]):order(1):desc(L["auto_award_desc"]):set('disabled', false)
							:select('autoAwardType', L['auto_award_type']):order(2):desc(L['auto_award_type_desc'])
								:set('style', 'dropdown'):set('width', 'double')
								:set('values',
	                                 function()
		                                 return {
			                                 [AutoAwardType.Equipable]    = L['equipable'],
			                                 [AutoAwardType.NotEquipable] = L['equipable_not'],
			                                 [AutoAwardType.All]          = L['all']
		                                 }
	                                 end
								)
							:select('autoAwardLowerThreshold', L['lower_quality_limit']):order(3.1)
								:desc(L['lower_quality_limit_desc']):set('style', 'dropdown')
								:set('values', Util.Tables.Copy(C.ItemQualityColoredDescriptions))
							:select('autoAwardUpperThreshold', L['upper_quality_limit']):order(3.2)
								:desc(L['upper_quality_limit_desc']):set('style', 'dropdown')
								:set('values', Util.Tables.Copy(C.ItemQualityColoredDescriptions))
							:input('autoAwardToNotInGroup', L["auto_award_to"]):order(4):desc(L['auto_award_to_desc'])
								:set('width', 'double')
								:set('get', function() return AddOn.GetDbValue(self, {'autoAwardTo'}) end)
								:set('set', function(_,v ) AddOn.SetDbValue(self, {'autoAwardTo'}, v) end)
								:set('hidden', function() return GetNumGroupMembers() > 0 end)
							:select('autoAwardTo', L["auto_award_to"]):order(4):desc(L['auto_award_to_desc'])
								:set('width', 'double'):set('style', 'dropdown')
								:set('hidden', function() return GetNumGroupMembers() == 0 end)
								:set('values',
	                                 function()
		                                 local t = {}
		                                 for i = 1, GetNumGroupMembers() do
			                                 local name = GetRaidRosterInfo(i)
			                                 t[name] = name
		                                 end
		                                 return t
	                                 end
								)
							:select('autoAwardReason', L["reason"]):order(4.1):desc(L['reason_desc'])
								:set('values', awardReasonsFunc)
						:close()
					:group('autoAwardRepItems', L["auto_award_rep_items"]):order(2):set('inline', true)
						:set('disabled', function() return not self.db.profile.autoAwardRepItems end)
						:args()
							:toggle('autoAwardRepItems', L["auto_award_rep_items"]):order(1):desc(L["auto_award_rep_items_desc"])
								:set('disabled', false):set('width', 'full')
							:select('autoAwardRepItemsMode', L['auto_award_rep_items_mode']):order(2):desc(L['auto_award_rep_items_mode_desc'])
								:set('style', 'dropdown'):set('width', 'double')
								:set('values',
						             function()
							             return {
								             [AutoAwardRepItemsMode.Person]     = L['person'],
								             [AutoAwardRepItemsMode.RoundRobin] = L['round_robin'],
							             }
						             end
								)
							:input('autoAwardRepItemsToNotInGroup', L["auto_award_to"]):order(3):desc(L['auto_award_to_desc'])
								:set('width', 'double')
								:set('get', function() return AddOn.GetDbValue(self, {'autoAwardRepItemsTo'}) end)
								:set('set', function(_,v ) AddOn.SetDbValue(self, {'autoAwardRepItemsTo'}, v) end)
								:set('hidden',
	                                 function()
		                                 return GetNumGroupMembers() > 0 or
				                                 self.db.profile.autoAwardRepItemsMode == AutoAwardRepItemsMode.RoundRobin
	                                 end
								)
							:select('autoAwardRepItemsTo', L["auto_award_to"]):order(3):desc(L['auto_award_to_desc'])
								:set('width', 'double'):set('style', 'dropdown')
								:set('hidden',
						             function()
							             return GetNumGroupMembers() == 0 or
									             self.db.profile.autoAwardRepItemsMode == AutoAwardRepItemsMode.RoundRobin
						             end
								)
								:set('values',
						             function()
							             local t = {}
							             for i = 1, GetNumGroupMembers() do
								             local name = GetRaidRosterInfo(i)
								             t[name] = name
							             end
							             return t
						             end
								)
							:select('autoAwardRepItemsReason', L["reason"]):order(4):desc(L['reason_desc'])
								:set('values', awardReasonsFunc)
						:close()
				:close()
			:group('responses', L["responses"]):order(4)
				:args()
					:group('timeout', L["timeout"]):order(1):set('inline', true)
						:args()
							:toggle('enable', L["timeout_enable"]):order(1):desc(L["timeout_enable_desc"])
								:set('get', function() return AddOn.GetDbValue(self, {'timeout'}) end)
								:set('set',
						             function()
							             if self.db.profile.timeout then
								             AddOn.SetDbValue(self, {'timeout'}, false)
										 else
								             AddOn.SetDbValue(self, {'timeout'}, ML.Defaults.profile.timeout)
										 end
						             end
								)
							:range("timeout", L["timeout_duration"], 0, 240, 5):order(2):desc(L["timeout_duration_desc"])
								:set('disabled', function() return not self.db.profile.timeout end)
						:close()
					:group('showLootResponses', L["responses_during_loot"]):order(2):set('inline', true)
						:args()
							:toggle('showLootResponses', L["enable_display"]):order(1):desc(L["responses_during_loot_desc"])
						:close()
					:group('whisperResponses', L["responses_from_chat"]):order(3):set('inline', true)
						:args()
							:toggle('acceptWhispers', L["accept_whispers"]):order(1):desc(L["accept_whispers_desc"])
							:description('description', L["responses_from_chat_desc"]):order(2):fontSize('medium')
							-- additional options added below
						:close()
				:close()

	builder:SetPath(ML:GetName() .. '.args.responses.args.whisperResponses.args')
	local db = self.db.profile
	for i = 1, db.buttons.numButtons do
		local button = db.buttons[i]
		Logging:Debug("Button = %s", Util.Objects.ToString(button))
		-- :input('autoAwardRepItemsToNotInGroup', L["auto_award_to"]):order(3):desc(L['auto_award_to_desc'])
		builder
			:input("whisperkey_" .. i,  UIUtil.ColoredDecorator(button.color):decorate(L[button.text])):order(i + 2)
				:desc(format(L["whisperkey_for_x"], button.text)):set('width', 'double')
				:set('get', function() return db.buttons[i].whisperKey end)
				:set('set', function(_, v) db.buttons[i].whisperKey = tostring(v) end)
				:set('hidden', function() return not db.acceptWhispers or db.buttons.numButtons < i end)
	end

	builder:SetPath(ML:GetName() .. '.args.announcements.args.awards.args')
	for i = 1, #db.announceAwardText do
		builder
			:select('awardChannel' .. i, L["channel"]):order(i + 2):desc(L['channel_desc'])
				:set('style', 'dropdown'):set('values', Util.Tables.Copy(C.ChannelDescriptions))
				:set('get', function() return db.announceAwardText[i].channel end)
				:set('set', function(_, v) db.announceAwardText[i].channel = v end)
				:set('hidden', function() return not db.announceAwards end)
			:input('awardMessage' .. i, L["message"]):order(i + 2.1):desc(L['message_desc'])
				:set('width', 'double')
				:set('get', function() return db.announceAwardText[i].text end)
				:set('set', function(_, v) db.announceAwardText[i].text = v end)
				:set('hidden', function() return not db.announceAwards end)
	end

	return builder:build()
end)

function ML:ConfigTableChanged(msg)
	Logging:Debug("ConfigTableChanged() : %s", Util.Objects.ToString(msg))
end

function ML:BuildConfigOptions()
	local options = Options(self)
	return options[self:GetName()], false
end