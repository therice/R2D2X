local _, AddOn = ...
local C, Logging, Util = AddOn.Constants, AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util')
local Award = AddOn.Package('Models').Award
local UI, UIUtil = AddOn.Package('UI'), AddOn.Package('UI.Util')

-- generic build entry attributes
local Attributes = UIUtil:Class('Attributes')
function Attributes:initialize(attrs) self.attrs = attrs end
function Attributes:set(attr, value)
    self.attrs[attr] = value
    return self
end

-- generic builder which handles entries of attributes
local Builder =  UIUtil:Class('Builder')
function Builder:initialize(entries)
    self.entries = entries
    self.pending = nil
    self.embeds = {
        'build'
    }
end

local function _Embed(builder, entry)
    for _, method in pairs(builder.embeds) do
        entry[method] = function(_, ...)
            return builder[method](builder, ...)
        end
    end
    return entry
end

function Builder:_CheckPending()
    if self.pending then
        self:_InsertPending()
        self.pending = nil
    end
end

function Builder:_InsertPending()
    tinsert(self.entries, self.pending.attrs)
end

function Builder:entry(class, ...)
    self:_CheckPending()
    self.pending = _Embed(self, class(...))
    return self.pending
end

function Builder:build()
    self:_CheckPending()
    return self.entries
end


local Private = UI:Class('Utils')
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

local Decorator = UI:Class('Decorator')
function Decorator:initialize() end
function Decorator:decorate(...) return Util.Strings.Join('', ...) end

local ColoredDecorator = UI:Class('ColoredDecorator', Decorator)
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

function U.RightClickMenu(predicate, entries, callback)
    return function(menu, level)
        if not predicate() then return end
        if not menu or not level then return end

        local info = MSA_DropDownMenu_CreateInfo()
        local candidateName = menu.name
        local el = menu.entry
        local value = _G.MSA_DROPDOWNMENU_MENU_VALUE

        for _, entry in ipairs(entries[level]) do
            info = MSA_DropDownMenu_CreateInfo()
            if not entry.special then
                if not entry.onValue or entry.onValue == value or (Util.Objects.IsFunction(entry.onValue) and entry.onValue(candidateName, el)) then
                    if (entry.hidden and Util.Objects.IsFunction(entry.hidden) and not entry.hidden(candidateName, el)) or not entry.hidden then
                        for name, val in pairs(entry) do
                            if name == "func" then
                                info[name] = function() return val(candidateName, el) end
                            elseif Util.Objects.IsFunction(val) then
                                info[name] = val(candidateName, el)
                            else
                                info[name] = val
                            end
                        end
                        MSA_DropDownMenu_AddButton(info, level)
                    end
                end
            else
                if callback then callback(info, menu, level, entry, value) end
            end
        end
    end
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

function U.CreateTooltip(...)
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    for i = 1, select("#", ...) do
        GameTooltip:AddLine(select(i, ...),1,1,1)
    end
    GameTooltip:Show()
end

function U:HideTooltip()
    local tooltip = self.private:GetTooltip()
    if tooltip then tooltip.showing = false end
    GameTooltip:Hide()
end

function U.GetClassColorRGB(class)
    local c = U.GetClassColor(class)
    return U.RGBToHex(c.r,c.g,c.b)
end

function U.GetClassColor(class)
    local color = RAID_CLASS_COLORS[class:upper()]
    -- if class not found, return epic color.
    if not color then return {r=1,g=1,b=1,a=1} end
    color.a = 1.0
    return color
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

local Colors = {
    ResourceTypes = {
        [Award.ResourceType.Ep] = C.Colors.ItemArtifact,
        [Award.ResourceType.Gp] = C.Colors.ItemLegendary,
    },
    SubjectTypes = {
        [Award.SubjectType.Character] = C.Colors.ItemCommon,
        [Award.SubjectType.Guild]     = C.Colors.ItemUncommon,
        [Award.SubjectType.Raid]      = C.Colors.ItemLegendary,
        [Award.SubjectType.Standby]   = C.Colors.ItemRare,
    }
}

function U.GetSubjectTypeColor(subjectType)
    if Util.Objects.IsString(subjectType) then subjectType = Award.SubjectType[subjectType] end
    return Colors.SubjectTypes[subjectType]
end
function U.GetResourceTypeColor(resourceType)
    if Util.Objects.IsString(resourceType) then resourceType = Award.ResourceType[resourceType] end
    return Colors.ResourceTypes[resourceType]
end