local AddOnName, AddOn

describe("Library", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(false, 'Library')
        loadfile("Test/WowXmlParser.lua")()
        ParseXmlAndLoad('Libs/LibClass-1.0/LibClass-1.0.xml', AddOnName, AddOn)
        ParseXmlAndLoad('Core/Oak/Oak.xml', AddOnName, AddOn)
    end)

    teardown(function()
        After()
        AddOn:DiscardLibraries()
    end)

    describe("load library", function()
        it("fails if not available", function()
            assert.has.errors(function() AddOn:AddLibrary('LibLib', 'LibLib-0.1') end, "Cannot find a library instance of \"LibLib-0.1\"\.")
        end)
        it("succeeds", function()
            assert.has.errors(function() AddOn:GetLibrary('Class') end, "Library 'Class' not found - was it loaded via AddLibrary?")
            AddOn:AddLibrary('Class', 'LibClass-1.0')
            AddOn:DiscardLibraries()
        end)
    end)

    describe("yields library", function()
        it("fails if not loaded", function()
            assert.has.errors(function() AddOn:GetLibrary('LibLogging') end, "Library 'LibLogging' not found - was it loaded via AddLibrary?")
        end)
        it("succeeds", function()
            assert.has.errors(function() AddOn:GetLibrary('Class') end, "Library 'Class' not found - was it loaded via AddLibrary?")
            AddOn:AddLibrary('Class', 'LibClass-1.0')
            assert(AddOn:GetLibrary('Class'))
            AddOn:DiscardLibraries()
        end)
    end)
end)