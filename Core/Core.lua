local _, AddOn = ...
local L, Logging = AddOn.Locale, AddOn:GetLibrary("Logging")
local C, SlashCommands, Comm, Event =
    AddOn.Constants, AddOn.Require('Core.SlashCommands'), AddOn.Require('Core.Comm'), AddOn.Require('Core.Event')

local function ModeToggle(self, flag)
    if self.mode:Enabled(flag) then self.mode:Disable(flag) else self.mode:Enable(flag) end
end

function AddOn:DevModeEnabled()
    return self.mode:Enabled(C.Modes.Develop)
end

function AddOn:PersistenceModeEnabled()
    return self.mode:Enabled(C.Modes.Persistence)
end

function AddOn:RegisterChatCommands()
    Logging:Debug("RegisterChatCommands(%s)", self:GetName())
    SlashCommands:BulkSubscribe(
            {
                {'config', 'c'},
                L['chat_commands_config'],
                function() AddOn.ToggleConfig() end,
            },
            {
                {'dev'},
                L['chat_commands_dev'],
                function()
                    ModeToggle(self, C.Modes.Develop)
                    self:Print("Development Mode = " .. tostring(self:DevModeEnabled()))
                end,
                true
            },
            {
                {'pm'},
                L['chat_commands_pm'],
                function()
                    ModeToggle(self, C.Modes.Persistence)
                    self:Print("Persistence Mode = " .. tostring(self:PersistenceModeEnabled()))
                end,
                true
            }
    )
end
