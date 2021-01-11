local AddOnName, AddOn, Util, CDB

local function NewLootHistoryDb(lh, data)
	local db = NewAceDb(lh.defaults)
	for player, history in pairs(data) do
		db.factionrealm[player] = history
	end
	lh.db = db
	lh.history = CDB(db.factionrealm)
end

describe("LootHistory", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_LootHistory')
		loadfile('Modules/History/Test/LootHistoryTestData.lua')()
		Util, CDB = AddOn:GetLibrary('Util'), AddOn.ImportPackage('Models').CompressedDb
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local lh = AddOn:LootHistoryModule()
			assert(lh)
			assert(not lh:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("LootHistory")
			local lh = AddOn:LootHistoryModule()
			assert(lh)
			assert(lh:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("LootHistory")
			local lh = AddOn:LootHistoryModule()
			assert(lh)
			assert(not lh:IsEnabled())
		end)
	end)

	describe("functional", function()
		--- @type LootHistory
		local lh
		setup(function()
			AddOn:CallModule("LootHistory")
			lh = AddOn:LootHistoryModule()
			NewLootHistoryDb(lh, LootHistoryTestData_M)
		end)

		teardown(function()
			lh = nil
		end)

		it("builds data", function()
			lh:BuildData()
			assert.equal(#lh.frame.rows, 86)
			assert.equal(#lh.frame.date.data, 35)
			assert.equal(#lh.frame.instance.data, 4)
			assert.equal(#lh.frame.name.data, 13)
		end)

		it("updates more info", function()
			lh:UpdateMoreInfo(lh.frame, lh.frame.st.data, 23)
			assert(lh.frame.moreInfo:IsVisible())
			lh:UpdateMoreInfo(lh.frame, lh.frame.st.data, 49)
			assert(lh.frame.moreInfo:IsVisible())
		end)
	end)

	describe("imports", function()
		--- @type LootHistory
		local lh
		--- @type Sync
		local sync

		setup(function()
			AddOn:CallModule("LootHistory")
			lh = AddOn:LootHistoryModule()
			sync = AddOn:SyncModule()
		end)

		it("from sync", function()
			local handler = sync.handlers['LootHistory']
			local data = handler.send()
			NewLootHistoryDb(lh, LootHistoryTestData_M2)
			handler.receive(data)
		end)
	end)
end)