local _, AddOn = ...
local Logging = AddOn:GetLibrary('Logging')
local Util = AddOn:GetLibrary('Util')
local pkg = AddOn.Package('UI')
local Private = pkg:Class('Utils')

function Private:initialize()
    self.tooltip = nil
end

function Private:GetTooltip(creator)
    if not self.tooltip and creator then
        self.tooltip = creator()
    end
    return self.tooltip
end

local Util = AddOn.Instance(
        'UI.Util',
        function()
            return {
                private = Private()
            }
        end
)

function Util:CreateHypertip(link)
    if Util.Strings.IsEmpty(link) then return end
    -- this is to support shift click comparison on all tooltips
    local function tip()
        local tip = CreateFrame("GameTooltip", AddOn:Qualify("TooltipEventHandler"), UIParent, "GameTooltipTemplate")
        tip:RegisterEvent("MODIFIER_STATE_CHANGED")
        tip:SetScript("OnEvent",
                function(_, event, arg)
                    local tooltip = self.private.tooltip
                    if tooltip.showing and event == "MODIFIER_STATE_CHANGED" and (arg == "LSHIFT" or arg == "RSHIFT") and tooltip.link then
                        self:CreateHypertip(tooltip.link)
                    end
                end
        )
        return tip
    end

    local tooltip = self.private:GetTooltip(tip)
    tooltip.showing = true
    tooltip.link = link
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(link)
end


function Util:HideTooltip()
    local tooltip = self.private:GetTooltip()
    if tooltip then
        tooltip.showing = false
    end
    GameTooltip:Hide()
end
