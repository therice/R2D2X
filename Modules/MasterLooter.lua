--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @class MasterLooter
local ML = AddOn:NewModule("MasterLooter", "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0", "AceHook-3.0")

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
	}
}

function ML:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), ML.Defaults)
	self.sender = Comm():GetSender(C.CommPrefixes.Main)
end

function ML:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToEvents()
	self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
	self:SubscribeToComms()
end

function ML:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
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
		[C.Commands.MasterLooterDbRequest] = function(data)

		end,
		[C.Commands.Reconnect] = function(_, sender)

		end,
		[C.Commands.LootTable] = function(_, sender)

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