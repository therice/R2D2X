local AddOnName, AddOn
local Traffic, TrafficStatistics, Util, Award, CDB, LibEncounter
local history = {}

describe("Traffic History", function()

    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'History_Traffic')
        loadfile('Models/History/Test/TrafficTestData.lua')()
        local HistoryPkg = AddOn.Package('Models.History')
        Traffic, TrafficStatistics = HistoryPkg.Traffic, HistoryPkg.TrafficStatistics
        CDB =  AddOn.Package('Models').CompressedDb
        Award = AddOn.Package('Models').Award
        Util = AddOn:GetLibrary('Util')
        LibEncounter = AddOn:GetLibrary('Encounter')

        -- be sure the test data being used corresponds to serializer in DB
        for _,v in pairs(TrafficTestData_M2) do
            Util.Tables.Push(history, CDB.static:decompress(v))
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
    --    --- @type LibItemUtil
    --    local ItemUtil = AddOn:GetLibrary("ItemUtil")
    --    it("comparison", function()
    --        local a, at,  m, mt
    --        local as, ms, dst, dsm= {s=0, t=0}, {s=0, t=0}, 0, 0
    --        local ac, mc
    --
    --        for _, v in pairs(history) do
    --
    --            for _, p in pairs(v.subjects) do
    --                p[2] = ItemUtil.ClassTagNameToId[p[2]]
    --            end
    --
    --            local t = debugprofilestop()
    --            a = AceSerializer:Serialize(v)
    --            at = debugprofilestop() - t
    --            t = debugprofilestop()
    --            m = MessagePack.pack(v)
    --            mt = debugprofilestop() - t
    --
    --            --ac = Base64:Encode(Compressor:compress(a))
    --            --mc = Base64:Encode(Compressor:compress(m))
    --            --print(format("A=%d/%d/%.2f, M=%d/%d/%.2f", #a, #ac, at, #m, #mc, mt))
    --
    --            as.s = as.s + #a
    --            as.t = as.t + at
    --            ms.s = ms.s + #m
    --            ms.t = ms.t + mt
    --            print(format("A=%d/%.2f, M=%d/%.2f", #a, at, #m, mt))
    --
    --            local t = debugprofilestop()
    --            a = AceSerializer:Deserialize(a)
    --            at = debugprofilestop() - t
    --            t = debugprofilestop()
    --            m = MessagePack.unpack(m)
    --            mt = debugprofilestop() - t
    --            print(format("A=%.2f, M=%.2f", at, mt))
    --
    --            dst = dst + at
    --            dsm = dsm + mt
    --        end
    --
    --        -- A = AceSerializer
    --        -- S = LibSerialize
    --        -- M = LibMessagePack
    --        --
    --        -- TrafficTest: A=1841794/658.35, S=1186912/3173.70, M=1306438/664.57
    --        -- TrafficTest: A=974.60, S=1366.32, M=836.52
    --        --
    --        -- TrafficTest: A=1841794/655.92, S=1186912/3111.97, M=1306438/662.50
    --        -- TrafficTest: A=963.11, S=1336.98, M=826.76
    --        --
    --        -- TrafficTest: A=1841794/658.04, S=1186912/3112.96, M=1306438/658.54
    --        -- TrafficTest: A=979.75, S=1346.00, M=822.54
    --        --
    --        -- TrafficTest: A=1841794/669.33, S=1186912/3122.90, M=1306438/683.55
    --        -- TrafficTest: A=989.46, S=1344.68, M=844.81
    --        --
    --        -- TrafficTest: A=1841794/655.63, S=1186912/3130.07, M=1306438/679.95
    --        -- TrafficTest: A=976.40, S=1358.44, M=842.39
    --        --
    --        -- TrafficTest: A=78030/31.22, S=52013/141.06, M=51979/31.60
    --        -- TrafficTest: A=46.35, S=57.77, M=36.12
    --        --
    --        -- TrafficTest: A=1707775/678.69, S=1141607/3074.40, M=1141257/680.58
    --        -- TrafficTest: A=1034.96, S=1254.68, M=769.23
    --        print(format("A=%d/%.2f, M=%d/%.2f", as.s, as.t,  ms.s, ms.t))
    --        print(format("A=%.2f, M=%.2f", dst, dsm))
    --    end)
    --
    --    it("convert data (A to M)", function()
    --        local converted = {}
    --
    --        for _, v in pairs(history) do
    --            local m = MessagePack.pack(v)
    --            tinsert(converted, Base64:Encode(Compressor:compress(m)))
    --        end
    --
    --        print(Util.Objects.ToString(converted))
    --    end)
    --    it("convert data (M1 to M2)", function()
    --        local converted = {}
    --        local encounters = {610, 617, 712, 717, 1107, 1113, 672, 668}
    --        for _, v in pairs(history) do
    --            v.typeCode = nil
    --
    --            if v.boss then
    --                local creatureId = LibEncounter:GetCreatureId(v.boss)
    --                local encounterId = LibEncounter:GetEncounterId(creatureId)
    --
    --                v.encounterId = encounterId
    --                v.boss = nil
    --                v.instance = nil
    --            end
    --
    --            if v.mapId then
    --                v.instanceId = v.mapId
    --                v.mapId = nil
    --            end
    --
    --            -- add random encounters to raid EP awards
    --            if v.resourceType == 1 and v.subjectType == 3 and v.actionType == 1 then
    --                local encounter = Util.Tables.Random(encounters)
    --                v.instanceId = LibEncounter:GetEncounterMapId(encounter)
    --                v.encounterId = encounter
    --            end
    --
    --            local m = MessagePack.pack(v)
    --            tinsert(converted, Base64:Encode(Compressor:compress(m)))
    --        end
    --        print(Util.Strings.Join('", "', unpack(converted)))
    --    end)
    --end)

    describe("instance", function()
        it("creation fails on invalid arguments", function()
            assert.has.errors(function() Traffic(nil, {}) end, "The specified data was not of the correct type : table")
        end)
        it("reconstitution", function()
            local t = Traffic:reconstitute(history[1])
            assert.is.same(
                    t:toTable(),
                    {
                        resourceQuantity = 83,
                        description = 'Husk of the Old God',
                        id = '1602307917-16696',
                        subjectType = 1,
                        subjects = {{'Abramelin-Atiesh', 'MAGE'}},
                        resourceType = 2,
                        version = {minor = 0, patch = 0, major = 1},
                        actionType = 1,
                        timestamp = 1602307917,
                        resourceBefore = 142,
                        actor = 'Gnomechómsky-Atiesh',
                        actorClass = 'WARLOCK'
                    }
            )
        end)
    end)

    describe("statistics", function()
        it("creation", function()
            local stats = TrafficStatistics()
            for _, v in pairs(history) do
                stats:ProcessEntry(v)
            end

            local se = stats:Get('Gnomechómsky-Atiesh')
            local totals = se:CalculateTotals()
            print(Util.Objects.ToString(totals))
            assert(totals.awards[Award.ResourceType.Ep].count == 16)
            assert(totals.awards[Award.ResourceType.Ep].total == 275)
            assert(totals.awards[Award.ResourceType.Ep].decays == 1)
            assert(totals.awards[Award.ResourceType.Ep].resets == 0)

            assert(totals.awards[Award.ResourceType.Gp].count == 0)
            assert(totals.awards[Award.ResourceType.Gp].total == 0)
            assert(totals.awards[Award.ResourceType.Gp].decays == 1)
            assert(totals.awards[Award.ResourceType.Gp].resets == 0)

            se = stats:Get(TrafficStatistics.Summary)
            totals = se:CalculateTotals()
            print(Util.Objects.ToString(totals))
        end)
    end)
end)