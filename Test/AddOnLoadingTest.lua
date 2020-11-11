local AddOnName, AddOn

describe("AddOn", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true)
    end)
    teardown(function()
        After()
    end)

    describe("is", function()
        it("loaded", function()
            assert(AddOn.Constants.name == AddOnName)
        end)
    end)
end)