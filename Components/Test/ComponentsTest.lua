local AddOn

describe("Component", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'Component')
    end)
    
    teardown(function()
        After()
    end)
    
   describe("new", function()
       it("fails with invalid arguments", function()
           assert.has.errors(function () AddOn.NewComponent(1) end)
           assert.has.errors(function () AddOn.NewComponent({}) end)
           assert.has.errors(function () AddOn.NewComponent(function() end) end)
       end)
       it("fails on repeated definition", function()
           local c = AddOn.NewComponent("c")
           assert.is.table(c)
           assert.has.errors(function () AddOn.NewComponent("c") end, "Component 'c' already exists")
       end)
   end)
    
    describe("get", function()
        it("returns correct component", function()
            local c1 = AddOn.NewComponent("TestC")
            local c2 = AddOn.GetComponent("TestC")
            assert.are.same(c1, c2)
        end)
        it("fails when component does not exit", function()
            assert.has.errors(
                function() AddOn.GetComponent("TestC2") end,
                "Component 'TestC2' does not exist"
            )
        end)
    end)
end)