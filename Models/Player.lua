local _, AddOn = ...
local Util, Logging, GuildStorage = AddOn:GetLibrary("Util"), AddOn:GetLibrary("Logging"), AddOn:GetLibrary("GuildStorage")
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
        Logging:Trace('Get(%s) : %s', tostring(guid), Util.Objects.ToString(player))
        -- todo
        if GetServerTime() - player.timestamp > 0 then return Player:reconstitute(player) end
    else
        Logging:Trace("Get(%s) : No cached entry", tostring(guid))
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

function Player:IsValid()
    return Util.Objects.IsSet(self.guid) and Util.Objects.IsSet(self.name)
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

function Player.Create(guid, info)
    Logging:Trace("Create(%s) : info=%s", tostring(guid), tostring(Util.Objects.IsSet(info)))
    if Util.Strings.IsEmpty(guid) then return Player(nil, 'Unknown', nil, nil) end

    -- https://wow.gamepedia.com/API_GetPlayerInfoByGUID
    -- The information is not encoded in the GUID itself; as such, no data is available until
    -- the client has encountered the queried GUID.
    -- localizedClass, englishClass, localizedRace, englishRace, sex, name, realm
    local _, class, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    Logging:Trace("Create(%s) : info query -> class=%s, name=%s, realm=%s", guid, tostring(class), tostring(name), tostring(realm))
    -- if the name is not set, means the query did not complete. likely because the player was not
    -- encountered. therefore, just return nil if thats the case
    if Util.Objects.IsEmpty(name) then
        Logging:Warn("Create(%s) : Unable to obtain player information via GetPlayerInfoByGUID", guid)
        if info and Util.Strings.IsSet(info.name) then
            Logging:Trace("Create(%s) : Using provided player information", guid)
            name = info.name
            class = info.classTag or info.class
        else
            return nil
        end
    end

    if Util.Objects.IsEmpty(realm) then realm = select(2, UnitFullName("player")) end

    local player = Player(guid, name, class, realm)
    Logging:Trace("Create(%s) : created %s", guid, Util.Objects.ToString(player:toTable()))
    Put(player)
    return player
end

--/run print(R2D2X.Package('Models').Player:Get('Eliovak'))
--/run print(R2D2X.Package('Models').Player:Get('Eliovak-Atiesh'))
--/run print(R2D2X.Package('Models').Player:Get('Gnomechómsky'))
function Player:Get(input)
    local guid, info

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
            if Util.Strings.IsEmpty(guid) then
                guid = GUID(name)
                -- last attempt is try via the guild
                if Util.Strings.IsEmpty(guid) then
                    -- fully qualify the name for guild query
                    info = GuildStorage:GetMember(AddOn:UnitName(name))
                    if info then guid = info.guid end
                end
            end
        end
    else
        error(format("%s is an invalid player", tostring(input)), 2)
    end

    Logging:Debug("Get(%s) : GUID=%s", tostring(input), tostring(guid))

    if Util.Strings.IsEmpty(guid) then Logging:Warn("Get(%s) : unable to determine GUID", tostring(input)) end
    return Get(guid) or Player.Create(guid, info)
end

if AddOn._IsTestContext('Models_Player') then
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

