local name, AddOn = ...

-- this will be first non-library file to load
-- shim it here so available until re-established
if not AddOn._IsTestContext then AddOn._IsTestContext = function() return false end end

AddOn.Constants = {
    name    =   name,
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
        Evergreen       =   CreateColor(0, 1, 0.59, 1),
        ItemArtifact    =   _G.ITEM_QUALITY_COLORS[6].color,
        ItemCommon      =   _G.ITEM_QUALITY_COLORS[1].color,
        ItemEpic        =   _G.ITEM_QUALITY_COLORS[4].color,
        ItemHeirloom    =   _G.ITEM_QUALITY_COLORS[7].color,
        ItemLegendary   =   _G.ITEM_QUALITY_COLORS[5].color,
        ItemPoor        =   _G.ITEM_QUALITY_COLORS[0].color,
        ItemRare        =   _G.ITEM_QUALITY_COLORS[3].color,
        ItemUncommon    =   _G.ITEM_QUALITY_COLORS[2].color,
    },
    
    Commands = {
        PlayerInfo              =   "pi",
        PlayerInfoRequest       =   "pir",
    },

    DropDowns = {
        StandingsRightClick     = name .. "_Standings_RightClick",
        StandingsFilter         = name .. "_Standings_Filter",
    },

    Events = {
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

    Messages = {

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
    },

    Responses = {

    },

    VersionStatus = {

    }
}