--- @type  AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.Event
local Event = AddOn.Require('Core.Event')

function AddOn:SubscribeToEvents()
    Logging:Debug("SubscribeToEvents(%s)", self:GetName())
    local events = {}
    for event, method in pairs(self.Events) do
        Logging:Trace("SubscribeToEvents(%s) : %s", self:GetName(), event)
        events[event] = function(evt, ...) self[method](self, evt, ...) end
    end
    self.eventSubscriptions = Event:BulkSubscribe(events)
end


function AddOn:UnsubscribeFromEvents()
    Logging:Debug("UnsubscribeFromEvents(%s)", self:GetName())
    if self.eventSubscriptions then
        for _, subscription in pairs(self.eventSubscriptions) do
            subscription:unsubscribe()
        end
        self.eventSubscriptions = nil
    end
end

-- track whether initial load of addon or has it been reloaded (either via login or explicit reload)
local initialLoad = true
-- this event is triggered when the player logs in, /reloads the UI, or zones between map instances
-- basically whenever the loading screen appears
--
-- initial login = true, false
-- reload ui = false, true
-- instance zone event = false, false
function AddOn:PlayerEnteringWorld(_, isLogin, isReload)
    Logging:Debug("PlayerEnteringWorld(%s) : isLogin=%s, isReload=%s, initialLoad=%s",
                  AddOn.player:GetName(), tostring(isLogin), tostring(isReload), tostring(initialLoad)
    )
    self:NewMasterLooterCheck()
    -- if we have not yet handled the initial entering world event
    if initialLoad then
        if not self:IsMasterLooter() and Util.Objects.IsSet(self.masterLooter) then
            Logging:Debug("Player '%s' entering world (initial load)", tostring(self.player))
            self:ScheduleTimer("Send", 2, self.masterLooter, C.Commands.Reconnect)
            self:Send(C.group, C.Commands.PlayerInfo, self:GetPlayerInfo())
        end
        self:UpdatePlayerData()
        initialLoad = false
    end
end

--  PartyLootMethodChanged, PartyLeaderChanged, GroupLeft
function AddOn:PartyEvent(event, ...)
    Logging:Debug("PartyEvent(%s)", event)
    self:NewMasterLooterCheck()
    -- todo : standby roster reset
end


function AddOn:LootOpened(_, ...)
    Logging:Debug("LootOpened()")
end

function AddOn:LootClosed(_, ...)
    Logging:Debug("LootClosed()")
end

function AddOn:LootReady(_, ...)
    Logging:Debug("LootReady()")
end

function AddOn:LootSlotCleared(_, ...)
    Logging:Debug("LootSlotCleared()")
end

function AddOn:EncounterEnd(_, ...)
    Logging:Debug("EncounterEnd()")
end

function AddOn:EncounterStart(_, ...)
    Logging:Debug("EncounterStart()")
end

function AddOn:RaidInstanceEnter(_, ...)
    Logging:Debug("RaidInstanceEnter()")
end

function AddOn:EnterCombat(_, ...)

end

function AddOn:LeaveCombat(_, ...)

end