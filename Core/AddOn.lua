
--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibGuildStorage
local GuildStorage =  AddOn:GetLibrary('GuildStorage')
--- @type Core.Comm
local Comm = AddOn.Require('Core.Comm')
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Core.SlashCommands
local SlashCommands = AddOn.Require('Core.SlashCommands')

function AddOn:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())
    -- convert to a semantic version
    self.version = AddOn.Package('Models').SemanticVersion(self.version)
    -- bitfield which keeps track of our operating mode
    self.mode = AddOn.Package('Core').Mode()
    -- is the addon enabled, can be altered at runtime
    self.enabled = true
    -- tracks information about the player at time of login and when encounters begin
    self.playerData = {
        -- slot number -> item link
        gear = {
        }
    }
    -- our guild (start off as unguilded, will get callback when ready to populate)
    self.guildRank = L["unguilded"]
    -- the master looter (Player)
    self.masterLooter = nil
    -- capture looting method for later required checks
    self.lootMethod = GetLootMethod() or "freeforall"
    -- does addon handle loot?
    self.handleLoot = false

    self.db = self:GetLibrary("AceDB"):New(self:Qualify('DB'), self.Defaults)
    if not AddOn._IsTestContext() then Logging:SetRootThreshold(self.db.profile.logThreshold) end

    -- register slash commands
    SlashCommands:Register()
    self:RegisterChatCommands()
    -- setup comms
    Comm:Register(C.CommPrefixes.Main)
    Comm:Register(C.CommPrefixes.Version)
    self.Send = Comm:GetSender(C.CommPrefixes.Main)
    self:SubscribeToPermanentComms()
end

function AddOn:OnEnable()
    Logging:Debug("OnEnable(%s)", self:GetName())

    --@debug@
    -- this enables certain code paths that wouldn't otherwise be available in normal usage
    self.mode:Enable(AddOn.Constants.Modes.Develop)
    --@end-debug@

    -- this enables flag for persistence of stuff like points to officer's notes, history, and sync payloads
    -- it can be disabled as needed through /r2d2 pm
    self.mode:Disable(AddOn.Constants.Modes.Persistence)
    -- todo : go back to enabled once out of development
    -- self.mode:Enable(AddOn.Constants.Modes.Persistence)
    self.player = Player:Get("player")

    Logging:Debug("OnEnable(%s) : %s", self:GetName(), tostring(self.player))

    for name, module in self:IterateModules() do
        Logging:Debug("OnEnable(%s) : Examining module (startup) '%s'", self:GetName(), name)

        if module:EnableOnStartup() then
            Logging:Debug("OnEnable(%s) : Enabling module (startup) '%s'", self:GetName(), name)
            module:Enable()
        end
    end

    if IsInGuild() then
        -- Register with guild storage for state change callback
        GuildStorage.RegisterCallback(
                self,
                GuildStorage.Events.StateChanged,
                function(event, state)
                    Logging:Debug("GuildStorage.Callback(%s, %s)", tostring(event), tostring(state))
                    if state == GuildStorage.States.Current then
                        local me = GuildStorage:GetMember(AddOn.player:GetName())
                        if me then
                            AddOn.guildRank = me.rank
                            GuildStorage.UnregisterCallback(self, GuildStorage.Events.StateChanged)
                            Logging:Debug("GuildStorage.Callback() : Guild Rank = %s", AddOn.guildRank)
                        else
                            Logging:Debug("GuildStorage.Callback() : Not Found")
                            AddOn.guildRank = L["not_found"]
                        end
                    end
                end
        )

        -- todo
        -- self:ScheduleTimer("SendGuildVersionCheck", 2)
    end

    -- register events
    self:SubscribeToEvents()
    -- register configuration
    self:RegisterConfig()
    -- add minimap button
    self:AddMinimapButton()
    self:Print(format(L["chat version"], tostring(self.version)) .. " is now loaded. Thank you for trusting us to handle all your EP/GP needs!")

    -- this filters out any responses to whispers related to addon
    local ChatMsgWhisperInformFilter = function(_, event, msg, player, ...)
        return strfind(msg, "[[\'" .. self:GetName() .. "\']]:")
    end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ChatMsgWhisperInformFilter)
end

function AddOn:OnDisable()
    Logging:Debug("OnDisable(%s)", self:GetName())
    self:UnsubscribeFromEvents()
    SlashCommands:Unregister()
end