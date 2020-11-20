local AddOnName, AddOn
local Traffic, TrafficStatistics, Util, Award, CDB
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

        for _,v in pairs(TrafficTestData) do
            Util.Tables.Push(history, CDB.static:decompress(v))
        end
    end)

    teardown(function()
        history = {}
        After()
    end)

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
            assert(totals.awards[Award.ResourceType.Ep].count == 16)
            assert(totals.awards[Award.ResourceType.Ep].total == 275)
            assert(totals.awards[Award.ResourceType.Ep].decays == 1)
            assert(totals.awards[Award.ResourceType.Ep].resets == 0)

            assert(totals.awards[Award.ResourceType.Gp].count == 0)
            assert(totals.awards[Award.ResourceType.Gp].total == 0)
            assert(totals.awards[Award.ResourceType.Gp].decays == 1)
            assert(totals.awards[Award.ResourceType.Gp].resets == 0)
        end)
    end)
end)