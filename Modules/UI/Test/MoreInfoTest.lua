local AddOnName, AddOn, Util
--- @type UI.MoreInfo
local MI


describe("MoreInfo", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_MoreInfo')
		AddOnLoaded(AddOnName, true)
		Util = AddOn:GetLibrary('Util')
		MI = AddOn.Require('UI.MoreInfo')
	end)

	teardown(function()
		After()
	end)

	describe("operations", function()
		it("updates more info", function()
			AddOn:ToggleModule("Standings")
			local standings = AddOn:StandingsModule()
			local frame = standings:GetFrame()
			MI.UpdateMoreInfoWithLootStats(standings:GetFrame(), nil, nil)
			assert(not frame.moreInfo:IsVisible())
			MI.UpdateMoreInfoWithLootStats(standings:GetFrame(), { { name = 'Player101-Realm1'} }, 1)
			assert(frame.moreInfo:IsVisible())
		end)
	end)
end)