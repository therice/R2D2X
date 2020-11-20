local AddOnName, AddOn
local Loot, LootStatistics, Util, CDB
local history = {}


describe("Loot History", function()

    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'History_Traffic')
        loadfile('Models/History/Test/LootTestData.lua')()
        local HistoryPkg = AddOn.Package('Models.History')
        Loot, LootStatistics = HistoryPkg.Loot, HistoryPkg.LootStatistics
        CDB =  AddOn.Package('Models').CompressedDb
        Util = AddOn:GetLibrary('Util')

        for k,v in pairs(LootTestData) do
            history[k] = CDB.static:decompress(v)
        end
    end)

    teardown(function()
        history = {}
        After()
    end)

    describe("creation", function()
        it("from no args", function()
            local entry = Loot()
            assert(entry:FormattedTimestamp() ~= nil)
            assert(entry.id:match("(%d+)-(%d+)"))
        end)
        it("from instant #travisignore", function()
            local entry = Loot(1585928063)
            assert(entry:FormattedTimestamp() == "04/03/2020 09:34:23")
            assert(entry.id:match("1585928063-(%d+)"))
        end)
    end)

    describe("marshalling", function()
        it("to table", function()
            local entry = Loot(1585928063)
            local asTable = entry:toTable()
            assert(asTable.timestamp == 1585928063)
            assert(asTable.version ~= nil)
            assert(asTable.version.major >= 1)
        end)
        it("from table", function()
            local entry1 = Loot(1585928063)
            local asTable = entry1:toTable()
            local entry2 = Loot:reconstitute(asTable)
            assert.equals(entry1.id, entry2.id)
            assert.equals(entry1.timestamp, entry2.timestamp)
            assert.equals(entry1.version.major, entry2.version.major)
            -- invoke to make sure class meta-data came back with reconstitute
            entry2.version:nextMajor()
            assert.equals(tostring(entry1.version), tostring(entry2.version))
        end)
    end)

    describe("stats", function()
        it("creation", function()
            local stats = LootStatistics()
            for k,  e in pairs(history) do
                for i, v in ipairs(e) do
                    stats:ProcessEntry(k, v, i)
                end
            end

            local se = stats:Get('Gnomechómsky-Atiesh')
            local totals = se:CalculateTotals()
            assert(totals.count == 14)
            assert(totals.raids.count == 10)
        end)
    end)

end )