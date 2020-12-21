
local AddOnName, AddOn, Util, Player, C, StandbyMember

describe("Standby", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_Standby')
		C = AddOn.Constants
		Util, Player, StandbyMember =
			AddOn:GetLibrary('Util'), AddOn.Package('Models').Player, AddOn.Package('Models').StandbyMember
		AddOnLoaded(AddOnName, true)
		SetTime()
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		teardown(function()
			AddOn:YieldModule("Standby")
		end)

		it("is disabled on startup", function()
			local sb = AddOn:StandbyModule()
			assert(sb)
			assert(not sb:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("Standby")
			local sb = AddOn:StandbyModule()
			assert(sb)
			assert(sb:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("Standby")
			local sb = AddOn:StandbyModule()
			assert(sb)
			assert(not sb:IsEnabled())
		end)
	end)

	describe("functionality", function()
		--- @type Standby
		local sb

		setup(function()
			_G.IsInRaidVal = true
			_G.UnitIsGroupLeaderVal = true
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.player = Player:Get("Player1")
			-- AddOn.masterLooter = AddOn.player
			AddOn:CallModule("MasterLooter")
			PlayerEnteredWorld()
			assert(AddOn:IsMasterLooter())
			GuildRosterUpdate()
			AddOn:CallModule("Standby")
			sb = AddOn:StandbyModule()
			sb.db.profile = {
				enabled                 = true,
				standby_pct             = 0.75,
				verify_after_each_award = false,
			}
		end)

		teardown(function()
			AddOn:YieldModule("MasterLooter")
			AddOn:YieldModule("Standby")
			AddOn:StopHandleLoot()
			AddOn.masterLooter = nil
			AddOn.player = nil
			AddOn.handleLoot = false
			sb = nil
		end)

		it("loads roster from DB", function()
			sb:ResetRoster()
			sb.db.profile.roster = {
				['Player1-Realm1'] = {
					joined = 1607820681,
					name = 'Player1-Realm1',
					status = {
						online = true,
						timestamp = 1607820681
					},
					class = 'WARLOCK',
					contacts = {
						['Player4-Realm1'] = {
							online = false,
							timestamp = 1607820681
						},
						['Player5-Realm1'] = {
							online = false,
							timestamp = 1607820681
						}
					}
				}
			}
			sb:RosterSetup()
			assert.equal(Util.Tables.Count(sb.roster), 1)

			local sbe = sb.roster['Player1-Realm1']
			assert(sbe)
			assert(sbe:IsOnline())
			assert.equal(Util.Tables.Count(sbe.contacts), 2)
		end)

		it("adds player", function()
			sb:AddPlayer(StandbyMember("Imatest", "WARRIOR", {}))
			assert.equal(Util.Tables.Count(sb.roster), 2)
		end)

		it("adss player from message", function()
			sb:AddPlayerFromMessage("A B C", "Imafaker")
			sb:AddPlayerFromMessage("", "Imanoob")
			assert.equal(Util.Tables.Count(sb.roster), 4)
		end)

		it("removes player", function()
			sb:RemovePlayer(StandbyMember("Imatest"))
			assert.equal(Util.Tables.Count(sb.roster), 3)
		end)

		it("prunes roster", function()
			sb.db.profile.verify_after_each_award = true
			local sbe = sb.roster['Imanoob']
			-- _G.UnitIsUnit = function(unit1, unit2) return true end
			sbe:UpdateStatus('Imanoob', false)
			sb:PruneRoster()
			assert.equal(Util.Tables.Count(sb.roster), 2)
			sb.db.profile.verify_after_each_award = false
		end)

		it("pings player", function()
			--sb:PingPlayer("Imatest")
			sb:PingPlayer("Imafaker")
			WoWAPI_FireUpdate(GetTime() + 10)
			local sbe = sb.roster['Imafaker']
			assert(sbe:IsOnline())
			assert.equal(Util.Tables.Count(sb.roster), 2)
		end)

		it("provides award roster", function()
			sb.db.profile.verify_after_each_award = false
			local roster, pct = sb:GetAwardRoster()
			assert.equal(Util.Tables.Count(roster), 2)
			assert.equal(pct, 0.75)
			sb.db.profile.verify_after_each_award = true
			roster, pct = sb:GetAwardRoster()
			assert.equal(Util.Tables.Count(roster), 2)
			assert.equal(pct, 0.75)
		end)
	end)
end)