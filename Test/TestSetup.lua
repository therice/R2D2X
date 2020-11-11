-- params is for passing functions directly to TestSetup in advance of loading files
-- [1] - Boolean indicating if entire AddOn should be loaded
-- [2] - Namespace for establishing global for testing flag
-- [3] - Table of pre-hook functions (for addon loading)
-- [4] - Table of post-hook functions (for addon loading)
local params = {...}
local pl = require('pl.path')
local addOnTestNs, testNs, loadAddon, logFile, caller =
    'R2D2X_Testing', nil, nil, nil, pl.abspath(pl.abspath('.') .. '/' .. debug.getinfo(2, "S").source:match("@(.*)$"))

loadAddon = params[1] or false

function Before()
    local path = pl.dirname(caller)
    local name = pl.basename(caller):match("(.*).lua$")
    testNs = (params[2] or name) .. '_Testing'
    _G[testNs] = true
    logFile = io.open(pl.abspath(path) .. '/' .. name .. '.log', 'w')
    _G[addOnTestNs .. '_GetLogFile'] = function() return logFile end
    _G[addOnTestNs] = true
    _G.print_orig = _G.print
    _G.print = function(...)
        logFile:write(name .. ': ')
        logFile:write(...)
        logFile:write('\n')
    end

    print(testNs .. ' -> true')
    print(addOnTestNs .. ' -> true')
    print("Caller -> FILE(" .. caller .. ") PATH(" .. path .. ") NAME(" .. name .. ")")
end

function ConfigureLogging()
    local success, result = pcall(
            function()
                local Logging, _ = LibStub('LibLogging-1.0')
                Logging:SetRootThreshold(Logging.Level.Trace)
                Logging:SetWriter(
                        function(msg)
                            _G[addOnTestNs .. '_GetLogFile']():write(msg, '\n')
                        end
                )
            end
    )
    if not success then
        print('Logging configuration failed, not all logging will be written to log file -> ' .. tostring(result))
    end
end

function ResetLogging()
    pcall(
            function()
                local Logging, _ = LibStub('LibLogging-1.0')
                Logging:ResetWriter()
            end
    )
end

function After()
    if logFile then
        logFile:close()
        logFile = nil
    end
    _G[testNs] = nil
    _G[addOnTestNs] = nil
    _G[addOnTestNs .. '_GetLogFile'] = nil
    _G.print = _G.print_orig
    ResetLogging()
end


Before()


local thisDir = pl.abspath(debug.getinfo(1).source:match("@(.*)/.*.lua$"))
local wowApi = thisDir .. '/WowApi.lua'
loadfile(wowApi)()

local name, addon

if loadAddon then
    local toc = pl.abspath(thisDir .. '/../R2D2X.toc')
    print('Loading TOC @ ' .. toc)
    loadfile('Test/WowAddonParser.lua')()
    name, addon = TestSetup(toc, params[3] or {}, params[4] or {})
else
    loadfile('Libs/LibStub/LibStub.lua')()
    name, addon = "AddOnName", {}
end

return name, addon