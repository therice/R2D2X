local AddOnName, AddOn, Util


describe("GearPoints", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_GearPoints')
        Util = AddOn:GetLibrary('Util')
        AddOnLoaded(AddOnName, true)
    end)

    teardown(function()
        After()
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
            print(Util.Objects.ToString(module:BuildConfigOptions(), 6))
        end)
    end)
end)