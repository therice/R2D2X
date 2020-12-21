local AddOnName, AddOn,  Util
--- @type Models.StandbyMember
local StandbyMember
--- @type Models.StandbyStatus
local StandbyStatus

describe("Standby", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Player')
		Util, StandbyMember, StandbyStatus =
			AddOn:GetLibrary('Util'), AddOn.Package('Models').StandbyMember, AddOn.Package('Models').StandbyStatus
	end)

	teardown(function()
		After()
	end)

	describe("Member", function()
		it("is created from parameters (no contacts)", function()
			local m = StandbyMember("Imatest", "WARLOCK", {})
			assert(m.name == "Imatest")
			assert(m.class == "WARLOCK")
			assert(m.joined ~= nil)
			assert(m.status.timestamp == m.joined)
			assert(m.status.online == true)
			assert(Util.Tables.Count(m.contacts) == 0)
		end)
		it("is created from parameters (contacts)", function()
			local m = StandbyMember("Imatest", "WARLOCK", {"Anothertest", "Debugme"})
			assert(m.name == "Imatest")
			assert(m.class == "WARLOCK")
			assert(m.joined ~= nil)
			assert(m.status.timestamp == m.joined)
			assert(m.status.online == true)
			assert(Util.Tables.Count(m.contacts) == 2)

			for name, status in pairs(m.contacts) do
				assert(Util.Objects.In(name, "Anothertest", "Debugme"))
				assert(status.timestamp == m.joined)
				assert(status.online == false)
			end

			print(Util.Objects.ToString(m:toTable()))
			m = StandbyMember("Imatest", "WARLOCK", "Anothertest")
			assert(m:JoinedTimestamp())
			assert(m:PingedTimestamp())
			assert(m:IsOnline())
			assert(m:IsPlayerOrContact("Anothertest"))
			m:UpdateStatus("Imatest", true)
			assert(m:IsOnline())
			_G.UnitIsUnit = function(unit1, unit2) return true end
			m:UpdateStatus("Anothertest", false)
			assert(not m:IsOnline())
			print(Util.Objects.ToString(m:toTable()))
		end)
		it("supports (de)serialization", function()
			local m1 = StandbyMember("Imatest", "WARLOCK", {"Anothertest", "Debugme"})
			m1.status = StandbyStatus(1602021820, false)
			m1:UpdateStatus('Anothertest', true)

			local m2 = StandbyMember:reconstitute(m1:toTable())
			for name, status in pairs(m2.contacts) do
				assert(Util.Objects.In(name, "Anothertest", "Debugme"))
				assert(Util.Tables.Equals(m1.contacts[name]:toTable(), status:toTable(), true))
			end

			local e1, e2 = m1:toTable(), m2:toTable()
			assert.are.same(e1, e2)
		end)
	end)
end)