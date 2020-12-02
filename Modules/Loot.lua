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
--- @class Loot
local Loot = AddOn:NewModule("Loot")

local RANDOM_ROLL_PATTERN =
	_G.RANDOM_ROLL_RESULT:gsub("%(", "%%(")
	  :gsub("%)", "%%)")
	  :gsub("%%%d%$", "%%")
	  :gsub("%%s", "(.+)")
	  :gsub("%%d", "(%%d+)")

function Loot:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
end

function Loot:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToEvents()
end

function Loot:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self:UnsubscribeFromEvents()
end

function Loot:EnableOnStartup()
	return false
end

function Loot:SubscribeToEvents()
	Logging:Debug("SubscribeToEvents(%s)", self:GetName())
	self.eventSubscriptions = Event():BulkSubscribe({
	  [C.Events.ChatMessageSystem] = function(_, msg)
		  Logging:Debug("%s - %s",C.Events.ChatMessageSystem, Util.Objects.ToString(msg))
		  self:OnChatMessage(msg)
	  end
	})
end

function Loot:UnsubscribeFromEvents()
	Logging:Debug("UnsubscribeFromEvents(%s)", self:GetName())
	if self.eventSubscriptions then
		for _, subscription in pairs(self.eventSubscriptions) do
			subscription:unsubscribe()
		end
		self.eventSubscriptions = nil
	end
end

function Loot:OnChatMessage(msg)
	Logging:Trace("OnChatMessage()")
	local name, roll, low, high = msg:match(RANDOM_ROLL_PATTERN)
	roll, low, high = tonumber(roll), tonumber(low), tonumber(high)
	--if name and low == 1 and high == 100 and AddOn:UnitIsUnit(Ambiguate(name, "short"), "player") and awaitingRolls[1] then
	--	local el = awaitingRolls[1]
	--	tremove(awaitingRolls, 1)
	--	self:CancelTimer(el.timer)
	--	local entry = el.entry
	--	AddOn:SendCommand(C.group, C.Commands.Roll, AddOn.playerName, roll, entry.item.sessions)
	--	AddOn:SendAnnouncement(format(L["roll_result"], AddOn.Ambiguate(AddOn.playerName), roll, entry.item.link), C.group)
	--	entry.rollResult:SetText(roll)
	--	entry.rollResult:Show()
	--	self:ScheduleTimer("OnRollTimeout", ROLL_SHOW_RESULT_TIME, el)
	--end
end

function Loot:Start(lt, reRoll)
	reRoll = Util.Objects.IsSet(reRoll) and reRoll or false
	Logging:Debug("Start(%s)", tostring(reRoll))
end