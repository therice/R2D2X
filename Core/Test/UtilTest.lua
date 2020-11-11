local AddOnName, AddOn

describe("Util", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true)
    end)
    teardown(function()
        After()
    end)

    describe("functions", function()
        it("Qualify", function()
            assert(AddOn:Qualify("Test") == format("%s_%s", AddOn.Constants.name, "Test"))
            assert(AddOn:Qualify("Test", "Another") == format("%s_%s_%s", AddOn.Constants.name, "Test", "Another"))
        end)
    end)
end)