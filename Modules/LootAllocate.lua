--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @class LootAllocate
local LA = AddOn:NewModule("LootAllocate", "AceBucket-3.0")

function LA:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.active = false
	self.session = 0
end

function LA:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:SubscribeToComms()
end

function LA:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.active = false
	self.session = 0
	self:UnregisterAllBuckets()
	self:UnsubscribeFromComms()
end

function LA:EnableOnStartup()
	return false
end

function LA:ReceiveLootTable(lt)
	Logging:Debug("ReceiveLootTable()")
	self.active = true
end

function LA:SubscribeToComms()
	Logging:Debug("SubscribeToComms(%s)", self:GetName())
	self.commSubscriptions = Comm():BulkSubscribe(C.CommPrefixes.Main, {
		[C.Commands.Response] = function(data, sender)
			Logging:Debug("Response from %s", tostring(sender))
		end,
		[C.Commands.LootAck] = function(data, sender)
			Logging:Debug("LootAck from %s", tostring(sender))
		end,
	})
end

function LA:UnsubscribeFromComms()
	Logging:Debug("UnsubscribeFromComms(%s)", self:GetName())
	if self.commSubscriptions then
		for _, subscription in pairs(self.commSubscriptions) do
			subscription:unsubscribe()
		end
		self.commSubscriptions = nil
	end
end