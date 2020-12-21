local AddOnName, AddOn, Util, Player, C


describe("MasterLooter", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_MasterLooter')
		C = AddOn.Constants
		Util, Player = AddOn:GetLibrary('Util'), AddOn.Package('Models').Player
		AddOnLoaded(AddOnName, true)
		SetTime()
	end)

	teardown(function()
		--print(Util.Objects.ToString( AddOn.Require('Core.Event').private.metricsRcv:Summarize()))
		--print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsSend:Summarize()))
		--print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsRecv:Summarize()))
		--print(Util.Objects.ToString( AddOn.Require('Core.Comm').private.metricsFired:Summarize()))
		After()
	end)

	describe("lifecycle", function()
		teardown(function()
			AddOn:YieldModule("LootSession")
			AddOn:YieldModule("MasterLooter")
		end)

		it("is disabled on startup", function()
			local module = AddOn:MasterLooterModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("MasterLooter")
			local module = AddOn:MasterLooterModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("MasterLooter")
			local module = AddOn:MasterLooterModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)

	describe("events", function()
		local module

		setup(function()
			_G.IsInRaidVal = true
			AddOn.handleLoot = true
			AddOn.player = Player:Get("Player1")
			AddOn:CallModule("MasterLooter")
			module = AddOn:MasterLooterModule()
			PlayerEnteredWorld()
			assert(module:IsEnabled())
		end)

		teardown(function()
			AddOn:YieldModule("LootSession")
			AddOn:StopHandleLoot()
			AddOn.masterLooter = nil
			module = nil
		end)

		it("handles LOOT_READY", function()
			WoWAPI_FireEvent("LOOT_READY")
			assert(module:IsEnabled())
			assert(module:_GetLootSlot(1))
			assert(not module:_GetLootSlot(2))
			assert(module:_GetLootSlot(3))
		end)

		it("handles LOOT_OPENED", function()
			WoWAPI_FireEvent("LOOT_OPENED")
			assert(module:IsEnabled())
			assert(module:_GetLootSlot(1))
			assert(not module:_GetLootSlot(2))
			assert(module:_GetLootSlot(3))
			assert(module:_GetLootTableEntry(1))
			assert(module:_GetLootTableEntry(2))
			assert(not module:_GetLootTableEntry(3))
			local lt = module:_GetLootTableForTransmit()
			assert(#lt == 2)
			for _, e in pairs(lt) do
				assert(e.ref)
				assert(not e.slot)
				assert(not e.awarded)
				assert(not e.sent)
			end
		end)
		it("handles LOOT_SLOT_CLEARED", function()
			WoWAPI_FireEvent("LOOT_SLOT_CLEARED", 1)
			assert(module:IsEnabled())
			assert(module:_GetLootSlot(1).looted)
		end)

		it("handles LOOT_CLOSED", function()
			WoWAPI_FireEvent("LOOT_CLOSED")
			assert(module:IsEnabled())
			assert(module.lootOpen == false)
		end)
	end)

	describe("functionality", function()
		--- @type MasterLooter
		local ml
		--- @type LootAllocate
		local la
		setup(function()
			_G.IsInRaidVal = true
			_G.UnitIsGroupLeaderVal = true
			_G.UnitIsUnit = function(unit1, unit2) return true end
			AddOn.player = Player:Get("Player1")
			-- AddOn.masterLooter = AddOn.player
			AddOn:CallModule("MasterLooter")
			ml = AddOn:MasterLooterModule()
			ml.db.profile.autoStart = true
			ml.db.profile.autoAdd = true
			ml.db.profile.outOfRaid = true
			ml.db.profile.acceptWhispers = true
			ml.db.profile.usage = {
				never  = false,
				ml     = true,
				ask_ml = false,
				state  = "ml",
			}
			la = AddOn:LootAllocateModule()
			PlayerEnteredWorld()
			assert(ml:IsEnabled())
			assert(AddOn:IsMasterLooter())
			GuildRosterUpdate()
		end)

		teardown(function()
			AddOn:YieldModule("MasterLooter")
			AddOn:StopHandleLoot()
			AddOn:YieldModule("Loot")
			AddOn:YieldModule("LootAllocate")
			AddOn.masterLooter = nil
			AddOn.player = nil
			AddOn.handleLoot = false
			ml, la = nil, nil
		end)

		it("sends LootTable", function()
			WoWAPI_FireEvent("LOOT_READY")
			WoWAPI_FireEvent("LOOT_OPENED")
			WoWAPI_FireUpdate(GetTime()+10)
			assert(AddOn.lootTable)
			assert(#AddOn.lootTable >= 1)
		end)

		it("handles Reconnect", function ()
			AddOn:Send(AddOn.masterLooter, C.Commands.Reconnect)
			_G.UnitIsUnit = function(unit1, unit2) return false end
			WoWAPI_FireUpdate(GetTime()+10)
			_G.UnitIsUnit = function(unit1, unit2) return true end
		end)

		it("HaveUnawardedItems", function()
			assert(ml:HaveUnawardedItems())
		end)

		it("UpdateLootSlots", function()
			ml:_UpdateLootSlots()
		end)

		it("CanGiveLoot", function()
			ml.lootOpen = false
			local ok, cause = ml:CanGiveLoot(1, nil, AddOn.player:GetName())
			assert(not ok)
			assert(cause == ml.AwardStatus.Failure.LootNotOpen)
			ml.lootOpen = true
			ok, cause = ml:CanGiveLoot(1, nil, AddOn.player:GetName())
			assert(not ok)
			assert(cause == ml.AwardStatus.Failure.LootGone)
			_G.GetContainerNumFreeSlots = function(bag) return 0, 0 end
			ok, cause = ml:CanGiveLoot(1, ml.lootSlots[1].item, AddOn.player:GetName())
			assert(not ok)
			assert(cause == ml.AwardStatus.Failure.MLInventoryFull)
			_G.GetContainerNumFreeSlots = function(bag) return 4, 0 end
			_G.UnitIsUnit = function(unit1, unit2) return false end
			_G.UnitIsConnected = function(unit) return false end
			ok, cause = ml:CanGiveLoot(1, ml.lootSlots[1].item, AddOn.player:GetName())
			assert(not ok)
			assert(cause == ml.AwardStatus.Failure.Offline)
			_G.UnitIsConnected = function(unit) return true end
			ok, cause = ml:CanGiveLoot(1, ml.lootSlots[1].item, AddOn.player:GetName())
			assert(not ok)
			assert(cause == ml.AwardStatus.Failure.NotBop)
			_G.UnitIsUnit = function(unit1, unit2) return true end
			ok, cause = ml:CanGiveLoot(1, ml.lootSlots[1].item, AddOn.player:GetName())
			assert(ok)
			assert(cause == nil)
		end)

		it("Award", function()
			local cbFired = false
			local function Cb(awarded, session, winner, status, award, callback, ...)
				cbFired = true
				assert(awarded)
				assert.equal(session, 1)
				assert.equal(winner, "Player1-Realm1")
				assert.equal(status, "Normal")
				assert(award)
				assert.equal(award.awardReason, "ms_need")
			end

			AddOn:SendResponse(C.group, 1, 1)
			WoWAPI_FireUpdate(GetTime() + 10)
			local award = AddOn:LootAllocateModule():GetItemAward(1, AddOn.player:GetName())
			ml:Award(award.session, award.winner, award:NormalizedReason().text, award.reason, Cb, award)
			WoWAPI_FireEvent("LOOT_SLOT_CLEARED", 1)
			assert(cbFired)
			WoWAPI_FireUpdate(GetTime() + 10)
		end)

		it("handles whispers", function()
			SendChatMessage("!help", "WHISPER")
			SendChatMessage("!items", "WHISPER")
			SendChatMessage("!item 2 3", "WHISPER")
			WoWAPI_FireUpdate(GetTime() + 10)

			local cr2 = la:GetCandidateResponse(2, AddOn.player:GetName())
			assert(cr2)
			assert.equal(cr2.response, 3)
		end)

		it("ends session", function()
			ml:EndSession()
			assert(not ml.running)
		end)
	end)
end)