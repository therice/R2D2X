-- params is for passing functions directly to TestSetup in advance of loading files
-- [1] - Boolean indicating if entire AddOn should be loaded
-- [2] - Namespace for establishing global for testing flag
-- [3] - Table of pre-hook functions (for addon loading)
-- [4] - Table of post-hook functions (for addon loading)
local params = {...}
local pl = require('pl.path')
local assert = require("luassert")
local say = require("say")
local addOnTestNs, testNs, loadAddon, logFileName, logFile, caller =
    'R2D2X_Testing', nil, nil, nil, nil, pl.abspath(pl.abspath('.') .. '/' .. debug.getinfo(2, "S").source:match("@(.*)$"))

loadAddon = params[1] or false

--
-- custom assertions start
--
local function less(state, arguments)
    return arguments[1] < arguments[2]
end

local function greater(state, arguments)
    return arguments[1] > arguments[2]
end

say:set_namespace("en")
say:set("assertion.less.positive", "Expected %s to be smaller than %s")
say:set("assertion.less.negative", "Expected %s to not be smaller than %s")
assert:register("assertion", "less", less, "assertion.less.positive", "assertion.less.negative")

say:set("assertion.greater.positive", "Expected %s to be greater than %s")
say:set("assertion.greater.negative", "Expected %s to not be greater than %s")
assert:register("assertion", "greater", greater, "assertion.greater.positive", "assertion.greater.negative")
--
-- custom assertions end
--

function Before()
    local path = pl.dirname(caller)
    local name = pl.basename(caller):match("(.*).lua$")
    testNs = (params[2] or name) .. '_Testing'
    _G[testNs] = true
    logFileName = pl.abspath(path) .. '/' .. name .. '.log'
    logFile = io.open(logFileName, 'w')
    _G[addOnTestNs .. '_GetLogFile'] = function() return logFile end
    _G[addOnTestNs] = true
    _G.print_orig = _G.print
    _G.print = function(...)
        logFile:write(name .. ': ')
        logFile:write(...)
        logFile:write('\n')
        logFile:flush()
    end

    print(testNs .. ' -> true')
    print(addOnTestNs .. ' -> true')
    print("Caller -> FILE(" .. caller .. ") PATH(" .. path .. ") NAME(" .. name .. ")")
end

function ConfigureLogging()
    local success, result = pcall(
            function()
                local Logging = LibStub('LibLogging-1.0')
                Logging:SetRootThreshold(Logging.Level.Trace)
                Logging:SetWriter(
                        function(msg)
                            _G[addOnTestNs .. '_GetLogFile']():write(msg, '\n')
                            _G[addOnTestNs .. '_GetLogFile']():flush()
                        end
                )
            end
    )
    if not success then
        print('Logging configuration failed, not all logging will be written to log file -> ' .. tostring(result))
    else
        print('Logging configured -> ' .. tostring(logFileName))
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

local function xpcall_patch()
    -- this is dubious, something strange occurring with Ace3 Libs and invocations of xpcall via unit tests
    -- probably should back this out, but a workaround for now
    _G.xpcallo = _G.xpcall
    _G.xpcall = function(func, err, ...)
        local success, result = _G.pcall(func, ...)
        if not success then
            print('ERROR -> ' .. dump(result))
            error(result)
        end
        return success, result
    end
end

local function xpcall_restore()
    _G.xpcall = _G.xpcallo
    _G.xpcallo = nil
end

function AddOnLoaded(name, enable)
    WoWAPI_FireEvent("ADDON_LOADED", name)
    if enable then
        _G.IsLoggedIn = function() return true end
        WoWAPI_FireEvent("PLAYER_LOGIN")
    end
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

xpcall_patch()
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

xpcall_restore()
return name, addon