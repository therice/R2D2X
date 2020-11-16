local name, AddOn = ...

AddOn.Constants = {
    name    =   name,
    chat    =   "chat",
    group   =   "group",
    guild   =   "guild",
    player  =   "player",
    party   =   "party",

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
    
    },
    
    Commands = {
    
    },

    DropDowns = {

    },

    Events = {
        GroupLeft               =   "GROUP_LEFT",
        LootClosed              =   "LOOT_CLOSED",
        LootOpened              =   "LOOT_OPENED",
        LootReady               =   "LOOT_READY",
        LootSlotCleared         =   "LOOT_SLOT_CLEARED",
        PlayerEnteringWorld     =   "PLAYER_ENTERING_WORLD",
        PartyLootMethodChanged  =   "PARTY_LOOT_METHOD_CHANGED",
        PartyLeaderChanged      =   "PARTY_LEADER_CHANGED",
    },

    Messages = {
        PlayerInfo              =   "pi",
        PlayerInfoRequest       =   "pir",
    },

    Modes = {
        Standard                =   0x01,
        Test                    =   0x02,
        Develop                 =   0x04,
        Persistence             =   0x08,
    },
    
    Popups = {

    },

    Responses = {

    },

    VersionStatus = {

    }
}