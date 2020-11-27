--- @type AddOn
local _, AddOn = ...
local L, Logging = AddOn.Locale, AddOn:GetLibrary("Logging")
local C, Comm = AddOn.Constants, AddOn.Require('Core.Comm')

function AddOn:SubscribeToPermanentComms()
    Logging:Debug("SubscribeToPermanentComms(%s)", self:GetName())
    Comm:BulkSubscribe(C.CommPrefixes.Main, {
        [C.Commands.PlayerInfoRequest] = function(data, sender)

        end,
        [C.Commands.PlayerInfo] = function(_, sender)
            Logging:Debug("%s, %s", C.Commands.PlayerInfo, tostring(sender))
        end,
    })
end
