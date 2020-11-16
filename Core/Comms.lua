local _, AddOn = ...
local L, Logging = AddOn.Locale, AddOn:GetLibrary("Logging")
local C, Comm = AddOn.Constants, AddOn.Require('Core.Comm')

function AddOn:SubscribeToPermanentComms()
    Logging:Debug("SubscribeToPermanentComms(%s)", self:GetName())
    Comm:BulkSubscribe(C.CommPrefixes.Main, {
        [C.Messages.PlayerInfoRequest] = function(data, sender)

        end,
        [C.Messages.PlayerInfo] = function(_, sender)

        end,
    })
end
