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
    -- print(testNs .. ' -> true')
    _G[testNs] = true
    logFile = io.open(pl.abspath(path) .. '/' .. name .. '.log', 'w')
    if loadAddon then
        _G[addOnTestNs] = true
        _G[addOnTestNs .. '_GetLogFile'] = function() return logFile end
    end
    -- print("Caller -> FILE(" .. caller .. ") PATH(" .. path .. ") NAME(" .. name .. ")")
end

function After()
    if logFile then
        logFile:close()
        logFile = nil
    end
    _G[testNs] = nil
    _G[addOnTestNs] = nil
end

Before()

local thisDir = pl.abspath(debug.getinfo(1).source:match("@(.*)/.*.lua$"))
local wowApi = thisDir .. '/WowApi.lua'
loadfile(wowApi)()

if loadAddon then
    local toc = pl.abspath(thisDir .. '/../R2D2X.toc')
    -- print('Loading TOC @ ' .. toc)
    loadfile('Test/WowAddonParser.lua')()
    return TestSetup(toc, params[3] or {}, params[4] or {})
else
    loadfile('Libs/LibStub/LibStub.lua')()
    return "AddOnName", {}
end