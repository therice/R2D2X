
local AddOnName, AddOn, Util

describe("Core", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Core_Core')
		AddOnLoaded(AddOnName, true)
		Util = AddOn:GetLibrary('Util')
		SetTime()
		_G.IsInRaidVal = true
		_G.UnitIsGroupLeaderVal = true
		_G.UnitIsUnit = function(unit1, unit2) return true end
		local db = AddOn:MasterLooterModule().db.profile
		db.onlyUseInRaids = true
		db.usage = {
			never  = false,
			ml     = true,
			ask_ml = false,
			state  = "ml",
		}
		PlayerEnteredWorld()
		GuildRosterUpdate()
		assert(AddOn:IsMasterLooter())
	end)
	teardown(function()
		After()
	end)
	describe("Core", function()
		it("GetButtonCount", function()
			assert.equal(4, AddOn:GetButtonCount())
		end)
		it("GetButtons", function()
			local buttonCount, buttons = AddOn:GetButtonCount(), AddOn:GetButtons()
			print(Util.Objects.ToString(buttons))
			for i = 1, buttonCount do
				assert(buttons[i])
			end
		end)
		it("GetResponse", function()
			for _, r in pairs(AddOn.Constants.Responses) do
				if r ~= AddOn.Constants.Responses.Roll then
					assert(AddOn:GetResponse(r))
				end
			end
			local buttonCount = AddOn:GetButtonCount()
			for i = 1, buttonCount do
				assert(AddOn:GetResponse(i))
			end
		end)
		it("UpdateGroupMembers", function()
			AddOn:UpdateGroupMembers()
			assert(Util.Tables.Count(AddOn.group) >= 1)
		end)
		it("GroupIterator", function()
			for name in AddOn:GroupIterator() do
				assert(Util.Strings.StartsWith(name, "Player"))
				assert(Util.Strings.EndsWith(name, "Realm1"))
			end
		end)
	end)
end)