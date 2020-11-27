local _, AddOn = ...

--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging = AddOn:GetLibrary("Logging")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type table
local cache= {}

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
local Item =  AddOn.Package('Models.Item'):Class('Item')
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
	self.gp        = nil
end

-- create an Item via GetItemInfo
-- item can be a number, name, itemString, or itemLink
-- https://wow.gamepedia.com/API_GetItemInfo
local function ItemQuery(item)
	Logging:Trace("ItemQuery(%s)", tostring(item))

	local name, link, rarity, ilvl, _, type, subType, _, equipLoc, texture, _,
		typeId, subTypeId, bindType, _, _, _ = GetItemInfo(item)
	local id = link and ItemUtil:ItemLinkToId(link)
	if name then
		-- check to see if a custom item has been setup for the id
		-- which overrides anything provided by API
		local customItem = ItemUtil:GetCustomItem(tonumber(id))
		--Logging:Debug("CustomItem = %s, %s", Util.Objects.ToString(customItem), tostring(not customItem and subType or nil))
		return Item:new(
				id,
				link,
				not customItem and rarity or customItem.rarity,
				not customItem and ilvl or customItem.item_level,
				type,
				not customItem and equipLoc or customItem.equip_location,
				not customItem and subType or nil,
				texture,
				typeId,
				not customItem and subTypeId or nil,
				bindType,
				ItemUtil:GetItemClassesAllowedFlag(link)
		)
	else
		return nil
	end
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

-- accepts same input types as https://wow.gamepedia.com/API_GetItemInfo
-- itemId : Number - Numeric ID of the item. e.g. 30234 for  [Nordrassil Wrath-Kilt]
-- itemName : String - Name of an item owned by the player at some point during this play session, e.g. "Nordrassil Wrath-Kilt".
-- itemString ; String - A fragment of the itemString for the item, e.g. "item:30234:0:0:0:0:0:0:0" or "item:30234".
-- itemLink : String - The full itemLink.
function Item.Get(item)
	Logging:Trace('Get(%s)', tostring(item))
	local itemId = Util.Objects.IsNumber(item) and item or ItemUtil:ItemLinkToId(item)
	local instance = cache[itemId]
	if not instance then
		instance = ItemQuery(item)
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
