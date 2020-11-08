-- params is for passing functions directly to TestSetup in advance of loading files
-- [1] - Boolean indicating if entrire AddOn should be loaded
-- [2] - Table of pre-hook functions
local params = {...}

local pl = require('pl.path')
local logFile, caller = nil, pl.abspath(pl.abspath('.') .. '/' .. debug.getinfo(2, "S").source:match("@(.*)$"))

function Before()
    local path = pl.dirname(caller)
    local name = pl.basename(caller):match("(.*).lua$")
    logFile = io.open(pl.abspath(path) .. '/' .. name .. '.log', 'w')
    -- print("Caller -> FILE(" .. caller .. ") PATH(" .. path .. ") NAME(" .. name .. ")")
end

function After()
    if logFile then
        logFile:close()
        logFile = nil
    end
end

Before()

local thisDir = pl.abspath(debug.getinfo(1).source:match("@(.*)/.*.lua$"))
if params[1] then
    local toc = pl.abspath(thisDir .. '/../R2D2X.toc')
    print('Loading -> ' .. toc)
    loadfile(thisDir .. '/WowAddonParser.lua')()
    TestSetup(toc, params[2] or {})
else
    loadfile('Libs/LibStub/LibStub.lua')()
end