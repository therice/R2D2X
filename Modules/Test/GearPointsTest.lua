local AddOnName, AddOn, Util, GameTooltip


describe("GearPoints", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_GearPoints')
        Util = AddOn:GetLibrary('Util')
        GameTooltip = CreateFrame("GameTooltip", "GearPointsTestItemTooltip", UIParent, "GameTooltipTemplate")
        GameTooltip.HasScript = function(self, script)
            if script == "OnTooltipSetItem" then return true end
            return false
        end
        GameTooltip.OnTooltipSetItem = function(...)
            print('OnTooltipSetItem')
            print(Util.Objects.ToString({...}))
        end

        AddOnLoaded(AddOnName, true)
    end)

    teardown(function()
        After()
        GameTooltip = nil
    end)

    describe("lifecycle", function()
        it("is disabled on startup", function()
            local module = AddOn:GearPointsModule()
            assert(module)
            assert(module:IsEnabled())
        end)
        it("can be disabled", function()
            AddOn:ToggleModule("GearPoints")
            local module = AddOn:GearPointsModule()
            assert(module)
            assert(not module:IsEnabled())
        end)
        it("can be enabled", function()
            AddOn:ToggleModule("GearPoints")
            local module = AddOn:GearPointsModule()
            assert(module)
            assert(module:IsEnabled())
        end)
    end)


    describe("configuration", function()
        it("is built", function()
            local module = AddOn:GearPointsModule()
            assert(module:BuildConfigOptions())
        end)
    end)

    describe("item tooltip hook", function()
        local tt = {
            lines = {}
        }
        tt.GetItem = function() return nil, '|cff9d9d9d|Hitem:18832:2564:0:0:0:0:0:0:60:0:0:0:0|h[Brutality Blade]|h|r' end
        tt.AddLine = function(self, line)
            tinsert(self.lines, line)
        end

        GameTooltip:GetScript('OnTooltipSetItem')(tt)
        print(Util.Objects.ToString(lines))
        assert(#tt.lines == 2)
    end)
end)