local AddOn

describe("Native UI", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_Native')
    end)
    teardown(function()
        After()
    end)

    describe("is", function()
        it("loaded and initialized", function()
            assert(AddOn.Libs.Util.Objects.ToString(AddOn))
        end)
    end)
end)