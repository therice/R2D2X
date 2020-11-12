local _, AddOn = ...
local Logging, Util = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util')
local Pkg = AddOn.Package('UI')
local Private = Pkg:Class('Utils')

function Private:initialize()
    self.tooltip = nil
end

function Private:GetTooltip(creator)
    if not self.tooltip and creator then
        self.tooltip = creator()
    end
    return self.tooltip
end

local U = AddOn.Instance(
        'UI.Util',
        function()
            return {
                private = Private()
            }
        end
)

local Decorator = Pkg:Class('Decorator')
function Decorator:initialize() end
function Decorator:decorate(...) return Util.Strings.Join('', ...) end

local ColoredDecorator = Pkg:Class('ColoredDecorator', Decorator)
function ColoredDecorator:initialize(r, g, b)
    Decorator.initialize(self)
    if Util.Objects.IsTable(r) then
        if r.GetRGB then
            self.r, self.g, self.b = r:GetRGB()
        else
            self.r, self.g, self.b = unpack(r)
        end
    else
        self.r, self.g, self.b = r, g, b
    end
end

function ColoredDecorator:decorate(...)
    return U.RGBToHexPrefix(self.r, self.b, self.g) .. ColoredDecorator.super:decorate(...) .. "|r"
end

function U:CreateHypertip(link)
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

function U:HideTooltip()
    local tooltip = self.private:GetTooltip()
    if tooltip then tooltip.showing = false end
    GameTooltip:Hide()
end

function U.RGBToHex(r,g,b)
    return string.format("%02x%02x%02x", math.floor(255*r), math.floor(255*g), math.floor(255*b))
end

function U.RGBToHexPrefix(r, g, b)
    return "|cff" .. U.RGBToHex(r, g, b)
end

function U.ColoredDecorator(...)
    return ColoredDecorator(...)
end