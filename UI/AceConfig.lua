local _, AddOn = ...
local Logging, Util = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util')
local Attributes, Builder = AddOn.Package('UI.Util').Attributes, AddOn.Package('UI.Util').Builder

local Option = AddOn.Class('Option', Attributes)
function Option:initialize(param, type, name, order)
    Attributes.initialize(
            self, {
                type = type,
                name = name,
                order = order or 0,
            }
    )
    -- param is the key for the configuration table at which option will associated
    self.param = param
end

function Option:named(name) return self:set('name', name) end
function Option:type(type) return self:set('type', type) end
function Option:order(order) return self:set('order', order or 0) end
function Option:desc(desc) return self:set('desc', desc) end

local ConfigBuilder = AddOn.Package('UI.AceConfig'):Class('ConfigBuilder', Builder)
function ConfigBuilder:initialize(options, path)
    Builder.initialize(self, options or {})
    self.path = path or nil
    tinsert(self.embeds, 'args')
    tinsert(self.embeds, 'header')
    tinsert(self.embeds, 'group')
    tinsert(self.embeds, 'toggle')
    tinsert(self.embeds, 'execute')
    tinsert(self.embeds, 'description')
    tinsert(self.embeds, 'select')
end

function ConfigBuilder:_ParameterName( param)
    return self.path and (self.path .. '.' .. param) or param
end

function ConfigBuilder:_InsertPending()
    Util.Tables.Set(self.entries, self.pending.param, self.pending.attrs)
end

function ConfigBuilder:SetPath(path)
    self:_CheckPending()
    self.path = path
    return self
end

function ConfigBuilder:args()
    local path = self.pending and Util.Strings.Join('.', self.pending.param, 'args') or 'args'
    self:_CheckPending()
    Util.Tables.Set(self.entries, path, { })
    self.path = path
    return self
end

function ConfigBuilder:entry(class, param, ...)
    return Builder.entry(self, class, self:_ParameterName(param), ...)
end

function ConfigBuilder:header(param, name)
    return self:entry(Option, param, 'header', name)
end

function ConfigBuilder:group(param, name)
    return self:entry(Option, param, 'group', name)
end

function ConfigBuilder:toggle(param, name)
    return self:entry(Option, param, 'toggle', name)
end

function ConfigBuilder:execute(param, name)
    return self:entry(Option, param, 'execute', name)
end

function ConfigBuilder:description(param, name)
    return self:entry(Option, param, 'description', name):set('fontSize', 'medium')
end

function ConfigBuilder:select(param, name)
    return self:entry(Option, param, 'select', name)
end