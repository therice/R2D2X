local AddOnName, AddOn, Util


describe("GearPointsCustom", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_GearPointsCustom')
		Util = AddOn:GetLibrary('Util')
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:GearPointsCustomModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("GearPointsCustom")
			local module = AddOn:GearPointsCustomModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("GearPointsCustom")
			local module = AddOn:GearPointsCustomModule()
			assert(module)
			assert(module:IsEnabled())
		end)
	end)

	describe("operations", function()
		local gpc

		before_each(function()
			if AddOn:IsModuleEnabled("GearPointsCustom") then
				AddOn:ToggleModule("GearPointsCustom")
			end
			AddOn:ToggleModule("GearPointsCustom")
			gpc = AddOn:GearPointsCustomModule()
			PlayerEnteredWorld()
			GuildRosterUpdate()
		end)

		teardown(function()
			AddOn:ToggleModule("GearPointsCustom")
			gpc = nil
		end)

		it("builds config options", function()
			gpc:BuildConfigOptions()
		end)
	end)

	describe("ui", function()
		local gpc

		before_each(function()
			if AddOn:IsModuleEnabled("GearPointsCustom") then
				AddOn:ToggleModule("GearPointsCustom")
			end
			AddOn:ToggleModule("GearPointsCustom")
			gpc = AddOn:GearPointsCustomModule()
			PlayerEnteredWorld()
			GuildRosterUpdate()
		end)

		teardown(function()
			AddOn:ToggleModule("GearPointsCustom")
			gpc = nil
		end)

		it("builds add item frame", function()
			local f = gpc:GetAddItemFrame()
			assert(f)
			f.queryInput:SetText(18832)
			f.Query()
			gpc:OnAddItemClick()
		end)
	end)
end)