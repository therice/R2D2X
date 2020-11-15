local _, AddOn = ...
local Util, Logging = AddOn:GetLibrary("Util"), AddOn:GetLibrary("Logging")
local Player = AddOn.Package('Models'):Class('Player')
local GuidPatternPremable, GuidPatternRemainder = "Player%-", "%d?%d?%d?%d%-%x%x%x%x%x%x%x%x"
local GuidPattern = GuidPatternPremable .. GuidPatternRemainder
local cache

local function InitializeCache()
    cache = setmetatable(
            {},
            {
                __index = function(_, id)
                    if not AddOn.db.global.cache.player then AddOn.db.global.cache.player = {} end
                    return AddOn.db.global.cache.player[id]
                end,
                __newindex = function(_, id, v)
                    AddOn.db.global.cache.player[id] = v
                end
            }
    )
end

local function Put(player)
    player.timestamp = GetServerTime()
    cache[player.guid] = player:toTable()
end

local function Get(guid)
    local player = cache[guid]
    if player  then
        Logging:Debug('Get(%s) : %s', tostring(guid), Util.Objects.ToString(player))
        if GetServerTime() - player.timestamp <= 1 then
            return Player:reconstitute(player)
        end
    end
end

local function GUID(name)
    for guid, player in pairs(AddOn.db.global.cache.player) do
        if Util.Strings.Equal(Ambiguate(player.name, "short"), name) then
            return guid
        end
    end
end

InitializeCache()

function Player:initialize(guid, name, class, realm)
    self.guid = guid
    self.name = name and AddOn:UnitName(name) or nil
    self.class = class
    self.realm = realm
    self.timestamp = -1
end

function Player:GetName()
    return self.name
end

function Player:GetShortName()
    return Ambiguate(self.name, "short")
end

function Player:ForTransmit()
    return gsub(self.guid, GuidPatternPremable, "")
end

function Player:GetInfo()
    return GetPlayerInfoByGUID(self.guid)
end

function Player:__tostring()
    return self.name .. ' (' .. self.guid .. ')'
end

function Player:__eq(o)
    return Util.Strings.Equal(self.guid, o.guid)
end

function Player.Create(guid)
    Logging:Debug("Create(%s)", tostring(guid))
    if Util.Strings.IsEmpty(guid) then
        return Player(nil, 'Unknown', nil, nil)
    end

    -- https://wow.gamepedia.com/API_GetPlayerInfoByGUID
    -- localizedClass, englishClass, localizedRace, englishRace, sex, name, realm
    local _, class, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    Logging:Debug("Create(%s) : %s, %s, %s", guid, tostring(class), tostring(name), tostring(realm))
    if Util.Objects.IsEmpty(realm) then
        realm = select(2, UnitFullName("player"))
    end

    local player = Player(guid, name, class, realm)
    Put(player)
    return player
end

function Player:Get(input)
    local guid

    Logging:Debug("Get(%s)", tostring(input))

    if Util.Strings.IsSet(input) then
        if not strmatch(input, GuidPatternPremable) and strmatch(input, GuidPatternRemainder) then
            guid = "Player-" .. input
        elseif strmatch(input, GuidPattern) then
            guid = input
        else
            local name = Ambiguate(input, "short")
            guid = UnitGUID(name)
            -- GUID(s) are only available for people we're grouped with
            -- so attempt a few other approaches if not available
            --
            -- via existing cached players
            if Util.Strings.IsEmpty(input) then
                guid = GUID(name)
                -- last attempt is try via the guild
                if Util.Strings.IsEmpty(input) then
                    -- todo : determine if we want to use LibGuild or just query directly
                end
            end
        end
    else
        error(format("%s is an invalid player", tostring(input)), 2)
    end

    Logging:Debug("Get(%s) : %s", tostring(input), tostring(guid))

    if Util.Strings.IsEmpty(guid) then Logging:Warn("Get(%s) : unable to determine GUID", tostring(input)) end
    return Get(guid) or Player.Create(guid)
end

if _G.Models_Player_Testing or _G.R2D2X_Testing then
    function Player.GetCache()
        return AddOn.db.global.cache.player
    end

    function Player.ReinitializeCache()
        cache = nil
        InitializeCache()
    end

    if not AddOn.db then AddOn.db = {} end
    if not Util.Tables.Get(AddOn.db, 'global.cache') then
        Util.Tables.Set(AddOn.db, 'global.cache', {})
    end

    Player.ReinitializeCache()
end

-- Does have GUID @ index 17
-- /run print(GetGuildRosterInfo(1))