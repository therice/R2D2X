--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil =  AddOn:GetLibrary("ItemUtil")
--- @type LibGearPoints
local LibGP = AddOn:GetLibrary("GearPoints")
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @class GearPoints
local GP = AddOn:NewModule('GearPoints', "AceBucket-3.0", "AceHook-3.0")

GP.defaults = {
    profile = {
        enabled = true,
        -- this is the minimum value for GP
        gp_min = 1,
        -- the threshold for item quality for having an associated GP
        -- also used for tooltips
        threshold = 4, -- epic
        -- these are the inputs for GP formula
        formula = {
            gp_base             = 4.8,
            gp_coefficient_base = 2.5,
            gp_multiplier       = 1,
        },
        -- GP scaling by slot
        slot_scaling = {
            head            = 1,
            neck            = 0.5,
            shoulder        = 0.75,
            chest           = 1,
            waist           = 0.75,
            legs            = 1,
            feet            = 0.75,
            wrist           = 0.5,
            hand            = 0.75,
            finger          = 0.5,
            trinket         = 0.75,
            cloak           = 0.5,
            shield          = 0.5,
            weapon          = 1.5,
            weapon2h        = 2,
            weaponmainh     = 1.5,
            weaponoffh      = 0.5,
            holdable        = 0.5,
            -- Bows, Crossbows, Guns (could split them up if merited, but they all seem equal)
            ranged          = 1.5,
            wand            = 0.5,
            thrown          = 0.5,
            relic           = 0.667,
        },
        -- scale is the percentage of GP to give to character for that type of award
        -- user_visible determines if the award type is presented as option to user for loot response
        -- color determines how the response is displayed in game if available to user
        --
        -- each entry here that is user visible will be presented to player as a response option
        -- when loot is available for award
        award_scaling = {
            ms_need  = {
                scale = 1,
                user_visible = true,
                color = C.Colors.Evergreen,
            },
            minor_upgrade = {
                scale = 0.75,
                user_visible = true,
                color = C.Colors.PaladinPink,
            },
            os_greed = {
                scale = 0.5,
                user_visible = true,
                color = C.Colors.RogueYellow,
            },
            pvp = {
                scale = 0.25,
                user_visible = true,
                color = C.Colors.DeathKnightRed,
            },
            disenchant = {
                scale = 0,
                user_visible = false,
                color = C.Colors.MageBlue,
            },
            bank = {
                scale = 0,
                user_visible = false,
                color = C.Colors.Purple,
            },
            free = {
                scale = 0,
                user_visible = false,
                color = C.Colors.Blue,
            }
        }
    }
}

GP.DefaultAwardColor = GP.defaults.profile.award_scaling.ms_need.color

function GP:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())
    LibGP:SetToStringFn(Util.Objects.ToString)
    self.db = AddOn.db:RegisterNamespace(self:GetName(), GP.defaults)
end

function GP:OnEnable()
    Logging:Debug("OnEnable(%s)", self:GetName())
    self:ConfigureLibGP()
    self:HookItemToolTip()
    self:RegisterBucketMessage(C.Messages.ConfigTableChanged, 5, "ConfigTableChanged")
end

function GP:OnDisable()
    Logging:Debug("OnDisable(%s)", self:GetName())
    self:UnregisterAllBuckets()
end

function GP:ConfigureLibGP()
    Logging:Debug("ConfigureLibGP(%s)", self:GetName())
    LibGP:SetQualityThreshold(self.db.profile.threshold)
    LibGP:SetScalingConfig(self.db.profile.slot_scaling)
    LibGP:SetFormulaInputs(
            self.db.profile.formula.gp_base,
            self.db.profile.formula.gp_coefficient_base,
            self.db.profile.formula.gp_multiplier
    )
end

--- @param award Models.Item.ItemAward
function GP:OnAwardItem(award)
    if not award then error('no item award provided') end
    Logging:Debug("OnAwardItem : %s", Util.Objects.ToString(award:toTable(), 3))

end

function GP:GetAwardSettings(award)
    Logging:Trace("GetAwardSettings(%s)", tostring(award))

    if Util.Objects.IsEmpty(award) then return nil end

    local settings =
        AddOn:HaveMasterLooterDb() and
        AddOn:MasterLooterDbValue('award_scaling', award) or
        self:GetDbValue('award_scaling', award)

    if not settings then
        Logging:Warn("GetAwardSettings(%s) : could not locate settings", tostring(award))
    end

    return settings
end

function GP:GetAwardColor(award)
    local settings = self:GetAwardSettings(award)
    -- Logging:Debug("GetAwardColor(%s) : %s", tostring(award), Util.Objects.ToString(settings))
    return settings and settings.color or GP.DefaultAwardColor
end

function GP:GetAwardScale(award)
    local settings = self:GetAwardSettings(award)
    return settings and tonumber(settings.scale) or 1
end

--- @param item Models.Item.Item
--- @param awardReason string the award reason key for award_scaling table (can be nil)
function GP:GetGpTextColored(item, awardReason)
    -- Logging:Debug("GetGpTextColored(%s, %s)", tostring(item.link), Util.Objects.ToString(awardReason))
    local baseGp, awardGp = item:GetGp(awardReason)
    local text = UIUtil.ColoredDecorator(GP.DefaultAwardColor):decorate(tostring(baseGp))
    if awardGp then
        awardGp = UIUtil.AwardReasonDecorator(awardReason):decorate(tostring(awardGp))
        text = awardGp .. "(" .. text .. ")"
    end
    return text
end

local function OnTooltipSetItemAddGp(tooltip, ...)
    local success, err = pcall(
        function()
            local _, itemlink = tooltip:GetItem()
            local color = ItemUtil:ItemLinkToColor(itemlink)
            local gp, _, ilvl = LibGP:GetValue(itemlink)
            if ilvl then
                tooltip:AddLine(L["gp_tooltip_ilvl"]:format(C.name_c, color .. tostring(ilvl) .. '|r'))
            end

            -- nil or 0 gp
            if not Util.Objects.IsNumber(gp) or gp == 0 then return end

            tooltip:AddLine(L["gp_tooltip_gp"]:format(C.name_c, UIUtil.ColoredDecorator(C.Colors.ItemLegendary):decorate(tostring(gp))))
        end
    )

    if not success then Logging:Warn("OnTooltipSetItemAddGp() : failed to augment tooltip -> %s", tostring(err)) end
end

function GP:HookItemToolTip()
    local f = EnumerateFrames()
    while f do
        -- if a game tool tip and not the one from ItemUtils
        if f:IsObjectType("GameTooltip") and f ~= ItemUtil.tooltip then
            local name = f:GetName() or nil
            if f:HasScript("OnTooltipSetItem") then
                Logging:Trace("HookItemToolTip() : Hooking script into GameTooltip '%s'",  Util.Objects.ToString(name))
                self:HookScript(f, "OnTooltipSetItem", OnTooltipSetItemAddGp)
            end
        end
        f = EnumerateFrames(f)
    end
end

function GP:ConfigTableChanged(msg)
    Logging:Debug("ConfigTableChanged() : %s", Util.Objects.ToString(msg))
    for serializedMsg, _ in pairs(msg) do
        local success, module, _ = AddOn:Deserialize(serializedMsg)
        if success and self:GetName() == module then
            self:ConfigureLibGP()
            break
        end
    end
end

local OffSuitSlotMappings = {
    ['Ranged'] =
        Util.Strings.Join(', ',
            C.ItemEquipmentLocationNames.Bows,
            C.ItemEquipmentLocationNames.Crossbows,
            C.ItemEquipmentLocationNames.Guns
    ),
    ['Relic'] =
        Util.Strings.Join(', ',
                C.ItemEquipmentLocationNames.Libram,
                C.ItemEquipmentLocationNames.Idol,
                C.ItemEquipmentLocationNames.Totem
    ),
    ['Weapon'] = C.ItemEquipmentLocationNames.OneHandWeapon,
    ['Weapon2h'] = C.ItemEquipmentLocationNames.TwoHandWeapon,
    ['Weaponmainh'] = C.ItemEquipmentLocationNames.MainHandWeapon,
    ['Weaponoffh'] = C.ItemEquipmentLocationNames.OffHandWeapon,
}

local Options = Util.Memoize.Memoize(function ()
    -- base template upon which we'll be attaching additional options
    local builder = AceUI.ConfigBuilder()
    builder:group(GP:GetName(), L["gp"]):desc(L["gp_desc"])
        :args()
            :group("calculation", L["calculation"]):set('childGroups', 'tab'):order(2)
                :args()
                    :header("thresholdHeader", L["quality_threshold"]):order(1)
                    :group("threshold", ""):order(2):set("inline", true)
                        :args()
                            :description("help", L["quality_threshold_desc"]):order(1)
                            :header("spacer",""):order(2)
                            :select('threshold', L['quality_threshold']):desc(L['quality_desc']):order(3)
                                :set('values', Util.Tables.Copy(C.ItemQualityDescriptions))
                        :close()
                    :header("headerEquation", L["equation"]):order(3)
                    :group("equation", ""):order(4):set("inline", true)
                        :args()
                            :description("formula_help", L["gp_help"]):order(1)
                            :header("spacer",""):order(2)
                            :description("formula", "|cff00ff96GP|r = |cff8787edbase|r * (|cff3fc6eacoefficient|r ^ ((item_level / 26) + (item_rarity - 4)) * |cfffff468equipment_slot_multiplier|r) * |cfff48cbamultiplier|r")
                                :order(3):fontSize("large")
                            :range("formula.gp_base", "|cff8787edbase|r", 1, 1000):order(4)
                            :range("formula.gp_coefficient_base", "|cff3fc6eacoefficient|r", 1, 100):order(5)
                            :range("formula.gp_multiplier", "|cfff48cbamultiplier|r", 1, 100):order(6)
                        :close()
                :close()
            :group("awards", L["award_reasons"]):set('childGroups', 'tab'):order(1)
                :args()
                    :header("awardHeader", L["awards"]):order(1)
                    :description("help", L["award_scaling_help"]):order(2):fontSize("medium")
                    :header("spacer",""):order(3)
                :close()
            :group("slots", L["equipment_slots"]):set('childGroups', 'select'):order(3)
                :args()
                    :header("slotsHeader", L["equipment_slots"]):order(1)
                    :description("slotsDescription", L["equipment_slots_help"]):order(2):fontSize("medium")
                    :header("spacer",""):order(3)
                :close()

    -- set path to awards group arguments
    builder:SetPath(GP:GetName() .. '.args.awards.args')
    local awardScalingDefaults, order = GP.defaults.profile.award_scaling, 4
    for award, _ in pairs(awardScalingDefaults) do
        builder
            :range('award_scaling.' .. award .. '.scale', UIUtil.ColoredDecorator(awardScalingDefaults[award].color):decorate(L[award]), 0, 1, 0.01):order(order)
                :desc(format(L["award_scaling_for_reason"], L[award]))
                :set('isPercent', true):set('width', 1.5)
        order = order + 1
    end

    builder:SetPath(GP:GetName() .. '.args.slots.args')
    local slotScalingKeys = Util(Util.Tables.Keys(GP.defaults.profile.slot_scaling)):Sort(function(a,b) return a < b end)()
    order = 4
    for _, slot in pairs(slotScalingKeys) do
        local slotDisplayKey = Util.Strings.UcFirst(slot)
        local displayName = C.ItemEquipmentLocationNames[slotDisplayKey] or OffSuitSlotMappings[slotDisplayKey] or "???"
        local description = OffSuitSlotMappings[slotDisplayKey] or displayName
        -- Logging:Debug("%s, %s, %s", slotDisplayKey, displayName, description)
        builder
            :group(slot, displayName):desc(L["item_slot_with_name"]:format(description)):order(order)
                :args()
                    :description('help', description):order(1)
                    :range('slot_scaling.' .. slot, L["slot_multiplier"], 0, 5)
                        :desc(L['slot_multiplier_desc']):order(2):set('width', 'double')
                :close()

        order = order + 1
    end

    return builder:build()
end)

function GP:BuildConfigOptions()
    local options = Options()
    return options[self:GetName()], true
end
