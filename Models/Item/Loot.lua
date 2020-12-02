--- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type Models.Item.ItemRef
local ItemRef = AddOn.Package('Models.Item').ItemRef

--- @class Models.Item.LootSlotInfo
local LootSlotInfo = AddOn.Package('Models.Item'):Class('LootSlotInfo', ItemRef)
function LootSlotInfo:initialize(slot, name, link, quantity, quality, bossGuid, bossName)
	-- links work as item references
	ItemRef.initialize(self, link)
	self.slot = slot
	self.name = name
	self.quantity = quantity
	self.quality = quality
	self.bossGuid = bossGuid
	self.bossName = bossName
	self.looted = false
end

--- @return string the full item link
function LootSlotInfo:GetItemLink()
	return self.item
end

--- @class Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item'):Class('LootTableEntry', ItemRef)
function LootTableEntry:initialize(slot, item)
	ItemRef.initialize(self, item)
	self.slot    = slot
	self.awarded = false
	self.sent    = false
	Logging:Debug("LootTableEntry : %s", Util.Objects.ToString(self:toTable()))
end

-- trims down the entry to minimal amount of needed information
-- in order to keep data transmission small
function LootTableEntry:ForTransmit()
	return {
		ref = ItemRef.ForTransmit(self)
	}
end

---@return Models.Item.ItemRef
function LootTableEntry.ItemRefFromTransmit(t)
	if not t or not t.ref then error("no reference provided") end
	return ItemRef.FromTransmit(t.ref)
end

--- @class Models.Item.LootQueueEntry
local LootQueueEntry = AddOn.Package('Models.Item'):Class('LootQueueEntry')
function LootQueueEntry:initialize(slot, callback, args)
	self.slot = slot
	self.callback = callback
	self.args = args
	self.timer = nil
end

---@param awarded boolean was entry cleared as  result of successful award
---@param reason string if not awarded, the reason for failure
function LootQueueEntry:Cleared(awarded, reason)
	if self.callback then
		self.callback(awarded, reason, unpack(self.args))
	end
end