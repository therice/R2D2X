local gearPoints, Util, ItemUtil

describe("LibGearPoints", function()
    setup(function()
        loadfile("Test/TestSetup.lua")(false, 'LibGearPoints')
        loadfile("Libs/LibGearPoints-1.2/Test/BaseTest.lua")()
        LoadDependencies()
        loadfile("Libs/LibGearPoints-1.2/Test/LibGearPointsTestData.lua")()
        ConfigureLogging()
        Util = LibStub('LibUtil-1.1')
        ItemUtil = LibStub('LibItemUtil-1.1')
        gearPoints = LibStub('LibGearPoints-1.2')
        gearPoints:SetToStringFn( LibStub('LibUtil-1.1').Objects.ToString)
    end)
    teardown(function()
        After()
    end)
    describe("quality threshold", function()
        it("has default value", function()
            assert.equal(4, gearPoints:GetQualityThreshold())
        end)
        it("can be set to a valid value", function()
            gearPoints:SetQualityThreshold(5)
            assert.equal(5, gearPoints:GetQualityThreshold())
        end)
        it("cannot be set to an invalid value", function()
            assert.has_error(function() gearPoints:SetQualityThreshold(55) end)
            assert.has_error(function() gearPoints:SetQualityThreshold(nil) end)
        end)
    end)
    describe("formula inputs", function()
        it("has default values", function()
            local base, coefficientBase, multiplier = gearPoints:GetFormulaInputs()
            assert.equal(4.8, base)
            assert.equal(2.5, coefficientBase)
            assert.equal(1, multiplier)
        end)
        it("can be set", function()
            gearPoints:SetFormulaInputs(5.3, 2.1)
            local base, coefficientBase, multiplier = gearPoints:GetFormulaInputs()
            assert.equal(5.3, base)
            assert.equal(2.1, coefficientBase)
            assert.equal(1, multiplier)
            gearPoints:SetFormulaInputs(nil, nil, 2)
            base, coefficientBase, multiplier = gearPoints:GetFormulaInputs()
            assert.equal(5.3, base)
            assert.equal(2.1, coefficientBase)
            assert.equal(2, multiplier)
        end)
    end)
    describe("scaling factor", function()
        it("configuration is empty upon loading", function()
            assert.equal(0, GetSize(gearPoints:GetScalingConfig()))
        end)
        it("invalid configuration is ignored", function()
            gearPoints:SetScalingConfig({
                head = true,
                neck_scale = function() end,
                wrist_bogus_1 = true
            })
            assert.equal(0, GetSize(gearPoints:GetScalingConfig()))
        end)
        it("configuration can be supplied (via table)", function()
            gearPoints:SetScalingConfig(TestScalingConfig)
            assert.equal(5, GetSize(gearPoints:GetScalingConfig()))
        end)
        it("configuration can be supplied (via AceDB)", function()
            local db = NewAceDb():RegisterNamespace("GearPoints", DbScalingDefaults)
            gearPoints:SetScalingConfig(db.profile)
            local scale, comment = gearPoints:GetScale("INVTYPE_WEAPON")
            assert.equal(1.5, scale)
            assert.equal('One-Hand Weapon', comment)
        end)
        it("key can be determined from equipment location", function()
            assert.equal(string.lower("weaponMainH"), gearPoints:GetScaleKey("INVTYPE_WEAPONMAINHAND"))
            assert.equal("ranged", gearPoints:GetScaleKey("INVTYPE_RANGED"))
            assert.equal("ranged", gearPoints:GetScaleKey(nil, "Bows"))
            assert.equal("wand", gearPoints:GetScaleKey(nil, "Wands"))
        end)
        it("can be determined from equipment location", function()
            gearPoints:SetScalingConfig(TestScalingConfig)
            local scale, comment = gearPoints:GetScale("INVTYPE_WEAPON")
            assert.equal(1.5, scale)
            assert.equal('One-Hand Weapon', comment)
            scale, comment = gearPoints:GetScale("INVTYPE_SHIELD")
            assert.equal(0.5, scale)
            assert.equal(nil, comment)
        end)
    end)
    describe("gp calculation", function()
        it("can be made from scale", function()
            gearPoints:ResetFormulaInputs()
            local base, coefficientBase, multiplier = gearPoints:GetFormulaInputs()
            assert.equal(4.8, base)
            assert.equal(2.5, coefficientBase)
            assert.equal(1, multiplier)
            assert.equal(56, gearPoints:CalculateFromScale(1, 70, 4))
            assert.equal(75, gearPoints:CalculateFromScale(1, 78, 4))
        end)
        it("can be made from item id", function()
            gearPoints:ResetFormulaInputs()
            gearPoints:SetQualityThreshold(4)
            gearPoints:SetScalingConfig(TestScalingConfig)
            local gp, comment = gearPoints:GetValue(18832)
            assert.equal(84,gp)
            assert.equal(comment, "One-Hand Weapon")
            gearPoints:ResetScalingConfig()
        end)
        it("can be made from custom items", function()
            gearPoints:ResetFormulaInputs()
            gearPoints:SetQualityThreshold(4)
            gearPoints:SetScalingConfig(TestScalingConfig)
            ItemUtil:SetCustomItems(TestCustomItems)
            local gp, comment = gearPoints:GetValue(21232)
            assert(116 == gp)
            assert.equal(comment, "One-Hand Weapon")
            gp, comment = gearPoints:GetValue(18646)
            assert(44 == gp)
            assert.equal(comment, "Custom GP")
            gp, comment = gearPoints:GetValue(17069)
            assert(40 == gp)
            assert.equal(comment, "Custom Scale")
            gearPoints:ResetScalingConfig()
            ItemUtil:ResetCustomItems()
        end)
    end)
end)