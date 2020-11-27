local AddOnName, AddOn, Util, Encounter


describe("EffortPoints", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_EffortPoints')
		AddOnLoaded(AddOnName, true)
		Util = AddOn:GetLibrary('Util')
		Encounter = AddOn.Package('Models').Encounter
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:EffortPointsModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("EffortPoints")
			local module = AddOn:EffortPointsModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("EffortPoints")
			local module = AddOn:EffortPointsModule()
			assert(module)
			assert(module:IsEnabled())
		end)
	end)

	describe("configuration", function()
		it("is built", function()
			local module = AddOn:EffortPointsModule()
			assert(module:BuildConfigOptions())
		end)
	end)

	describe("functional", function()
		local ep

		before_each(function()
			ep = AddOn:EffortPointsModule()
			PlayerEnteredWorld()
			GuildRosterUpdate()
			_G.IsInRaidVal = true
			assert(ep:IsEnabled())
		end)

		teardown(function()
			ep = nil
		end)

		it("OnEncounterEnd", function()
			local e = Encounter(716, "encounterName", 1, 40, 1)
			ep:OnEncounterEnd(e)
			assert( e:IsSuccess())
			e = Encounter(710, "encounterName", 1, 10, 1)
			assert( e:IsSuccess())
			ep:OnEncounterEnd(e)
			e = Encounter(709, "encounterName", 1, 12)
			assert(not e:IsSuccess())
			ep:OnEncounterEnd(e)
			ep.db.profile.raid.award_defeat = true
			ep.db.profile.raid.auto_award_defeat = true
			ep:OnEncounterEnd(e)
		end)

		it("ScaleIfRequired", function()
			ep.db.profile.raid.maps['469'] = {
				scaling = true,
				scaling_pct = 0.50,
			}

			local value = ep:ScaleIfRequired(20, 469)
			assert.equal(value, 10)

			ep.db.profile.raid.maps['531'] = {
				scaling = false,
				scaling_pct = 0.25,
			}

			value = ep:ScaleIfRequired(50, 531)
			assert.equal(value, 50)

			value = ep:ScaleIfRequired(50, 9999)
			assert.equal(value, 50)

			_G.InstanceInfo = {
				name = "Molten Core",
				mapid = 469
			}

			value = ep:ScaleIfRequired(100)
			assert.equal(value, 50)

			_G.InstanceInfo = nil
			value = ep:ScaleIfRequired(100)
			assert.equal(value, 100)

			_G.IsInRaidVal = false
			value = ep:ScaleIfRequired(100)
			assert.equal(value, 100)
		end)
	end)
end)