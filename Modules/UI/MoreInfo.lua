--- @type AddOn
local _, AddOn = ...
local L, C, Logging, Util = AddOn.Locale, AddOn.Constants, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
local UI, UIUtil = AddOn.Require('UI.Native'), AddOn.Require('UI.Util')

--- @class UI.MoreInfo
local MI = AddOn.Instance(
        'UI.MoreInfo',
        function()
            return {

            }
        end
)

local function Enabled(module)
    local settings = AddOn:ModuleSettings(module)
    return settings and settings.moreInfo or false, settings
end

local function Toggle(module)
    local enabled, settings = Enabled(module)
    enabled = not enabled
    if settings then settings.moreInfo = enabled end
    return enabled
end

local function SetTextures(module, miButton)
    local miEnabled = Enabled(module)
    if miEnabled then
        miButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        miButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    else
        miButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        miButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    end
end

-- fn : function(enabled [is more info enabled], frame [frame on which widget was embedded])
function MI.EmbedWidgets(module, frame, fn)
    if not Util.Objects.IsFunction(fn) then error("no function provided for updating more info") end

    local miButton = UI:NewNamed('Button', frame.content, "MoreInfoButton")
    miButton:SetSize(25, 25)
    miButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -20)
    SetTextures(module, miButton)
    miButton:SetScript(
            "OnClick",
            function(button)
                Toggle(module)
                SetTextures(module, button)
                frame.moreInfo.Update()
            end
    )
    miButton:SetScript("OnEnter", function() UIUtil.CreateTooltip(L["click_more_info"]) end)
    miButton:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
    miButton:HideTextures()
    frame.moreInfoBtn = miButton

    local mi = UI:NewNamed('GameTooltip', frame, 'MoreInfo')
    mi.Update = function(...)
        -- no more information widget, cannot update
        if not frame.moreInfo then return end
        local enabled = Enabled(module)
        -- not enabled, just hide and return
        if not enabled then return frame.moreInfo:Hide() end
        fn(frame, ...)
    end

    frame:HookScript("OnHide", function() frame.moreInfo:Hide() end)
    frame.moreInfo = mi
end

function MI.Update(frame, ...)
    if frame and frame.moreInfo then
        frame.moreInfo.Update(...)
    end
end
