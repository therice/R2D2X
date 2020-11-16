local _, AddOn = ...
local L, Logging, Util = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary('Util')
local C, SlashCommands, Player =
    AddOn.Constants, AddOn.Require('Core.SlashCommands'), AddOn.ImportPackage('Models').Player

local function ModeToggle(self, flag)
    if self.mode:Enabled(flag) then self.mode:Disable(flag) else self.mode:Enable(flag) end
end

function AddOn:TestModeEnabled()
    return self.mode:Enabled(C.Modes.Test)
end

function AddOn:DevModeEnabled()
    return self.mode:Enabled(C.Modes.Develop)
end

function AddOn:PersistenceModeEnabled()
    return self.mode:Enabled(C.Modes.Persistence)
end

function AddOn:RegisterChatCommands()
    Logging:Debug("RegisterChatCommands(%s)", self:GetName())
    SlashCommands:BulkSubscribe(
            {
                {'config', 'c'},
                L['chat_commands_config'],
                function() AddOn.ToggleConfig() end,
            },
            {
                {'dev'},
                L['chat_commands_dev'],
                function()
                    ModeToggle(self, C.Modes.Develop)
                    self:Print("Development Mode = " .. tostring(self:DevModeEnabled()))
                end,
                true
            },
            {
                {'pm'},
                L['chat_commands_pm'],
                function()
                    ModeToggle(self, C.Modes.Persistence)
                    self:Print("Persistence Mode = " .. tostring(self:PersistenceModeEnabled()))
                end,
                true
            }
    )
end

function AddOn:IsMasterLooter()
    Logging:Debug("IsMasterLooter(%s) : %s, %s", self:GetName(), tostring(self.masterLooter), tostring(self.player))
    return self.masterLooter and self.player and Util.Objects.Equals(self.masterLooter, self.player)
end

function AddOn:GetMasterLooter()
    Logging:Debug("GetMasterLooter()")
    local lootMethod, mlPartyId, mlRaidId = GetLootMethod()
    self.lootMethod = lootMethod
    Logging:Trace("GetMasterLooter() : Loot Method is '%s'", self.lootMethod)

    -- always the player when testing alone
    if GetNumGroupMembers() == 0 and (self:TestModeEnabled() or self:DevModeEnabled()) then
        -- todo
        -- self:ScheduleTimer("Timer", 5, AddOn.Constants.Commands.MasterLooterDbCheck)
        return true, self.player
    end

    if Util.Strings.Equal(lootMethod, "master") then
        local name
        -- Someone in raid
        if mlRaidId then
            name = self:UnitName("raid" .. mlRaidId)
        -- Player in party
        elseif mlPartyId == 0 then
            name = self.player:GetName()
        -- Someone in party
        elseif mlPartyId then
            name = self:UnitName("party" .. mlPartyId)
        end

        Logging:Debug("GetMasterLooter() : ML is '%s'", tostring(name))
        return IsMasterLooter(), Player:Get(name)
    end

    Logging:Warn("GetMasterLooter() : Unsupported loot method '%s'", tostring(self.lootMethod))
    return false, nil
end

function AddOn:NewMasterLooterCheck()
    Logging:Debug("NewMasterLooterCheck()")

    local oldMl, oldLm = self.masterLooter and self.masterLooter:GetName() or nil, self.lootMethod
    _, self.masterLooter = self:GetMasterLooter()
    self.lootMethod = GetLootMethod()

    if Util.Objects.IsSet(self.masterLooter) and
            (
                Util.Strings.Equal(self.masterLooter:GetName(), "Unknown") or
                Util.Strings.Equal(Ambiguate(self.masterLooter:GetName(), "short"):lower(), _G.UNKNOWNOBJECT:lower())
            )
    then
        Logging:Warn("NewMasterLooterCheck() : Unknown Master Looter")
        return self:ScheduleTimer("NewMasterLooterCheck", 1)
    end

    if self:UnitIsUnit(oldMl, "player") and not self:IsMasterLooter() then
        self:StopHandleLoot()
    end

    if self:UnitIsUnit(oldMl, self.masterLooter:GetName()) and Util.Strings.Equal(oldLm, self.lootMethod) then
        Logging:Debug("NewMasterLooterCheck() : No Master Looter change")
        return
    end

    -- todo
    -- if self:MasterLooterModule():DbValue('usage.never') then return end

    if Util.Objects.IsEmpty(self.masterLooter) then return end

    -- request ML DB if not received within 15 seconds
    -- todo
    -- self:ScheduleTimer("Timer", 15,  AddOn.Constants.Commands.MasterLooterDbCheck)

    -- Someone else has become ML
    if not self:IsMasterLooter() and Util.Strings.IsSet(self.masterLooter:GetName()) then return end

    -- if not IsInRaid() and self.db.profile.onlyUseInRaids then return end
    -- todo
    -- if not IsInRaid() and self:MasterLooterModule():DbValue('onlyUseInRaids') then return end

    -- already handling loot, just bail
    if self.handleLoot then return end

    local _, type = IsInInstance()
    if Util.Objects.In(type, 'arena', 'pvp') then return end

    Logging:Debug("NewMasterLooterCheck() : isMasterLooter=%s", tostring(self:IsMasterLooter()))

    -- todo
    --[[
    -- we are ml and shouldn't as for usage
    --  self.db.profile.usage.ml
    if self.isMasterLooter and self:MasterLooterModule():DbValue('usage.ml') then
        self:StartHandleLoot()
        -- ask if using master looter
        -- self.db.profile.usage.ask_ml
    elseif self.isMasterLooter and self:MasterLooterModule():DbValue('usage.ask_ml') then
        return Dialog:Spawn(AddOn.Constants.Popups.ConfirmUsage)
    end
    --]]
end


function AddOn:StopHandleLoot()
    Logging:Debug("StopHandleLoot()")
end