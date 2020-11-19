local _, AddOn = ...
local L, Util, Dialog, UIUtil =
    AddOn.Locale, AddOn:GetLibrary("Util"), AddOn:GetLibrary("Dialog"), AddOn.Require('UI.Util')


Dialog:Register(AddOn.Constants.Popups.ConfirmAdjustPoints, {
    text = "text is missing, machu picchu!",
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
