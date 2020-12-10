local AddOnName, AddOn

describe("Core", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_UI')
        AddOnLoaded(AddOnName, true)
    end)
    teardown(function()
        After()
    end)

    describe("UI", function()
        it("updates more info", function()
            AddOn:ToggleModule("Standings")
            local standings = AddOn:StandingsModule()
            local frame = standings:GetFrame()
            AddOn.UpdateMoreInfoWithLootStats(standings:GetFrame(), nil, nil)
            assert(not frame.moreInfo:IsVisible())
            AddOn.UpdateMoreInfoWithLootStats(standings:GetFrame(), { { name = 'Player101-Realm1'} }, 1)
            assert(frame.moreInfo:IsVisible())
        end)
    end)

end)