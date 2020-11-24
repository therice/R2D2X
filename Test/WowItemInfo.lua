-- https://wowwiki.fandom.com/wiki/API_GetItemInfo
-- https://wowwiki.fandom.com/wiki/ItemString
--
-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
-- itemEquipLoc, itemIcon, itemSellPrice, typeId, subTypeId, bindType, expacID, itemSetID
-- isCraftingReagent
--
-- itemLink - e.g. |cFFFFFFFF|Hitem:12345:0:0:0|h[Item Name]|h|r
-- itemType : Localized name of the item’s class/type.
-- itemSubType : Localized name of the item’s subclass/subtype.
-- itemEquipLoc : Non-localized token identifying the inventory type of the item
local IdToInfo = {
    -- https://classic.wowhead.com/item=18832/brutality-blade
    [18832] = {
        'Brutality Blade',
        -- there are attributes in this link which aren't standard/plain, but bonuses (e.g. enchant at 2564)
        '|cff9d9d9d|Hitem:18832:2564:0:0:0:0:0:0:80:0:0:0:0|h[Brutality Blade]|h|r',
        4, --itemRarity
        70, --itemLevel
        60, --itemMinLevel
        "Weapon", --itemType
        'One-Handed Swords', --itemSubType
        1, --itemStackCount
        "INVTYPE_WEAPON", --itemEquipLoc
        135313,--itemIcon
        104089, --itemSellPrice
        2, --typeId
        7, --subTypeId
        1, --bindType
        254, --expacID
        nil, --itemSetID
        false --isCraftingReagent
    },
    [21232] = {
        'Imperial Qiraji Armaments',
        '|cff9d9d9d|Hitem:21232:0:0:0:0:0:0:0:80:0:0:0:0|h[Imperial Qiraji Armaments]|h|r',
    },
    [18646] = {
        'The Eye of Divinity',
        '|cff9d9d9d|Hitem:18646:0:0:0:0:0:0:0:80:0:0:0:0|h[The Eye of Divinity]|h|r',
    },
    [17069] = {
        'Striker\'s Mark',
        '|cff9d9d9d|Hitem:17069:0:0:0:0:0:0:0:80:0:0:0:0|h[Striker\'s Mark]|h|r',
    },
    [22356] = {
        'Desecrated Waistguard',
        '|cff9d9d9d|Hitem:22356:0:0:0:0:0:0:0:80:0:0:0:0|h[Desecrated Waistguard]|h|r',
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        133828
    }
}

-- item can be one of following input types
-- 	Numeric ID of the item. e.g. 30234
-- 	Name of an item owned by the player at some point during this play session, e.g. "Nordrassil Wrath-Kilt"
--  A fragment of the itemString for the item, e.g. "item:30234:0:0:0:0:0:0:0" or "item:30234"
--  The full itemLink (e.g. |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0|h[Broken Fang]|h|r )
local function ItemInfo(item)
    -- Numeric ID of the item. e.g. 30234
    if type(item) == 'number' or tonumber(item) ~= nil then
        return item, IdToInfo[tonumber(item)] or {}
    end

    if type(item) == 'string' then
        -- Check if item string or full link
        local id = strmatch(item or "", "item:(%d+):")
        -- print(item .. ' -> ' .. tostring(id))
        if id and id ~= "" then
            return tonumber(id), IdToInfo[tonumber(id)]
            -- it's an item name
        else
            for id, info in pairs(IdToInfo) do
                if info[1] == item then
                    return id, info or {}
                end
            end

        end
    end

    return 0, {}
end

-- todo : GetItemInfo and GetItemInfoInstant only support number params at moment
_G.GetItemInfo = function(item)
    local _, info = ItemInfo(item)
    return unpack(info)
end

-- itemID, itemType, itemSubType, itemEquipLoc, icon, itemClassID, itemSubClassID
-- GetItemInfoInstant(itemID or "itemString" or "itemName" or "itemLink")
-- https://wow.gamepedia.com/API_GetItemInfoInstant
_G.GetItemInfoInstant = function(item)
    local id, info = ItemInfo(item)

    if id > 0 then
        return id,
        info and info[6] or nil,
        info and info[7] or nil,
        info and info[9] or nil,
        info and info[10] or nil,
        info and info[12] or nil,
        info and info[13] or nil
    end
end
