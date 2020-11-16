local _, AddOn = ...
local E = AddOn.Constants.Events

AddOn.Events = {
    [E.GroupLeft]                   = "PartyEvent",
    [E.PlayerEnteringWorld]         = "PlayerEnteringWorld",
    [E.PartyLeaderChanged]          = "PartyEvent",
    [E.PartyLootMethodChanged]      = "PartyEvent",
    [E.LootClosed]                  = "LootClosed",
    [E.LootOpened]                  = "LootOpened",
    [E.LootReady]                   = "LootReady",
    [E.LootSlotCleared]             = "LootSlotCleared",
}