local _, AddOn = ...
local L, Log, Util = AddOn.Locale, AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util")
local UI = AddOn.Require('UI.Native')
local Logging = AddOn:GetModule("Logging", true)

function Logging:BuildFrame()
    if not self.frame then
        local frame = UI:NewNamed('Frame', UIParent, 'LoggingWindow', 'Logging', L['frame_logging'], 750, 400, false)
        frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local msg = UI:NewNamed('ScrollingMessageFrame', frame.content, 'Messages')
        msg:SetMaxLines(10000)
        msg:SetPoint("CENTER", frame.content, "CENTER", 0, 10)
        frame.msg = msg

        local close = UI:NewNamed('Button', frame.content, "Close")
        close:SetText('Close')
        close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -13, 5)
        close:SetScript("OnClick", function() frame:Hide() end)
        frame.close = close

        local clear =  UI:NewNamed("Button", frame.content, "Clear")
        clear:SetText('Clear')
        clear:SetPoint("RIGHT", frame.close, "LEFT", -25)
        clear:SetScript("OnClick", function() frame.msg:Clear() end)
        frame.clear = clear

        self.frame = frame
    end

    return self.frame
end

function Logging:SwitchDestination(msgs)
    if self.frame then
        if msgs then
            Util.Tables.Call(msgs,
                    function(line)
                        self.frame.msg:AddMessage(line, 1.0, 1.0, 1.0, nil, false)
                    end
            )
        end
        ---- now set logging to emit to frame
        Log:SetWriter(function(msg) self.frame.msg:AddMessage(msg) end)
    end
end

function Logging:Toggle()
    if self.frame then
        if self.frame:IsVisible() then
            self.frame:Hide()
        else
            self.frame:Show()
        end
    end
end