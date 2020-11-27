--- @type AddOn
local _, AddOn = ...
local L, Util, Dialog, UIUtil =
    AddOn.Locale, AddOn:GetLibrary("Util"), AddOn:GetLibrary("Dialog"), AddOn.Require('UI.Util')
local MachuPicchu = "text is missing, machu picchu!"

Dialog:Register(AddOn.Constants.Popups.ConfirmAdjustPoints, {
    text = MachuPicchu,
    on_show = AddOn:StandingsModule().AdjustOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = AddOn:StandingsModule().AdjustOnClickYes,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(AddOn.Constants.Popups.ConfirmDecayPoints, {
    text = MachuPicchu,
    on_show = AddOn:StandingsModule().DecayOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = AddOn:StandingsModule().DecayOnClickYes,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(AddOn.Constants.Popups.ConfirmDeleteItem, {
    text = MachuPicchu,
    on_show = AddOn:GearPointsCustomModule().DeleteItemOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = AddOn:GearPointsCustomModule().DeleteItemOnClickYes,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})