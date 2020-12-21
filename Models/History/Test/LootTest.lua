local AddOnName, AddOn
local Loot, LootStatistics, Util, CDB, LibEncounter
local history = {}


describe("Loot History", function()

    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'History_Traffic')
        loadfile('Models/History/Test/LootTestData.lua')()
        local HistoryPkg = AddOn.Package('Models.History')
        Loot, LootStatistics = HistoryPkg.Loot, HistoryPkg.LootStatistics
        CDB =  AddOn.Package('Models').CompressedDb
        Util = AddOn:GetLibrary('Util')
        LibEncounter = AddOn:GetLibrary('Encounter')

        for k,v in pairs(LootTestData_M2) do
            history[k] = CDB.static:decompress(v)
        end
    end)

    teardown(function()
        history = {}
        After()
    end)


    --describe("one-for-one", function()
    --    local AceSerializer = AddOn:GetLibrary('AceSerializer')
    --    --- @type LibMessagePack
    --    local MessagePack = AddOn:GetLibrary('MessagePack')
    --    local Compressor = Util.Compression.GetCompressors(Util.Compression.CompressorType.LibDeflate)[1]
    --    local Base64 = AddOn:GetLibrary("Base64")
        --it("convert data", function()
        --    local converted = {}
        --
        --    for k, v in pairs(history) do
        --        local m = MessagePack.pack(v)
        --        converted[k]= Base64:Encode(Compressor:compress(m))
        --    end
        --
        --    print(Util.Objects.ToString(converted))
        --end)
    --    it("convert data (M1 to M2)", function()
    --        local converted = {}
    --
    --        for name, entries in pairs(history) do
    --            local e = {}
    --            for _, v in pairs(entries) do
    --                v.color = nil
    --                v.groupSize = nil
    --                v.itemSubTypeId = nul
    --                v.itemTypeId = nil
    --                v.typeCode = nil
    --
    --
    --                --v.typeCode = nil
    --                --
    --                if v.boss then
    --                    local creatureId = LibEncounter:GetCreatureId(v.boss)
    --                    local encounterId = LibEncounter:GetEncounterId(creatureId)
    --
    --                    v.encounterId = encounterId
    --                    v.boss = nil
    --                    v.instance = nil
    --                end
    --
    --                if v.mapId then
    --                    v.instanceId = v.mapId
    --                    v.mapId = nil
    --                end
    --
    --                Util.Tables.Push(e, v)
    --            end
    --
    --            converted[name] =  Base64:Encode(Compressor:compress(MessagePack.pack(e)))
    --        end
    --
    --        print(Util.Objects.ToString(converted))
    --    end)
    --end)


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

            print(Util.Objects.ToString(totals))
        end)
    end)

end )