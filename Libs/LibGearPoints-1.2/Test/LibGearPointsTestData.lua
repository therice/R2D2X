TestCustomItems = {
    ["21232"] = {
        ["item_level"] = 79,
        ["equip_location"] = "INVTYPE_WEAPON",
        ["rarity"] = 4,
        ["default"] = true,
    },
    ["18646"] = {
        ["gp"] = 44,
        ["default"] = true,
        ["item_level"] = 75,
        ["equip_location"] = "CUSTOM_GP",
        ["rarity"] = 4,
    },
    ["17069"] = {
        ["scale"] = 0.75,
        ["rarity"] = 4,
        ["item_level"] = 69,
        ["equip_location"] = "CUSTOM_SCALE",
        ["default"] = false,
    },

}

TestScalingConfig =  {
    weapon = {
        {1.5,'One-Hand Weapon'},
        {0.5, 'Off Hand Weapon / Tank Main Hand Weapon'},
        {0.15, 'Hunter One-Hand Weapon'},
    },
    weaponmainh = {
        {1.5, 'Main Hand Weapon'},
        {0.25, 'Hunter One Hand Weapon'},
    },
    weaponoffh = {
        {0.5, 'Off Hand Weapon'},
        {0.25, 'Hunter One Hand Weapon'},
    },
    ranged = {
        {2.0, 'Hunter Ranged'},
        {0.3, 'Non-Hunter Ranged'},
    },
    shield = {
        {0.5}
    }
}

-- Stub defaults for AceDB
DbScalingDefaults = {
    profile = {

    }
}

do
    local ConfigIndexMappings = {
        'scale',
        'comment',
    }

    for slot, config in pairs(TestScalingConfig) do
        local index = 1
        for _, config_entry in pairs(config) do
            for i=1, #config_entry do
                local profileEntryKey = slot .. '_' .. ConfigIndexMappings[i] .. '_' .. index
                DbScalingDefaults.profile[profileEntryKey] = config_entry[i]
            end
            index = index +1
        end
    end

end
