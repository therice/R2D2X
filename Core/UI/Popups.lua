--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")
---@type UI.Util
local UIUtil = AddOn.Require('UI.Util')
local MachuPicchu = "text is missing, machu picchu!"

Dialog:Register(C.Popups.ConfirmUsage, {
    text = L["confirm_usage_text"],
    on_show = function(self) UIUtil.DecoratePopup(self) end,
    buttons = {
        {
            text = _G.YES,
            on_click = function() AddOn:StartHandleLoot() end,
        },
        {
            text = _G.NO,
            on_click = function() AddOn:Print(L["is_not_active_in_this_raid"]) end,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmAbort, {
    text = L["confirm_abort"],
    on_show = function(self) UIUtil.DecoratePopup(self) end,
    buttons = {
        {
            text = _G.YES,
            on_click = function()
                AddOn:MasterLooterModule():EndSession()
                CloseLoot()
                AddOn:LootAllocateModule():EndSession(true)
            end,
        },
        {
            text = _G.NO,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmAdjustPoints, {
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

Dialog:Register(AddOn.Constants.Popups.ConfirmAward, {
    text = MachuPicchu,
    icon = "",
    on_show = AddOn:MasterLooterModule().AwardOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = AddOn:MasterLooterModule().AwardOnClickYes
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})

Dialog:Register(C.Popups.ConfirmDecayPoints, {
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

Dialog:Register(C.Popups.ConfirmDeleteItem, {
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

Dialog:Register(AddOn.Constants.Popups.ConfirmReannounceItems, {
    text = MachuPicchu,
    on_show = function(self, data)
        UIUtil.DecoratePopup(self)
        if data.isRoll then
            self.text:SetText(format(L["confirm_rolls"], data.target))
        else
            self.text:SetText(format(L["confirm_unawarded"], data.target))
        end
    end,
    buttons = {
        {
            text = _G.YES,
            on_click = function(_, data)
                data.func()
            end,
        },
        {
            text = _G.NO,
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})


Dialog:Register(AddOn.Constants.Popups.ConfirmRevert, {
    text = MachuPicchu,
    on_show = AddOn:StandingsModule().RevertOnShow,
    buttons = {
        {
            text = _G.YES,
            on_click = AddOn:StandingsModule().RevertOnClickYes,
        },
        {
            text = _G.NO,
            on_click = Util.Functions.Noop
        },
    },
    hide_on_escape = true,
    show_while_dead = true,
})
