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

    },

    Responses = {

    },

    VersionStatus = {

    }
}