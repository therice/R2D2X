--- @type AddOn
local _, AddOn = ...
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type LibGearPoints
local GP = AddOn:GetLibrary('GearPoints')
--- @type table<number, Models.Item.Item>
local cache = {}

--
-- Item
--
-- This is intended to be a wrapper around item information obtained via native APIs, with additional attributes
-- such as classes which can use
--
--[[
Example Item(s) via GetItemInfo
{
	id = 12757,
	link = [Breastplate of Bloodthirst],
	quality = 4 -- Epic
	ilvl = 62,
	type = Armor,
    equipLoc = INVTYPE_CHEST,
    subType = Leather,
    texture = 132635,
    typeId = 4, -- LE_ITEM_CLASS_ARMOR
    subTypeId = 2, -- LE_ITEM_ARMOR_LEATHER
    bindType=  1 -- 0 - none; 1 - on pickup; 2 - on equip (LE_ITEM_BIND_ON_EQUIP); 3 - on use; 4 - quest
    classes = 4294967295,
},
{
	id = 14555,
	link = [Alcor's Sunrazor],
	quality = 4
	ilvl = 63,
	type = Weapon,
    equipLoc = INVTYPE_WEAPON,
    subType = Daggers,
    texture = 135344,
    typeId = 2,
    subTypeId = 15,
    bindType = 2,
    classes = 4294967295,
}
--]]
--- @class Models.Item.Item
local Item = AddOn.Package('Models.Item'):Class('Item')
function Item:initialize(id, link, quality, ilvl, type, equipLoc, subType, texture, typeId, subTypeId, bindType, classes)
	self.id        = id
	self.link      = link
	self.quality   = quality
	self.ilvl      = ilvl
	self.typeId    = typeId
	self.type      = type
	self.equipLoc  = equipLoc
	self.subTypeId = subTypeId
	self.subType   = subType
	self.texture   = texture
	self.bindType  = bindType
	self.classes   = classes
end

-- create an Item via GetItemInfo
-- item can be a number, name, itemString, or itemLink
-- https://wow.gamepedia.com/API_GetItemInfo
local function ItemQuery(item)
	Logging:Debug("ItemQuery(%s)", tostring(item))

	local name, link, rarity, ilvl, _, type, subType, _, equipLoc, texture, _,
		typeId, subTypeId, bindType  = GetItemInfo(item)
	local id = link and ItemUtil:ItemLinkToId(link)
	if name then
		-- check to see if a custom item has been setup for the id
		-- which overrides anything provided by API
		local customItem = ItemUtil:GetCustomItem(tonumber(id))
		-- Logging:Debug("CustomItem = %s, %s", Util.Objects.ToString(customItem), tostring(not customItem and subType or nil))
		if Util.Objects.IsSet(customItem) then
			rarity = customItem.rarity
			ilvl = customItem.item_level
			equipLoc = customItem.equip_location
			subType = nil
			subTypeId = nil
		end

		Logging:Debug("ItemQuery(%s) : results available", tostring(item))

		return Item:new(
				id,
				link,
				rarity,
				ilvl,
				type,
				equipLoc,
				subType,
				texture,
				typeId,
				subTypeId,
				bindType,
				ItemUtil:GetItemClassesAllowedFlag(link)
		)
	end

	Logging:Debug("ItemQuery(%s) : NO results available", tostring(item))
	return nil
end

--- @return boolean
function Item:IsBoe()
	return self.bindType == LE_ITEM_BIND_ON_EQUIP
end

--- @return boolean
function Item:IsValid()
	return ((self.id and self.id > 0) and Util.Strings.IsSet(self.link))
end

--- @return string
function Item:GetLevelText()
	if not self.ilvl then return "" end
	return tostring(self.ilvl)
end

--- @return string
function Item:GetTypeText()
	if Util.Strings.IsSet(self.equipLoc) and getglobal(self.equipLoc) then
		local typeId = self.typeId
		local subTypeId = self.subTypeId
		if self.equipLoc ~= "INVTYPE_CLOAK" and
				(
					not (typeId == LE_ITEM_CLASS_MISCELLANEOUS and subTypeId == LE_ITEM_MISCELLANEOUS_JUNK) and
					not (typeId == LE_ITEM_CLASS_ARMOR and subTypeId == LE_ITEM_ARMOR_GENERIC) and
					not (typeId == LE_ITEM_CLASS_WEAPON and subTypeId == LE_ITEM_WEAPON_GENERIC)
				) then
			return getglobal(self.equipLoc) .. (self.subType and (", " .. self.subType) or "")
		else
			return getglobal(self.equipLoc)
		end
	else
		return self.subType or ""
	end
end


--- @param awardReason string an (optional) value which will be used for calculating GP based upon reason
--- @return number, number BASE_GP, AWARD_GP
function Item:GetGp(awardReason)
	if not self.gp then
		self.gp = GP:GetValue(self.link)
	end

	local awardGp
	if self.gp and Util.Objects.IsSet(awardReason) then
		local awardScale = AddOn:GearPointsModule():GetAwardScale(awardReason)
		if awardScale then
			awardGp = Util.Numbers.Round(self.gp * awardScale)
		end
	end

	-- now apply any additional scaling required (such as raid reduction)
	--
	-- this also relies upon the award being completed in the instance where the item dropped
	-- otherwise, it will not be able to infer the raid (map id) for which any scaling should be applied
	--
	awardGp = AddOn:EffortPointsModule():ScaleIfRequired(awardGp and awardGp or self.gp)

	return self.gp or 0, awardGp or 0
end

-- accepts same input types (except itemName) as https://wow.gamepedia.com/API_GetItemInfo
-- itemId : number - Numeric ID of the item. e.g. 30234 for  [Nordrassil Wrath-Kilt]
-- itemName : string - Name of an item owned by the player at some point during this play session, e.g. "Nordrassil Wrath-Kilt".
-- itemString : string - A fragment of the itemString for the item, e.g. "item:30234:0:0:0:0:0:0:0" or "item:30234".
-- itemLink : string - The full itemLink.
function Item.Get(item)
	-- cannot simply use the itemId as a number, as links could represent stuff
	-- that the base item id wouldn't capture (e.g. sockets eventuall)

	-- see if it's a number as first pass
	local itemId = (Util.Objects.IsNumber(item) and item) or (strmatch(item,"^%d+$") and tonumber(item)) or nil
	-- not a number, now check for string permutations
	if not itemId and Util.Objects.IsString(item) and ItemUtil:ContainsItemString(item) then
		itemId = ItemUtil:NeutralizeItem(ItemUtil:ItemLinkToItemString(item))
	end

	-- Logging:Debug('Get(%s) : %s', tostring(item), tostring(itemId))
	if not itemId then error(format("item '%s' couldn't be parsed into a cache key", tostring(item))) end

	local instance = cache[itemId]
	-- local cached = Util.Objects.IsSet(instance)
	if not instance then
		instance = ItemQuery(itemId)
		if instance then
			cache[itemId] = instance
		end
	end

	return instance
end

function Item.ClearCache(item)
	if Util.Objects.IsNil(item) then
		cache = {}
	else
		local itemId = Util.Objects.IsNumber(item) and item or ItemUtil:ItemLinkToId(item)
		if itemId then
			cache[itemId] = nil
		end
	end
end

--- a reference to an item, the the actual item but can be obtained as needed
--- @class Models.Item.ItemRef
local ItemRef = AddOn.Package('Models.Item'):Class('ItemRef')
--- @param item any supports item strings, item links and item ids (not item names)
function ItemRef:initialize(item)
	self.item = item
end

--- @return Models.Item.Item the item represented by the reference
function ItemRef:GetItem()
	return Item.Get(self.item)
end

--- invokes passed function (e.g. a class constructor) with varargs
--- followed by embedding the referenced item's attributes into the
--- value returned by the function
---
--- @param into function
function ItemRef:Embed(into, ...)
	local item = self:GetItem()
	local embed = into(...)
	for k, v in pairs(item:toTable()) do
		embed[k] = v
	end
	for attr, value in pairs(self:toTable()) do
		if not Util.Objects.In(attr, 'ref') then
			embed[attr] = value
		end
	end
	return embed
end

--- @return Models.Item.ItemRef if passed instance is an ItemRef, returns "as is". if the passed instance is a table and has a
--- 'ref' attribute, it will return an new ItemRef  based upon that value. otherwise, returns nil
function ItemRef.Resolve(i)
	if ItemRef:isInstanceOf(i, ItemRef) then
		return i
	end

	if Util.Objects.IsTable(i) and i.ref then
		return Util.Strings.StartsWith(i.ref, "item:") and ItemRef(i.ref) or ItemRef.FromTransmit(i.ref)
	end

	return nil
end

--[[
|cff9d9d9d|Hitem:18832:2564:0:0:0:0:0:0:60:0:0:0:0|h[Brutality Blade]|h|r ->
|cff9d9d9d|Hitem:18832:2564:0:0:0:0:0:::0:0:0:0|h[Brutality Blade]|h|r ->
item:18832:2564:0:0:0:0:0:::0:0:0:0 ->
18832:2564:0:0:0:0:0:::0:0:0:0
--]]
-- not sure we need the actual link here for transmission, but it could contain
-- "stuff" that will eventually be relevant to presenting items to group members
function ItemRef:ForTransmit()
	Logging:Trace("ForTransmit(%s)", tostring(self.item))
	local transmit
	-- if the reference is a number, try to obtain via an actual item lookup
	if Util.Objects.IsNumber(self.item) or strmatch(self.item or "", "^%d+$") then
		local item = self:GetItem()
		if item and item.link then
			transmit = item.link
		else
			transmit = 'item:' .. self.item
		end
	elseif ItemUtil:ContainsItemString(self.item) then
		transmit = self.item
	else
		error(format("cannot represent ItemRef '%s' for transmission", tostring(self.item)))
	end

	return AddOn.TransmittableItemString(transmit)
end

function ItemRef.FromTransmit(ref)
	return ItemRef(AddOn.DeSanitizeItemString(ref))
end