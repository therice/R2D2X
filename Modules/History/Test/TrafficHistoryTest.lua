local AddOnName, AddOn, Util, CDB


local function NewTrafficHistoryDb(th, data)
	local db = NewAceDb(th.defaults)
	for k, history in pairs(data) do
		db.factionrealm[k] = history
	end
	th.db = db
	th.history = CDB(db.factionrealm)
end

describe("TrafficHistory", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Modules_TrafficHistory')
		loadfile('Modules/History/Test/TrafficHistoryTestData.lua')()
		Util, CDB = AddOn:GetLibrary('Util'), AddOn.ImportPackage('Models').CompressedDb
		AddOnLoaded(AddOnName, true)
	end)

	teardown(function()
		After()
	end)

	describe("lifecycle", function()
		it("is disabled on startup", function()
			local th = AddOn:TrafficHistoryModule()
			assert(th)
			assert(not th:IsEnabled())
		end)
		it("can be enabled", function()
			AddOn:ToggleModule("TrafficHistory")
			local th = AddOn:TrafficHistoryModule()
			assert(th)
			assert(th:IsEnabled())
		end)
		it("can be disabled", function()
			AddOn:ToggleModule("TrafficHistory")
			local th = AddOn:TrafficHistoryModule()
			assert(th)
			assert(not th:IsEnabled())
		end)
	end)

	describe("functional", function()
		--- @type TrafficHistory
		local th
		setup(function()
			AddOn:CallModule("TrafficHistory")
			th = AddOn:TrafficHistoryModule()
			NewTrafficHistoryDb(th, TrafficTestData_M)
		end)

		teardown(function()
			th = nil
		end)

		it("builds data", function()
			th:BuildData()
			assert.equal(#th.frame.rows, 66)
		end)

		it("updates more info", function()
			th:UpdateMoreInfo(th.frame, th.frame.st.data, 23)
			assert(th.frame.moreInfo:IsVisible())
			th:UpdateMoreInfo(th.frame, th.frame.st.data, 49)
			assert(th.frame.moreInfo:IsVisible())
		end)
	end)

	describe("imports", function()
		--- @type TrafficHistory
		local th
		--- @type Sync
		local sync

		setup(function()
			AddOn:CallModule("TrafficHistory")
			th = AddOn:TrafficHistoryModule()
			NewTrafficHistoryDb(th, TrafficTestData_M)
			sync = AddOn:SyncModule()
		end)

		it("from sync", function()
			local handler = sync.handlers['TrafficHistory']
			local data = handler.send()
			NewTrafficHistoryDb(th, TrafficTestData_M2)
			handler.receive(data)
		end)
	end)
end)