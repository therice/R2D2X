local AddOn, NativeUI

describe("Native UI Widgets", function()
    setup(function()
        _, AddOn = loadfile("Test/TestSetup.lua")(true, 'UI_Native_Widgets')
        NativeUI = AddOn.Require('UI.Native')
    end)

    teardown(function()
        After()
    end)

    describe("widget creation", function()
        it("succeeds for Button", function()
            NativeUI:New('Button')
        end)
        it("succeeds for EditBox", function()
            NativeUI:New('EditBox')

        end)
        it("succeeds for IconBordered", function()
            local w = NativeUI:New('IconBordered')
            w:SetBorderColor("red")
            w:Desaturate("red")
            w:GetScript("OnLeave")()
        end)
        it("succeeds for Text", function()
            local w = NativeUI:New('Text')
            w:SetHeight(10)
            w:SetWidth(10)
            w:SetTextColor()
            w:SetText('t')
        end)
        it("succeeds for Frame", function()
            local w = NativeUI:New('Frame')
        end)
    end)
end)