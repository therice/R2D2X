local _, AddOn = ...
local L, Logging = AddOn.Locale, AddOn:GetLibrary("Logging")
local Event = AddOn.Require('Core.Event')

function AddOn:SubscribeToEvents()
    Logging:Debug("SubscribeToEvents(%s)", self:GetName())
    for event, method in pairs(self.Events) do
        Logging:Debug("SubscribeToEvents(%s) : %s", self:GetName(), event)
        Event:Subscribe(
                event,
                function(evt, ...) self[method](evt, ...) end
        )
    end
end

-- this event is triggered when the player logs in, /reloads the UI, or zones between map instances
-- basically whenever the loading screen appears
function AddOn:PlayerEnteringWorld(_, ...)
    Logging:Debug("PlayerEnteringWorld(%s)", AddOn.player:GetName())
end

--  PartyLootMethodChanged, PartyLeaderChanged, GroupLeft
function AddOn:PartyEvent(event, ...)
    Logging:Debug("PartyEvent(%s)", event)
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