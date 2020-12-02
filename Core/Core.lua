--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.SlashCommands
local SlashCommands = AddOn.Require('Core.SlashCommands')
--- @type Models.Player
local Player = AddOn.ImportPackage('Models').Player
--- @type Models.Item.LootTableEntry
local LootTableEntry = AddOn.Package('Models.Item').LootTableEntry
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
local Dialog = AddOn:GetLibrary("Dialog")

local function ModeToggle(self, flag)
    if self.mode:Enabled(flag) then self.mode:Disable(flag) else self.mode:Enable(flag) end
end

--- @return boolean
function AddOn:TestModeEnabled()
    return self.mode:Enabled(C.Modes.Test)
end

--- @return boolean
function AddOn:DevModeEnabled()
    return self.mode:Enabled(C.Modes.Develop)
end

--- @return boolean
function AddOn:PersistenceModeEnabled()
    return self.mode:Enabled(C.Modes.Persistence)
end

function AddOn:ModuleSettings(module)
    return AddOn.db.profile.modules[module]
end

function AddOn:CallModule(module)
    Logging:Trace("CallModule(%s)", module)
    if not self.enabled then return end
    self:EnableModule(module)
end

function AddOn:IsModuleEnabled(module)
    Logging:Trace("IsModuleEnabled(%s)", module)
    local m = self:GetModule(module)
    return m and m:IsEnabled()
end

function AddOn:YieldModule(module)
    Logging:Trace("YieldModule(%s)", module)
    self:DisableModule(module)
end

function AddOn:ToggleModule(module)
    Logging:Trace("ToggleModule(%s)", module)
    if self:IsModuleEnabled(module) then
        self:YieldModule(module)
    else
        self:CallModule(module)
    end
end

--- @return Logging
function AddOn:LoggingModule()
    return self:GetModule("Logging")
end

--- @return EffortPoints
function AddOn:EffortPointsModule()
    return self:GetModule("EffortPoints")
end

--- @return GearPoints
function AddOn:GearPointsModule()
    return self:GetModule("GearPoints")
end

--- @return GearPointsCustom
function AddOn:GearPointsCustomModule()
    return self:GetModule("GearPointsCustom")
end

--- @return Standings
function AddOn:StandingsModule()
    return self:GetModule("Standings")
end

--- @return LootSession
function AddOn:LootSessionModule()
    return self:GetModule("LootSession")
end

--- @return MasterLooter
function AddOn:MasterLooterModule()
    return self:GetModule("MasterLooter")
end

--- @return LootAllocate
function AddOn:LootAllocateModule()
    return self:GetModule("LootAllocate")
end

--- @return Loot
function AddOn:LootModule()
    return self:GetModule("Loot")
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
                {'clearpc', 'cpc'},
                L['clear_player_cache_desc'],
                function()
                    AddOn.Package('Models').Player.ClearCache()
                    self:Print("Player cache cleared")
                end,
            },
            {
                {'clearic', 'cic'},
                L['clear_item_cache_desc'],
                function()
                    AddOn.Package('Models.Item').Item.ClearCache()
                    self:Print("Item cache cleared")
                end,
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
            },
            {
                {'test', 't'},
                L['chat_commands_test'],
                function(count)
                    self:Test(tonumber(count) or 2)
                end
            }
    )
end

function AddOn:IsMasterLooter()
    Logging:Debug("IsMasterLooter(%s) : ml=%s, player=%s", self:GetName(), tostring(self.masterLooter), tostring(self.player))
    return self.masterLooter and self.player and Util.Objects.Equals(self.masterLooter, self.player)
end

function AddOn:GetMasterLooter()
    Logging:Debug("GetMasterLooter()")
    local lootMethod, mlPartyId, mlRaidId = GetLootMethod()
    self.lootMethod = lootMethod
    Logging:Trace(
        "GetMasterLooter() : lootMethod='%s', mlPartyId=%s, mlRaidId=%s",
        self.lootMethod, tostring(mlPartyId), tostring(mlRaidId)
    )

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

    local oldMl, oldLm = self.masterLooter, self.lootMethod
    _, self.masterLooter = self:GetMasterLooter()
    self.lootMethod = GetLootMethod()

    -- ML is set, but it's an unknown player
    if Util.Objects.IsSet(self.masterLooter) and
            (
                Util.Strings.Equal(self.masterLooter:GetName(), "Unknown") or
                Util.Strings.Equal(Ambiguate(self.masterLooter:GetName(), "short"):lower(), _G.UNKNOWNOBJECT:lower())
            )
    then
        Logging:Warn("NewMasterLooterCheck() : Unknown Master Looter")
        return self:ScheduleTimer("NewMasterLooterCheck", 1)
    end

    -- at this point we can check if we're the ML, it's not changing
    local isML = self:IsMasterLooter()
    -- old ML is us, but no longer ML
    if self:UnitIsUnit(oldMl, "player") and not isML then
        self:StopHandleLoot()
    end

    -- is current ML unset
    if Util.Objects.IsEmpty(self.masterLooter) then return end

    -- old ML is us, new ML is us (implied by check above) and loot method has not changed
    if self:UnitIsUnit(oldMl, self.masterLooter) and Util.Strings.Equal(oldLm, self.lootMethod) then
        Logging:Debug("NewMasterLooterCheck() : No Master Looter change")
        return
    end

    local ML = self:MasterLooterModule()
    -- settings say to never use
    if ML:GetDbValue('usage.never') then return end

    -- request ML DB if not received within 15 seconds
    self:ScheduleTimer(
        function()
            if Util.Objects.IsSet(self.masterLooter) then
                -- base check on an attribute that should be present
                if not self.mlDb.raid then
                    self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
                end
            end
        end,
        15
    )

    -- Someone else has become ML, nothing additional to do
    if not isML and Util.Objects.IsSet(self.masterLooter) then return end

    -- not in raid and setting is to only use in traids
    if not IsInRaid() and ML:GetDbValue('onlyUseInRaids') then return end

    -- already handling loot, just bail
    if self.handleLoot then return end

    local _, type = IsInInstance()
    -- don't use in arena an PVP
    if Util.Objects.In(type, 'arena', 'pvp') then return end

    Logging:Debug("NewMasterLooterCheck() : isMasterLooter=%s", tostring(self:IsMasterLooter()))

    -- we're the ML and settings say to use when ML
    if isML and ML:GetDbValue('usage.ml') then
        self:StartHandleLoot()
    -- we're the ML and settings say to ask
    elseif isML and ML:GetDbValue('usage.ask_ml') then
        return Dialog:Spawn(C.Popups.ConfirmUsage)
    end
end

function AddOn:StartHandleLoot()
    Logging:Debug("StartHandleLoot()")
    local lootMethod = GetLootMethod()
    if not Util.Strings.Equal(lootMethod, "master") and GetNumGroupMembers() > 0 then
        self:Print(L["changing_loot_method_to_ml"])
        SetLootMethod("master", self.Ambiguate(self.player:GetName()))
    end

    local ML, lootThreshold = self:MasterLooterModule(), GetLootThreshold()
    local autoAwardLowerThreshold = ML:GetDbValue('autoAwardLowerThreshold')
    if ML:GetDbValue('autoAward') and lootThreshold ~= 2 and lootThreshold > autoAwardLowerThreshold then
        self:Print(L["changing_loot_threshold_auto_awards"])
        SetLootThreshold(autoAwardLowerThreshold >= 2 and autoAwardLowerThreshold or 2)
    end

    self:Print(format(L["player_handles_looting"], self.player:GetName()))
    self.handleLoot = true
    -- these are sent, but not actually consumed by addon
    self:Send(C.group, C.Commands.HandleLootStart)
    self:CallModule("MasterLooter")
    self:MasterLooterModule():NewMasterLooter(self.masterLooter)
end

function AddOn:StopHandleLoot()
    Logging:Debug("StopHandleLoot()")
    self.handleLoot = false
    self:MasterLooterModule():Disable()
    -- these are sent, but not actually consumed by addon
    self:Send(C.group, C.Commands.HandleLootStop)
end

function AddOn:HaveMasterLooterDb()
    return self.mlDb and Util.Tables.Count(self.mlDb) ~= 0
end

function AddOn:MasterLooterDbValue(...)
    return Util.Tables.Get(self.mlDb, Util.Strings.Join('.', ...))
end

function AddOn:OnMasterLooterDbReceived(mlDb)
    Logging:Debug("OnMasterLooterDbReceived()")
    self.mlDb = mlDb
end

function AddOn:OnLootTableReceived(lt)
    Logging:Debug("OnLootTableReceived() : %s", Util.Objects.ToString(lt))

    if not self.enabled then
        for i = 1, #lt do
            self:SendResponse(self.masterLooter, i, C.Responses.Disabled)
        end
        Logging:Trace("Sent 'disabled' response for all loot table entries")
        return
    end

    -- lt will an array of session to LootTableEntry representations
    -- each representations will be generated via LootTableEntry:ForTransmit()
    -- ref = ItemRef:ForTransmit()
    -- E.G.
    -- {{ref = 15037:0:0:0:0:0:0::}, {ref = 25798:0:0:0:0:0:0::}}

    -- convert transmitted reference into an ItemRef
    local interim = Util.Tables.Map(
            Util.Tables.Copy(lt),
            function(e) return LootTableEntry.ItemRefFromTransmit(e) end
    )
    -- determine how many uncached items there are
    local uncached = Util.Tables.CountFn(
            interim,
            function(i)
                return not i:GetItem()
            end
    )

    if uncached > 0 then
        self:ScheduleTimer('OnLootTableReceived', 0, lt)
        return
    end

    -- index will be the session, entry will be an ItemRef
    -- no need for additional processing, as the ItemRef will pointed to a cached item
    --
    -- these references may be augmented with additional attributes as needed
    -- but nothing else, by default, except the item reference
    self.lootTable = interim

    -- received LootTable without having received MasterLooterDb, well...
    if not self:HaveMasterLooterDb() then
        Logging:Warn("OnLootTableReceived() : received LootTable without having received MasterLooterDb from %s", tostring(self.masterLooter))
        self:Send(self.masterLooter, C.Commands.MasterLooterDbRequest)
        self:ScheduleTimer('OnLootTableReceived', 5, lt)
        return
    end

    ---- we're the master looter, start allocation
    if self:IsMasterLooter() then
        AddOn:CallModule("LootAllocate")
        AddOn:LootAllocateModule():ReceiveLootTable(self.lootTable)
    end

    ---- for anyone that is currently part of group, but outside of instances
    ---- automatically respond to each item (if support is enabled)
    if self:MasterLooterDbValue('outOfRaid') and GetNumGroupMembers() >= 8 and not IsInInstance() then
        Logging:Debug("OnLootTableReceived() : raid member, but not in the instance. responding to each item to that affect.")
        Util.Tables.Call(
            self.lootTable,
            function(_ , session)
                self:SendResponse(self.masterLooter, session,  C.Responses.NotInRaid)
            end,
            true -- need the index for session id
        )
        return
    end

    self:DoAutoPass(self.lootTable)
    self:SendLootAck(self.lootTable)

    AddOn:CallModule("Loot")
    AddOn:LootModule():Start(self.lootTable)

    Logging:Debug("OnLootTableReceived() : %d", Util.Tables.Count(self.lootTable))
end

function AddOn:AutoPassCheck(class, equipLoc, typeId, subTypeId, classes)
    return not ItemUtil:ClassCanUse(class, classes, equipLoc, typeId, subTypeId)
end

function AddOn:DoAutoPass(lt, skip)
    skip = Util.Objects.Default(skip, 0)
    Logging:Debug("DoAutoPass(%d)", skip)
    for session, entry in ipairs(lt) do
        if session > skip then
            if not Util.Objects.Default(entry.noAutoPass, false) then
                --- @type Models.Item.Item
                local item = entry:GetItem()
                if not item:IsBoe() then
                    if self:AutoPassCheck(self.player.class, item.equipLoc, item.typeId, item.subTypeId, item.classes) then
                        Logging:Trace("DoAutoPass() : Auto-passing on %s", item.link)
                        self:Print(format(L["auto_passed_on_item"], item.link))
                        entry.autoPass = true
                    end
                else
                    Logging:Trace("DoAutoPass() : skipped auto-pass on %s as it's BOE", item.link)
                end
            end
        end
    end
end

function AddOn:SendLootAck(lt, skip)
    skip = Util.Objects.Default(skip, 0)
    Logging:Debug("SendLootAck(%d)", skip)
    local hasData, toSend = false, { gear1 = {}, gear2 = {}, diff = {}, response = {} }
    for session, entry in ipairs(lt) do
        if session > (skip or 0) then
            hasData = true
            --- @type Models.Item.Item
            local item = entry:GetItem()
            local g1, g2 = self:GetPlayersGear(item.link, item.equipLoc)
            local diff = self:GetItemLevelDifference(item.link, g1, g2)

            toSend.gear1[session] = g1 and AddOn.SanitizeItemString(g1) or nil
            toSend.gear2[session] = g2 and AddOn.SanitizeItemString(g2) or nil
            toSend.diff[session] = diff
            toSend.response[session] = Util.Objects.Default(entry.autoPass, false)
        end
    end

    if hasData then
        self:Send(self.masterLooter, C.Commands.LootAck, self.playerData.ilvl, toSend)
    end
end