local AddOnName, AddOn, Util, Comm, C, Player

describe("Sync", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_Sync')
		AddOnLoaded(AddOnName, true)
		Util, C = AddOn:GetLibrary('Util'), AddOn.Constants
		Comm, Player = AddOn.Require('Core.Comm'),  AddOn.Package('Models').Player
		GuildRosterUpdate()
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local module = AddOn:SyncModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("Sync")
			local module = AddOn:SyncModule()
			assert(module)
			assert(module:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("Sync")
			local module = AddOn:SyncModule()
			assert(module)
			assert(not module:IsEnabled())
		end)
	end)

	describe("functional", function()
		local match = require "luassert.match"
		local _ = match._

		--- @type Sync
		local sync
		setup(function()
			Comm:Register(C.CommPrefixes.Sync)
			sync = AddOn:SyncModule()
			AddOn.player = Player:Get("Player1")
		end)

		teardown(function()
			sync = nil
		end)

		it("handles SyncSYN (Unavailable)", function()
			local s = spy.on(sync, "SyncNACKReceived")
			sync:SendSyncSYN(AddOn.player:GetName(), 'MasterLooter', sync.handlers['MasterLooter'].send())
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s).was.called(1)
			assert.spy(s).was.called_with(match.is_ref(sync), match.is_table(), 'MasterLooter', sync.Responses.Unavailable.id)
			assert.equal(#sync.streams, 0)
			s:clear()
			sync:SendSyncSYN(C.group, 'MasterLooter', sync.handlers['MasterLooter'].send())
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s).was.called(40)
			assert.equal(#sync.streams, 0)
			s:clear()
			sync:SendSyncSYN(C.guild, 'MasterLooter', sync.handlers['MasterLooter'].send())
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s).was.called(10)
			assert.equal(#sync.streams, 0)
		end)

		it("handles SyncSYN (Available)", function()
			local s1 = spy.on(sync, "SyncACKReceived")
			local s2 = spy.on(sync, "SendSyncData")
			local s3 = spy.on(sync, "SyncDataReceived")
			AddOn:CallModule('Sync')
			sync:SendSyncSYN(AddOn.player:GetName(), 'MasterLooter', sync.handlers['MasterLooter'].send())
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s1).was.called(1)
			assert.spy(s2).was.called(1)
			WoWAPI_FireUpdate(GetTime() + 10)
			assert.spy(s3).was.called(1)
		end)
	end)
end)