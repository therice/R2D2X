local _, AddOn = ...
local NativeUI = AddOn.Require('UI.Native')
local BaseWidget = AddOn.ImportPackage('UI').NativeWidget
local Button = AddOn.Package('UI.Widgets'):Class('Button', BaseWidget)

function Button:initialize(parent, name)
    BaseWidget.initialize(self, parent, name)
end

function Button:Create()
    local b = CreateFrame(
            "Button",
            self.parent:GetName() .. '_' .. self.name,
            self.parent,
            "UIPanelButtonTemplate"
    )
    b:SetText("")
    b:SetSize(100,25)
    return b
end

NativeUI:RegisterWidget('Button', Button)