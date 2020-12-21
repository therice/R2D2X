--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type Models.StandbyMember
local StandbyMember = AddOn.Package('Models').StandbyMember

--- @class Standby
local Standby = AddOn:NewModule("Standby", "AceEvent-3.0", "AceTimer-3.0")

Standby.defaults = {
	profile = {
		enabled                 = false,
		standby_pct             = 0.75,
		verify_after_each_award = false,
		roster                  = {},
	}
}

function Standby:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), Standby.defaults)
	--- @type table<string, Models.StandbyMember>
	self.roster = {}
	self:RegisterMessage(C.Messages.PlayerNotFound, function(...) self:PlayerNotFound(...) end)
	self:ScheduleTimer(function() self:RosterSetup() end, 3)
end

function Standby:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:GetFrame()
	self:BuildData()
	self:Show()
end

function Standby:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:Hide()
end

function Standby:EnableOnStartup()
	return false
end

-- Standby must be enabled AND
-- Must be Master Looter AND
-- Must be in Group OR Development Mode Enabled
function Standby:IsOperationRequired()
	return self.db.profile.enabled and AddOn:IsMasterLooter() and (IsInGroup() or AddOn:DevModeEnabled())
end

--- @param player Models.StandbyMember
function Standby:AddPlayer(player)
	-- only the master looter directly modifies the roster
	-- everyone else gets information via broadcasts
	if self:IsOperationRequired() and player then
		self.roster[player.name] = player
		self:ScheduleTimer(function() self:RosterPersist() end, 3)
		self:Update()
	end
end

function Standby:AddPlayerFromMessage(msg, sender)
	if self:IsOperationRequired() then
		local contacts = Util.Tables.New(AddOn:GetArgs(msg, 3))
		local class = AddOn:UnitClass(sender)

		if Util.Tables.Count(contacts) == 1 then
			contacts = {}
		else
			contacts = Util.Tables.Sub(contacts, 1, Util.Tables.Count(contacts) - 1)
		end

		Logging:Trace("AddPlayerFromMessage(%s) : %s", sender, Util.Objects.ToString(contacts))

		self:AddPlayer(StandbyMember(sender, class, contacts))
		SendChatMessage(
				format(L["whisper_standby_ack"], Util.Tables.Count(contacts) > 0 and Util.Tables.Concat(contacts, ",") or "N/A"),
				C.Channels.Whisper, nil, sender
		)
	else
		SendChatMessage(
				format(L["whisper_standby_ignored"], AddOn.masterLooter:GetName()),
				C.Channels.Whisper, nil, sender
		)
	end
end

--- @param player Models.StandbyMember
function Standby:RemovePlayer(player)
	Logging:Debug("RemovePlater(%s)", tostring(player))
	if self:IsOperationRequired() and player then
		self.roster[player.name] = nil
		self:ScheduleTimer(function() self:RosterPersist() end, 3)
		self:Update()
	end
end

function Standby:ResetRoster()
	if self.db.profile.enabled then
		self.roster = {}
		self:Update()
		self:RosterPersist()
	end
end

function Standby:PruneRoster()
	Logging:Trace("PruneRoster()")

	if self:IsOperationRequired() and self.db.profile.verify_after_each_award then
		for _, player in pairs(self.roster) do
			if not player:IsOnline() then
				self:RemovePlayer(player)
			end
		end
	end
end

function Standby:PingPlayers()
	for name, _ in pairs(self.roster) do
		self:PingPlayer(name)
	end
end

function Standby:PingPlayer(playerName)
	Logging:Trace("PingPlayer(%s)", tostring(playerName))

	local player = self.roster[playerName]
	if not player then
		Logging:Warn("PingPlayer(%s) : player not on standby/bench")
		return
	end

	local contacts = Util.Tables.New(AddOn.Ambiguate(player.name))
	for name, _ in pairs(player.contacts) do
		Util.Tables.Push(contacts, AddOn.Ambiguate(name))
	end
	-- if the contact isn't online, it will result in a system message - which we trap and forward on to PlayerNotFound
	-- via ChatFrame_AddMessageEventFilter() in Addon.lua
	Util.Tables.Call(
			contacts,
			function(contact)
				Logging:Trace("PingPlayer(%s) - sending ping", contact)
				AddOn:Send(contact, C.Commands.StandbyPing, playerName)
			end
	)
end

function Standby:PlayerNotFound(_, playerName)
	Logging:Trace("PlayerNotFound(%s)", tostring(playerName))
	self:PingAck(nil, playerName)
end

--- @param from string who sent ping ack, will be null if not called as result of a message
--- @param playerName string the name of the player or contact for which ack was sent
function Standby:PingAck(from, playerName)
	Logging:Trace("PingAck(%s) : %s", tostring(from), tostring(playerName))
	if self:IsOperationRequired() then
		-- player name is always required
		if playerName then
			local standbyMember
			-- if from is specified, then the playerName should be the actual roster member's name
			-- not a contact, as it's specified in StandbyPing as an argument
			if from then
				standbyMember = self.roster[playerName]
			-- otherwise, we need to search for it
			else
				_, standbyMember = Util.Tables.FindFn(
						self.roster,
						function(player) return player:IsPlayerOrContact(playerName) end
				)
			end

			if standbyMember then
				-- Logging:Debug("%s", Util.Objects.ToString(standbyMember))
				standbyMember:UpdateStatus(from and from or playerName, not Util.Strings.IsEmpty(from))
				Logging:Trace("%s / %s : %s", tostring(from), tostring(playerName), Util.Objects.ToString(standbyMember:toTable()))
				self:Update()
			end
		end
	end
end

function Standby:RosterSetup()
	Logging:Debug("RosterSetup(%s)", tostring(self:IsOperationRequired()))
	if self:IsOperationRequired() then
		local roster = self.db.profile.roster
		if roster and Util.Tables.Count(roster) > 0 then
			Logging:Trace("SetupRosterFromDb() : %d entries in persisted roster",
			              Util.Tables.Count(roster)
			)

			self.roster = Util.Tables.Map(
					Util.Tables.Copy(self.db.profile.roster),
					function(e) return StandbyMember:reconstitute(e) end
			)

			Logging:Trace("SetupRosterFromDb() : %s", Util.Objects.ToString(self.roster))
		end
	end
end

function Standby:RosterPersist()
	Logging:Debug("RosterPersist()")
	if self:IsOperationRequired() then
		if not self.roster or Util.Tables.Count(self.roster) == 0 then
			self.db.profile.roster = {}
		else
			self.db.profile.roster = Util.Tables.Map(
					Util.Tables.Copy(self.roster),
					function(e) return e:toTable() end
			)
		end
	end
end

function Standby:GetAwardRoster()
	if self:IsOperationRequired() then
		-- this is the trigger than award is being done, so if we check after each award then
		-- schedule pings and cleanup before returning result
		if self.db.profile.verify_after_each_award then
			self:ScheduleTimer(function() self:PingPlayers() end, 2)
			self:ScheduleTimer(function() self:PruneRoster() end, 7)
		end

		local roster = {}
		for name, _ in pairs(self.roster) do
			Util.Tables.Push(roster, AddOn:UnitName(name))
		end

		-- return roster of names and award %
		return roster, self.db.profile.standby_pct
	end
end

--- @return table
local Options = Util.Memoize.Memoize(function(self)
	local builder = AceUI.ConfigBuilder()

	builder:group(self:GetName(), L["standby"]):desc(L["standby_desc"])
		:args()
			:group('enabled', L['standby_toggle']):set('inline', true):order(1)
				:args()
					:toggle('enabled', L["enable"]):desc(L["standby_toggle_desc"]):order(0)
				:close()
			:group('settings', L['settings']):set('inline', true):order(2)
				:args()
					:toggle('verify_after_each_award', L["verify_after_each_award"]):desc(L["verify_after_each_award_desc"]):order(1)
						:set('disabled', function() return not self.db.profile.enabled end):set('width', 'full')
					:range("standby_pct", L["standby_pct"], 0, 1, 0.1):desc(L["standby_pct_desc"]):order(2)
						:set('isPercent', true)
						:set('disabled', function () return not self.db.profile.enabled end)
				:close()
			:execute('open', L["standby_open"]):desc(L["standby_open_desc"]):order(3)
				:set('func', function() AddOn:CallModule("Standby") end)

	return builder:build()
end)

function Standby:BuildConfigOptions()
	local options = Options(self)
	return options[self:GetName()], false
end