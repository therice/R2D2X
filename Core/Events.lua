local _, AddOn = ...
local L, Logging = AddOn.Locale, AddOn:GetLibrary("Logging")
local Event, Util = AddOn.Require('Core.Event'), AddOn:GetLibrary('Util')

function AddOn:SubscribeToEvents()
    Logging:Debug("SubscribeToEvents(%s)", self:GetName())
    for event, method in pairs(self.Events) do
        Logging:Trace("SubscribeToEvents(%s) : %s", self:GetName(), event)
        Event:Subscribe(
                event,
                function(evt, ...) self[method](self, evt, ...) end
        )
    end
end

-- track whether initial login rather than reload or zone change
local handledEnteringWorld = false

-- this event is triggered when the player logs in, /reloads the UI, or zones between map instances
-- basically whenever the loading screen appears
function AddOn:PlayerEnteringWorld(_, ...)
    Logging:Debug("PlayerEnteringWorld(%s)", AddOn.player:GetName())
    self:NewMasterLooterCheck()
    -- if we have not yet handled the initial entering world event
    if not handledEnteringWorld then
        if not handledEnteringWorld and not self:IsMasterLooter() and Util.Objects.IsSet(self.masterLooter) then
            Logging:Debug("Player '%s' entering world", tostring(self.player))
        end
        handledEnteringWorld = true
    end
end

--  PartyLootMethodChanged, PartyLeaderChanged, GroupLeft
function AddOn:PartyEvent(event, ...)
    Logging:Debug("PartyEvent(%s)", event)
    self:NewMasterLooterCheck()
end

function AddOn:LootClosed(_, ...)
    Logging:Debug("LootClosed()")
end

function AddOn:LootOpened(_, ...)
    Logging:Debug("LootOpened()")
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