--- @type AddOn
local name, AddOn = ...

-- this will be first non-library file to load
-- shim it here so available until re-established
if not AddOn._IsTestContext then AddOn._IsTestContext = function() return false end end

AddOn.Constants = {
    name    =   name,
    name_c  =   "|CFF87CEFA" .. name .. "|r",
    chat    =   "chat",
    group   =   "group",
    guild   =   "guild",
    player  =   "player",
    party   =   "party",

    Buttons = {
        Left    =   "LeftButton",
        Right   =   "RightButton",
    },

    CommPrefixes = {
      Main      =   name,
      Version   =   name .. 'v',
      Sync      =   name .. 's',
    },

    Channels = {
        None        =   "NONE",
        Guild       =   "GUILD",
        Instance    =   "INSTANCE_CHAT",
        Officer     =   "OFFICER",
        Party       =   "PARTY",
        Raid        =   "RAID",
        RaidWarning =   "RAID_WARNING",
        Whisper     =   "WHISPER",
    },

    Colors = {
        Blue            =   CreateColor(0, 0.44, 0.87, 1),
        DeathKnightRed  =   CreateColor(0.77,0.12,0.23,1),
        Evergreen       =   CreateColor(0, 1, 0.59, 1),
        ItemArtifact    =   _G.ITEM_QUALITY_COLORS[6].color,
        ItemCommon      =   _G.ITEM_QUALITY_COLORS[1].color,
        ItemEpic        =   _G.ITEM_QUALITY_COLORS[4].color,
        ItemHeirloom    =   _G.ITEM_QUALITY_COLORS[7].color,
        ItemLegendary   =   _G.ITEM_QUALITY_COLORS[5].color,
        ItemPoor        =   _G.ITEM_QUALITY_COLORS[0].color,
        ItemRare        =   _G.ITEM_QUALITY_COLORS[3].color,
        ItemUncommon    =   _G.ITEM_QUALITY_COLORS[2].color,
        MageBlue        =   CreateColor(0.25, 0.78, 0.92, 1),
        PaladinPink     =   CreateColor(0.96,0.55,0.73,1),
        Purple          =   CreateColor(0.53, 0.53, 0.93, 1),
        RogueYellow     =   CreateColor(1,0.96,0.41,1),
    },
    
    Commands = {
        PlayerInfo              =   "pi",
        PlayerInfoRequest       =   "pir",
        LootTable               =   "lt",
        MasterLooterDbRequest   =   "mldbr",
        Reconnect               =   "rct",
    },

    DropDowns = {
        StandingsRightClick     = name .. "_Standings_RightClick",
        StandingsFilter         = name .. "_Standings_Filter",
    },

    Events = {
        ChatMessageWhisper      =   "CHAT_MSG_WHISPER",
        EncounterEnd            =   "ENCOUNTER_END",
        EncounterStart          =   "ENCOUNTER_START",
        GroupLeft               =   "GROUP_LEFT",
        LootClosed              =   "LOOT_CLOSED",
        LootOpened              =   "LOOT_OPENED",
        LootReady               =   "LOOT_READY",
        LootSlotCleared         =   "LOOT_SLOT_CLEARED",
        PlayerEnteringWorld     =   "PLAYER_ENTERING_WORLD",
        PartyLootMethodChanged  =   "PARTY_LOOT_METHOD_CHANGED",
        PartyLeaderChanged      =   "PARTY_LEADER_CHANGED",
        PlayerRegenEnabled      =   "PLAYER_REGEN_ENABLED",
        PlayerRegenDisabled     =   "PLAYER_REGEN_DISABLED",
        RaidInstanceWelcome     =   "RAID_INSTANCE_WELCOME",
    },

    -- this is probably a misnomer since it's mixed names, but whatever...
    ItemEquipmentLocationNames = {
        Bows            =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_BOWS),
        Chest           =   _G.INVTYPE_CHEST,
        Cloak           =   _G.INVTYPE_CLOAK,
        Crossbows       =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_CROSSBOW),
        Feet            =   _G.INVTYPE_FEET,
        Finger          =   _G.INVTYPE_FINGER,
        Guns            =    GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_GUNS),
        Head            =   _G.INVTYPE_HEAD,
        Hand            =   _G.INVTYPE_HAND,
        Holdable        =   _G.INVTYPE_HOLDABLE,
        Idol            =   GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_IDOL),
        Legs            =   _G.INVTYPE_LEGS,
        Libram          =   GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_LIBRAM),
        MainHandWeapon  =   ("%s %s"):format(_G.INVTYPE_WEAPONMAINHAND, _G.WEAPON),
        Neck            =   _G.INVTYPE_NECK,
        OffHandWeapon   =   ("%s %s"):format(_G.INVTYPE_WEAPONOFFHAND, _G.WEAPON),
        OneHandWeapon   =   ("%s %s"):format(_G.INVTYPE_WEAPON, _G.WEAPON),
        Ranged          =   _G.INVTYPE_RANGED,
        Relic           =   _G.INVTYPE_RELIC,
        Shield          =   _G.SHIELDSLOT,
        Shoulder        =   _G.INVTYPE_SHOULDER,
        Thrown          =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_THROWN),
        Totem           =   GetItemSubClassInfo(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_TOTEM),
        Trinket         =   _G.INVTYPE_TRINKET,
        TwoHandWeapon   =   ("%s %s"):format(_G.INVTYPE_2HWEAPON, _G.WEAPON),
        Waist           =   _G.INVTYPE_WAIST,
        Wand            =   GetItemSubClassInfo(LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_WAND),
        WeaponMainHand  =   _G.INVTYPE_WEAPONMAINHAND,
        WeaponOffHand   =   _G.INVTYPE_WEAPONOFFHAND,
        WeaponTwoHand   =   _G.INVTYPE_2HWEAPON,
        Wrist           =   _G.INVTYPE_WRIST,
    },

    ItemQualityDescriptions = {
        [0] = ITEM_QUALITY0_DESC, -- Poor
        [1] = ITEM_QUALITY1_DESC, -- Common
        [2] = ITEM_QUALITY2_DESC, -- Uncommon
        [3] = ITEM_QUALITY3_DESC, -- Rare
        [4] = ITEM_QUALITY4_DESC, -- Epic
        [5] = ITEM_QUALITY5_DESC, -- Legendary
        [6] = ITEM_QUALITY6_DESC, -- Artifact
    },

    Messages = {
        ConfigTableChanged      =   name .. "_ConfigTableChanged",
    },

    Modes = {
        Standard                =   0x01,
        Test                    =   0x02,
        Develop                 =   0x04,
        Persistence             =   0x08,
    },
    
    Popups = {
        ConfirmAdjustPoints     =   name .. "_ConfirmAdjustPoints",
        ConfirmDecayPoints      =   name .. "_ConfirmDecayPoints",
        ConfirmDeleteItem       =   name .. "_ConfirmDeleteItem",
    },

    Responses = {

    },

    VersionStatus = {

    }
}