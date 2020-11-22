local _, AddOn = ...
local L, C, Logging, Util =
    AddOn.Locale, AddOn.Constants, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
local AceUI, UIUtil, LibGP =
    AddOn.Require('UI.Ace'), AddOn.Require('UI.Util'), AddOn:GetLibrary("GearPoints")
local GP = AddOn:NewModule('GearPoints', "AceBucket-3.0")

GP.Defaults = {
    profile = {
        enabled = true,
        -- this is the minimum value for GP
        gp_min = 1,
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


function GP:OnInitialize()
    Logging:Debug("OnInitialize(%s)", self:GetName())
    LibGP:SetToStringFn(Util.Objects.ToString)
    self.db = AddOn.db:RegisterNamespace(self:GetName(), GP.Defaults)
end

function GP:OnEnable()
    Logging:Debug("OnEnable(%s)", self:GetName())
    self:ConfigureLibGP()
end

function GP:OnDisable()
    Logging:Debug("OnDisable(%s)", self:GetName())
    self:UnregisterAllBuckets()
end

function GP:ConfigureLibGP()
    LibGP:SetScalingConfig(self.db.profile.slot_scaling)
    LibGP:SetFormulaInputs(
            self.db.profile.formula.gp_base,
            self.db.profile.formula.gp_coefficient_base,
            self.db.profile.formula.gp_multiplier
    )
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
                    :description("help", L["gp_help"]):order(1)
                    :header("headerEquation", L["equation"]):order(2)
                    :group("equation", ""):order(3):set("inline", true)
                        :args()
                            :description("help", "|cff00ff96GP|r = |cff8787edbase|r * (|cff3fc6eacoefficient|r ^ ((item_level / 26) + (item_rarity - 4)) * |cfffff468equipment_slot_multiplier|r) * |cfff48cbamultiplier|r")
                                :order(1):fontSize("large")
                            :range("formula.gp_base", "|cff8787edbase|r", 1, 1000):order(2)
                            :range("formula.gp_coefficient_base", "|cff3fc6eacoefficient|r", 1, 100):order(3)
                            :range("formula.gp_multiplier", "|cfff48cbamultiplier|r", 1, 100):order(4)
                        :close()
                    :header("awardHeader" , L["awards"]):order(3)
                    :group("awards", ""):order(4):set("inline", true)
                        :args()
                            :description("help", L["award_scaling_help"]):order(1):fontSize("medium")
                        :close()
                    :header("slotsHeader", L["equipment_slots"]):order(5)
                    :description("Description", L["equipment_slots_help"]):order(6):fontSize("medium")

    -- set path to awards group arguments
    builder:SetPath(GP:GetName() .. '.args.awards.args')
    local awardScalingDefaults, order = GP.Defaults.profile.award_scaling, 2
    for award, _ in pairs(awardScalingDefaults) do
        builder
            :range('award_scaling.' .. award .. '.scale', UIUtil.ColoredDecorator(awardScalingDefaults[award].color):decorate(L[award]), 0, 1, 0.01):order(order)
            :desc(format(L["award_scaling_for_reason"], L[award]))
            :set('isPercent', true)
            :set('width', 'double')
        order = order + 1
    end

    builder:SetPath(GP:GetName() .. '.args')
    local slotScalingKeys = Util(Util.Tables.Keys(GP.Defaults.profile.slot_scaling)):Sort(function(a,b) return a < b end)()
    order = 7
    for _, slot in pairs(slotScalingKeys) do
        local slotDisplayKey = Util.Strings.UcFirst(slot)
        local displayName = C.ItemEquipmentLocationNames[slotDisplayKey] or OffSuitSlotMappings[slotDisplayKey] or "???"
        local description = OffSuitSlotMappings[slotDisplayKey] or displayName
        -- Logging:Debug("%s, %s, %s", slotDisplayKey, displayName, description)
        builder
            :group(slot, displayName):desc(L["item_slot_with_name"]:format(description)):order(order)
                :args()
                    :description('help', displayName):order(1)
                    :range('slot_scaling.' .. slot, L["slot_multiplier"], 0, 5):desc(L['slot_multiplier_desc']):order(2):set('width', 'double')
            :close()

        order = order + 1
    end


    return builder:build()
end)

function GP:BuildConfigOptions()
    local options = Options()
    return options[self:GetName()], true
end
