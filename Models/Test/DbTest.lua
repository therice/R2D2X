local AddOnName, AddOn
local CompressedDb, Util

local function NewDb(data)
    -- need to add random # to end or it will have the same data
    local db = NewAceDb()
    if data then
        for k, v in pairs(data) do
            db.factionrealm[k] = v
        end
    end
    return db, CompressedDb(db.factionrealm)
end

describe("DB", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Db')
        ConfigureLogging()
        loadfile('Models/Test/DbTestData.lua')()
        Util = AddOn:GetLibrary('Util')
        CompressedDb = AddOn.Package('Models').CompressedDb
    end)

    teardown(function()
        After()
    end)
    describe("CompressedDb", function()
        it("handles compress and decompress", function()
            for _, v in pairs(TestData) do
                local c = CompressedDb.static:compress(v)
                local d = CompressedDb.static:decompress(c)
                assert.is.same(v, d)
            end
        end)
        it("handles single-value set/get via key", function()
            local _, db = NewDb()
            for k, v in pairs(TestData) do
                db:put(k, v)
            end

            -- print('Length=' .. #db)

            local c_ipairs = CompressedDb.static.ipairs

            for k, _ in c_ipairs(db) do
                assert(db:get(k))
                -- print(format("ipairs(%d)/get(%d)", k, k) .. ' =>'  .. Util.Objects.ToString(db:get(k)))
            end

            for _, v in c_ipairs(db) do
                assert(v)
                -- print("ipairs/v" .. ' =>'  .. Util.Objects.ToString(v))
            end

        end)
        it("handles single-value get/set via insert", function()
            local _, db = NewDb()
            for _, v in pairs(TestData) do
                db:insert(v)
            end

            --print('Length=' .. #db)

            local c_pairs = CompressedDb.static.pairs

            for k, _ in c_pairs(db) do
                assert(db:get(k))
                -- print(format("pairs(%d)/get(%d)", k, k) .. ' =>'  .. Util.Objects.ToString(db:get(k)))
            end

            for _, v in c_pairs(db) do
                assert(v)
                -- print("pairs/v" .. ' =>'  .. Util.Objects.ToString(v))
            end
        end)
        it("handles table set/get via key", function()
            local _, db = NewDb()
            for _, k in pairs({'a', 'b', 'c'}) do
                db:put(k, {})
                -- print(Util.Objects.ToString(db:get(k)))
            end

            for _, v in pairs({{a='a', b=1, c= true}, {c='c', d=10.6, e=false}}) do
                for _, k in pairs({'a', 'b', 'c'}) do
                    db:insert(v, k)
                end
            end

            --print('Length_1=' .. #db.db)
            --print('Length_2=' .. #db)

            local c_pairs = CompressedDb.static.pairs

            for k, _ in c_pairs(db) do
                assert(db:get(k))
                -- print(format("pairs(%s)/get(%s)", k, k) .. ' =>' .. Util.Objects.ToString(db:get(k)))
            end

            for _, v in c_pairs(db) do
                assert(v)
                --print("pairs/v" .. ' =>'  .. Util.Objects.ToString(v))
            end
        end)
        it("handles delete via key", function()
            local db, cdb = NewDb()
            local values = {"a", "b", "c", "1", "2", "3"}

            for _, v in Util.Objects.Each(values) do
                cdb:insert(v)
            end

            for k, v in pairs(db['factionrealm']) do
                if k ~= CompressedDb.static.CompressionSettingsKey then
                    assert.Is.Not.Nil(v)
                end
            end

            cdb:del(2)
            cdb:del(5)

            assert(#db['factionrealm'] == 4)
            local values2 = Util(values):Copy()()
            Util.Tables.Remove(values2, 2)
            Util.Tables.Remove(values2, 5)

            local c_pairs = CompressedDb.static.pairs
            for k, v in c_pairs(cdb) do
                assert(v == values2[k])
            end
        end)
        it("handles delete via key and index", function()
            local _, cdb = NewDb()
            local values = {["a"] = {1, 2}, ["b"] = {}, ["c"] = {3, 4}, ["1"] = {"a", "z"}}

            for k, _ in pairs(values) do
                cdb:put(k, values[k])
            end

            cdb:del('b')
            cdb:del('a', 2)
            cdb:del('1', 1)


            local values2 = Util(values):Copy()()
            Util.Tables.Remove(values2, 'b')
            Util.Tables.Remove(values2['a'], 2)
            Util.Tables.Remove(values2['1'], 1)

            local c_pairs = CompressedDb.static.pairs
            for k, v in c_pairs(cdb) do
                assert.Is.Not.Nil(values2[k])
                assert(Util.Tables.Equals(v, values2[k], true))
            end
        end)
        it("detects and removes nil values (numeric index)", function()
            local db, cdb = NewDb(TestSparseData)

            local c_pairs = CompressedDb.static.pairs

            local count = 0
            for k, _ in c_pairs(cdb) do
                assert(cdb:get(k))
                -- print(format("cdb pairs(%s)/get(%s)", tostring(k), tostring(k)) .. ' =>'.. Util.Objects.ToString(cdb:get(k)))
                count = count +1
            end
            assert(count == 6)

            for k, v in pairs(db.factionrealm) do
                assert(v)
                --print( Util.Objects.ToString(k) .. ' = ' .. Util.Objects.ToString(v))
            end
        end)
        it("detects and removes nil values (string index)", function()
            local _, cdb = NewDb(TestSparseData2)
            local c_pairs = CompressedDb.static.pairs

            local count = 0
            for k, _ in c_pairs(cdb) do
                assert(cdb:get(k))
                -- print(format("cdb pairs(%s)/get(%s)", tostring(k), tostring(k)) .. ' =>'.. Util.Objects.ToString(cdb:get(k)))
                count = count +1
            end
            assert(count == 6)

        end)
    end)
end )