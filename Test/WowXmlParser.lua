local xml2lua = require("xml2lua")
local handler = require("xmlhandler.dom")
local pl = require('pl.path')

function normalize(file)
    return file:gsub('\\', '/')
end

function filename(dir, file)
    return normalize(dir .. '/' .. file)
end

function Load(files, addOnName, addOnNamespace)
    for _, toload in pairs(files) do
        -- print('Loading File @ ' .. toload)
        loadfile(toload)(addOnName or 'TestAddOn', addOnNamespace or {})
    end
end

function ParseXml(file)
    -- print('Parsing File @ ' .. file)
    local wowXmlHandler = handler:new()
    local wowXmlParser = xml2lua.parser(wowXmlHandler)
    wowXmlParser:parse(xml2lua.loadFile(file))
    -- xml2lua.printable(wowXmlHandler.root)
    
    local parsed = {}
    for _, child in pairs(wowXmlHandler.root._children) do
        -- doesn't handle comments, will error out
        if type(child) == 'table' and child['_type'] ~= 'COMMENT' then
            table.insert(parsed, child["_attr"].file)
        end
    end
    return parsed
end

function ParseXmlAndLoad(file, addOnName, addOnNamespace)
    local rootDir = pl.dirname(pl.abspath(file))
    local parsed = ParseXml(file)
    for i, toload in ipairs(parsed) do
        toload = filename(rootDir, toload)
        parsed[i] = toload
    end
    Load(parsed, addOnName, addOnNamespace)
end