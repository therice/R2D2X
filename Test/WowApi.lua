_G.getfenv = function() return _G end
_G.random = math.random
-- need to set random seed and invoke once to avoid non-random behavior
math.randomseed(os.time())
math.random()

-- utility function for "dumping" a number of arguments (return a string representation of them)
function dump(...)
    local t = {}
    for i=1,select("#", ...) do
        local v = select(i, ...)
        if type(v)=="string" then
            tinsert(t, string.format("%q", v))
        elseif type(v)=="table" then
            tinsert(t, tostring(v).." #"..#v)
        else
            tinsert(t, tostring(v))
        end
    end
    return "<"..table.concat(t, "> <")..">"
end


require('bit')
_G.bit = bit
_G.tInvert = function(tbl)
    local inverted = {};
    for k, v in pairs(tbl) do
        inverted[v] = k;
    end
    return inverted;
end
_G.getfenv = function() return _G end
-- define required function pointers in global space which won't be available in testing
_G.format = string.format
-- https://wowwiki.fandom.com/wiki/API_debugstack
-- debugstack([thread, ][start[, count1[, count2]]]])
-- ignoring count2 currently (lines at end)
_G.debugstack = function (start, count1, count2)
    -- UGH => https://lua-l.lua.narkive.com/ebUKEGpe/confused-by-lua-reference-manual-5-3-and-debug-traceback
    -- If message is present but is neither a string nor nil, this function returns message without further processing.
    -- Otherwise, it returns a string with a traceback of the call stack. An optional message string is appended at the
    -- beginning of the traceback. An optional level number tells at which level to start the traceback
    -- (default is 1, the function calling traceback).
    local stack = debug.traceback()
    local chunks = {}
    for chunk in stack:gmatch("([^\n]*)\n?") do
        -- remove leading and trailing spaces
        local stripped = string.gsub(chunk, '^%s*(.-)%s*$', '%1')
        table.insert(chunks, stripped)
    end

    -- skip first line that looks like 'stack traceback:'
    local start_idx = math.min(start + 2, #chunks)
    -- where to stop, it's the start index + count1 - 1 (to account for counting line where we start)
    local end_idx = math.min(start_idx + count1 - 1, #chunks)
    return table.concat(chunks, '\n', start_idx, end_idx)
end
_G.strmatch = string.match
_G.strjoin = function(delimiter, ...)
    return table.concat({...}, delimiter)
end
_G.string.trim = function(s)
    -- from PiL2 20.4
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

_G.strfind = string.find
_G.gsub = string.gsub
_G.date = os.date
_G.time = os.time
_G.difftime = os.difftime
_G.unpack = table.unpack
_G.tinsert = table.insert
_G.tremove = table.remove
_G.floor = math.floor
_G.strlower = string.lower
_G.strupper = string.upper
_G.mod = function(a,b) return a - math.floor(a/b) * b end

-- https://wowwiki.fandom.com/wiki/API_strsplit
-- A list of strings. Not a table. If the delimiter is not found in the string, the whole subject string will be returned.
_G.strsplit = function(delimiter, str, max)
    local record = {}
    if string.len(str) > 0 then
        max = max or -1

        local field, start = 1, 1
        local first, last = string.find(str, delimiter, start, true)
        while first and max ~= 0 do
            record[field] = string.sub(str, start, first -1)
            field = field +1
            start = last +1
            first, last = string.find(str, delimiter, start, true)
            max = max -1
        end
        record[field] = string.sub(str, start)
    end

    return unpack(record)
end
string.split = _G.strsplit
_G.strsub = string.sub
_G.strbyte = string.byte
_G.strchar = string.char
_G.pack = table.pack
_G.unpack = table.unpack
_G.sort = table.sort
-- this isn't functionally correct
_G.debugprofilestop = function() return 0 end

local wow_api_locale = 'enUS'
function GetLocale()
    return wow_api_locale
end

function SetLocale(locale)
    wow_api_locale = locale
end

_time = 0
function GetTime()
    return _time
end


C_Timer = {}
function C_Timer.After(duration, callback)  end
function C_Timer.NewTimer(duration, callback)  end
function C_Timer.NewTicker(duration, callback, iterations)  end

if not wipe then
    function wipe(tbl)
        for k in pairs(tbl) do
            tbl[k]=nil
        end
    end

    if not table.wipe then
        table.wipe = wipe
    end
end

function hooksecurefunc(func_name, post_hook_func)
    local orig_func = _G[func_name]
    _G[func_name] =
    function (...)
        local ret = { orig_func(...) }
        post_hook_func(...)
        return unpack(ret)
    end
end

function GetFramerate()
    return 60
end

function GetServerTime ()
    return os.time()
end

function GetAddOnMetadata(name, attr)
    if string.lower(attr) == 'version' then
        return "2.0.0-beta"
    else
        return nil
    end
end

function GetAddOnInfo()
    return
end

function GetCurrentRegion()
    return 1 -- "US"
end

function GuildRoster ()  end

function IsInGuild() return 1  end

function IsInRaid() return _G.IsInRaidVal end

function UnitInRaid() return _G.IsInRaidVal end

function IsInGroup() return _G.IsInGroupVal end

function UnitInParty() return _G.IsInGroupVal end

-- https://wow.gamepedia.com/API_UnitIsUnit
function UnitIsUnit(a, b)
    -- extremely rudimentary, doesnt' handle things like resolving targettarget, player, etc
    if a == b then return 1 else return nil end
end


function IsInInstance()
    local type = "none"
    if _G.IsInGroupVal then
        type = "party"
    elseif _G.IsInRaidVal then
        type = "raid"
    end
    return (IsInGroup() or IsInRaid()), type
end


local PlayerToGuid = {
    ['Annasthétic'] = {
        guid = 'Player-4372-011C6125',
        name = 'Annasthétic-Atiesh',
        realm = 'Atiesh',
        class = 'PRIEST',
    },
    Eliovak = {
        guid = 'Player-4372-00706FE5',
        name = 'Eliovak-Atiesh',
        realm = 'Atiesh',
        class = 'ROGUE',
    },
    Folsom = {
        guid = 'Player-4372-007073FE',
        name = 'Folsom-Atiesh',
        realm = 'Atiesh',
        class = 'WARRIOR',
    },
    ['Gnomechómsky'] = {
        guid = 'Player-4372-00C1D806',
        name = 'Gnomechómsky-Atiesh',
        realm = 'Atiesh',
        class = 'WARLOCK',
    },
    Player1 = {
        guid = "Player-1-00000001",
        name = "Player1-Realm1",
        realm = "Realm1",
        class = "WARRIOR"
    },
    Player2 = {
        guid = "Player-1-00000002",
        name = "Player2-Realm1",
        realm = "Realm1",
        class = "WARRIOR"
    },
    Player3 = {
        guid = "Player-1122-00000003",
        name = "Player3-Realm2",
        realm = "Realm2",
        class = "WARRIOR"
    },
}

local PlayerGuidInfo = {}
for _, info in pairs(PlayerToGuid) do
    PlayerGuidInfo[info.guid] = info
end

function AddPlayerGuid(name, guid, realm, class)
    if not PlayerToGuid[name] then
        local info = {
            guid = guid,
            name = name .. '-' .. realm,
            realm = realm,
            class = class
        }
        PlayerToGuid[name] = info
        PlayerGuidInfo[guid] = info
        -- print(format('AddPlayerGuid added %s, %s', name, guid))
    end
end

function GetGuildInfo(unit) return "The Black Watch", "Quarter Master", 1, nil end

function GetGuildInfoText() return "This is my guild info" end

function GetNumGuildMembers() return 10  end

function GetGuildRosterInfo(index)
    local workingIdx = 100 + index
    local name, guid, realm = "Player" .. workingIdx, 'Player-1-' .. string.format("%08d", workingIdx), 'Realm1'
    local classInfo = C_CreatureInfo.GetClassInfo(math.random(1,5))

    AddPlayerGuid(name, guid, realm, classInfo.classFile)

    -- local name, rank, rankIndex, _, class, _, _, officerNote, _, _, classTag, _, _, _, _, _, guid =
    return
        name .. '-' .. realm, 'Member', 2, 60, classInfo.className, 'IronForge', "", "1240, 34", 1, 0, classInfo.classFileName,
        -1, 64, false, false, 3, guid
end

function GetRealmName() return 'Realm1' end

function UnitName(unit)
    if unit == "player" then
        return "Player1"
    elseif unit == "raid1" then
        return "Player1"
    else
        return unit --, "Realm1"
    end
end

function UnitFullName(unit)
    return UnitName(unit), GetRealmName()
end

function UnitClass(unit)
    if unit == "player" then
        return "Warlock", "WARLOCK"
    else
        return "Warrior", "WARRIOR"
    end
end

function UnitRace(unit)
    if unit == "player" then
        return "Gnome", "Gnome"
    else
        return "Human", "Human"
    end
end

function Ambiguate(name, context)
    if context == "short" then
        name = gsub(name, "%-.+", "")
    end
    return name
end

function GetRaidRosterInfo(i)
    local workingIdx = 500 + i
    local name, guid, realm = "Player" .. workingIdx, 'Player-1-' .. string.format("%08d", workingIdx), 'Realm1'
    local classInfo = C_CreatureInfo.GetClassInfo(math.random(1,5))
    AddPlayerGuid(name, guid, realm, classInfo.classFile)

    -- https://wow.gamepedia.com/API_GetRaidRosterInfo
    -- name, _, _, _, _, _, zone, online
    return name, nil, nil, nil, nil, nil, classInfo.classFile, 1
end

function GetInstanceInfo()
    return "Temple of Ahn\'Qiraj", "raid", 1, "40 Player", 40, 0, false, 531, nil
end

function IsLoggedIn() return false end

function GetLootMethod() return "master", nil, 1 end

function IsMasterLooter() return true end

function UnitHealthMax() return 100  end

function UnitHealth() return 50 end

function GetNumRaidMembers() return 40 end

function GetNumPartyMembers() return 5 end

function GetNumGroupMembers() return 40 end


function UnitGUID (name)
    if name == 'player' then name = UnitName(name) end
    if name == 'noguid' then return nil end
    --print(format('UnitGUID(%s)', name))
    return PlayerToGuid[name] and PlayerToGuid[name].guid or "Player-FFF-ABCDF012"
end

function GetPlayerInfoByGUID (guid)
    local player = PlayerGuidInfo[guid]
    if player then
        return nil,player.class, nil,nil,nil, player.name, player.realm
    else
        return nil, "HUNTER", nil,nil,nil, "Unknown", "Unknown"
    end
end


FACTION_HORDE = "Horde"
FACTION_ALLIANCE = "Alliance"

function UnitFactionGroup(unit)
    return FACTION_ALLIANCE, FACTION_ALLIANCE
end

local function _errorhandler(msg)
    print(format("_errorhandler() : %s", dump(msg)))
end

function geterrorhandler()
    return _errorhandler
end


function ChatFrame_AddMessageEventFilter(event, fn)  end

function SendChatMessage(text, chattype, language, destination)
    assert(#text<255)
    WoWAPI_FireEvent("CHAT_MSG_"..strupper(chattype), text, "Sender", language or "Common")
end

local registeredPrefixes = {}
function RegisterAddonMessagePrefix(prefix)
    assert(#prefix<=16)	-- tested, 16 works /mikk, 20110327
    registeredPrefixes[prefix] = true
end

function SendAddonMessage(prefix, message, distribution, target)
    if RegisterAddonMessagePrefix then --4.1+
        assert(#message <= 255,
                string.format("SendAddonMessage: message too long (%d bytes > 255)",
                        #message))
        -- CHAT_MSG_ADDON(prefix, message, distribution, sender)
        WoWAPI_FireEvent("CHAT_MSG_ADDON", prefix, message, distribution, "Sender")
    else -- allow RegisterAddonMessagePrefix to be nilled out to emulate pre-4.1
        assert(#prefix + #message < 255,
                string.format("SendAddonMessage: message too long (%d bytes)",
                        #prefix + #message))
        -- CHAT_MSG_ADDON(prefix, message, distribution, sender)
        WoWAPI_FireEvent("CHAT_MSG_ADDON", prefix, message, distribution, "Sender")
    end
end

C_ChatInfo = {}
C_ChatInfo.RegisterAddonMessagePrefix = RegisterAddonMessagePrefix

C_FriendList = {}

_G.MAX_CLASSES = 9

C_CreatureInfo = {}
C_CreatureInfo.ClassInfo = {
    [1] = {
        "Warrior", "WARRIOR"
    },
    [2] = {
        "Paladin", "PALADIN"
    },
    [3] = {
        "Hunter", "HUNTER"
    },
    [4] = {
        "Rogue", "ROGUE"
    },
    [5] = {
        "Priest", "PRIEST"
    },
    [6] = nil,
    [7] = {
        "Shaman", "SHAMAN"
    },
    [8] = {
        "Mage", "MAGE"
    },
    [9] = {
        "Warlock", "WARLOCK"
    },
    [10] = nil,
    [11] = {
        "Druid", "DRUID"
    },
    [12] = nil,
}

-- className (localized name, e.g. "Warrior"), classFile (non-localized name, e.g. "WARRIOR"), classID
function C_CreatureInfo.GetClassInfo(classID)
    local classInfo = C_CreatureInfo.ClassInfo[classID]
    if classInfo then
        return {
            className = classInfo[1],
            classFile = classInfo[2],
            classID = classID
        }
    end
    return nil
end


SlashCmdList = {}
hash_SlashCmdList = {}

function __WOW_Input(text)
    local a, b = string.find(text, "^/%w+")
    local arg, text = string.sub(text, a, b), string.sub(text, b + 2)
    for k, handler in pairs(SlashCmdList) do
        local i = 0
        while true do
            i = i + 1
            if not _G["SLASH_" .. k .. i] then
                break
            elseif _G["SLASH_" .. k .. i] == arg then
                handler(text)
                return
            end
        end
    end;
    print("No command found:", text)
end

local ChatFrameTemplate = {
    AddMessage = function(self, text)
        print((string.gsub(text, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1")))
    end
}

for i = 1, 7 do
    local f = {}
    for k, v in pairs(ChatFrameTemplate) do
        f[k] = v
    end
    _G["ChatFrame"..i] = f
end
DEFAULT_CHAT_FRAME = ChatFrame1

local Color = {}
function Color:New(r, g, b, a)
    local c = {r=r, g=g, b=b, a=a}
    c['GetRGB'] = function() return c.r, c.g, c.b end
    return c
end

_G.CreateColor = function(r, g, b, a)
    return Color:New(r, g, b, a)
end

_G.ITEM_QUALITY_COLORS = {
    {color = Color:New(1, 0, 0, 0)},
    {color = Color:New(2, 0, 0, 0)},
    {color = Color:New(3, 0, 0, 0)},
    {color = Color:New(4, 0, 0, 0)},
    {color = Color:New(5, 0, 0, 0)},
    {color = Color:New(6, 0, 0, 0)},
    {color = Color:New(7, 0, 0, 0)},
}
_G.ITEM_QUALITY_COLORS[0] = {color = Color:New(0, 0, 0, 0)}

_G.RAID_CLASS_COLORS = {}

-- https://github.com/Gethe/wow-ui-source/tree/classic
_G.INVTYPE_HEAD = "Head"
_G.INVTYPE_NECK = "Neck"
_G.INVTYPE_SHOULDER = "Shoulder"
_G.INVTYPE_CHEST = "Chest"
_G.INVTYPE_WAIST = "Waist"
_G.INVTYPE_LEGS = "Legs"
_G.INVTYPE_FEET = "Feet"
_G.INVTYPE_WRIST = "Wrist"
_G.INVTYPE_HAND = "Hands"
_G.INVTYPE_FINGER = "Finger"
_G.INVTYPE_TRINKET = "Trinket"
_G.INVTYPE_CLOAK = "Back"
_G.SHIELDSLOT = "Shield"
_G.INVTYPE_HOLDABLE = "Held In Off-Hand"
_G.INVTYPE_RANGED = "Ranged"
_G.INVTYPE_RELIC =  "Relic"
_G.INVTYPE_WEAPON = "One-Hand"
_G.INVTYPE_2HWEAPON = "Two-Handed"
_G.INVTYPE_WEAPONMAINHAND = "Main Hand"
_G.INVTYPE_WEAPONOFFHAND = "Off Hand"
_G.WEAPON = "Weapon"
_G.LE_ITEM_WEAPON_AXE1H = 0
_G.LE_ITEM_WEAPON_AXE2H = 1
_G.LE_ITEM_WEAPON_BOWS = 2
_G.LE_ITEM_WEAPON_GUNS = 3
_G.LE_ITEM_WEAPON_MACE1H = 4
_G.LE_ITEM_WEAPON_MACE2H = 5
_G.LE_ITEM_WEAPON_POLEARM = 6
_G.LE_ITEM_WEAPON_SWORD1H = 7
_G.LE_ITEM_WEAPON_SWORD2H = 8
_G.LE_ITEM_WEAPON_WARGLAIVE = 9
_G.LE_ITEM_WEAPON_STAFF = 10
_G.LE_ITEM_WEAPON_BEARCLAW = 11
_G.LE_ITEM_WEAPON_CATCLAW = 12
_G.LE_ITEM_WEAPON_UNARMED = 13
_G.LE_ITEM_WEAPON_GENERIC = 14
_G.LE_ITEM_WEAPON_DAGGER = 15
_G.LE_ITEM_WEAPON_THROWN = 16
_G.LE_ITEM_WEAPON_CROSSBOW = 18
_G.LE_ITEM_WEAPON_WAND = 19
_G.LE_ITEM_ARMOR_GENERIC = 0
_G.LE_ITEM_ARMOR_CLOTH = 1
_G.LE_ITEM_ARMOR_LEATHER = 2
_G.LE_ITEM_ARMOR_MAIL = 3
_G.LE_ITEM_ARMOR_PLATE = 4
_G.LE_ITEM_ARMOR_COSMETIC = 5
_G.LE_ITEM_ARMOR_SHIELD = 6
_G.LE_ITEM_ARMOR_LIBRAM = 7
_G.LE_ITEM_ARMOR_IDOL = 8
_G.LE_ITEM_ARMOR_TOTEM = 9
_G.LE_ITEM_ARMOR_SIGIL = 10
_G.LE_ITEM_ARMOR_RELIC = 11

_G.LE_ITEM_CLASS_WEAPON = 2
_G.LE_ITEM_CLASS_ARMOR = 4

_G.RANDOM_ROLL_RESULT = "%s rolls %d (%d-%d)"

_G.TOOLTIP_DEFAULT_BACKGROUND_COLOR = {
    r = 0,
    g = 0,
    b = 0,
}
_G.TOOLTIP_DEFAULT_COLOR = {
    r = 0,
    g = 0,
    b = 0,
}

_G.AUTO_LOOT_DEFAULT_TEXT = "Auto Loot"


_G.UNKNOWNOBJECT = "Unknown"
_G.StaticPopup_DisplayedFrames = {}

_G.PlaySound = function(...) end

_G.FauxScrollFrame_Update = function() end
_G.FauxScrollFrame_GetOffset = function() return 0 end
_G.CLASS_ICON_TCOORDS = {}

loadfile('Test/WowApiUI.lua')()