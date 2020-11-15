local _, AddOn = ...
local Logging, Util = AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util')

local Package = AddOn.Package('UI')
local AceConfigOption = Package:Class('AceConfigOption')
local AceConfigBuilder = Package:Class('AceConfigBuilder')

function AceConfigOption:initialize(builder, param, type, name, order)
    self.builder = builder
    -- param is the key for the configuration table at which option will associated
    self.param = param
    -- attrs are the key/value pairs which define the option
    self.attrs = {
        type = type,
        name = name,
        order = order or 0,
    }
end

function AceConfigOption:set(attr, value)
    self.attrs[attr] = value
    return self
end

function AceConfigOption:named(name) return self:set('name', name) end
function AceConfigOption:type(type) return self:set('type', type) end
function AceConfigOption:order(order) return self:set('order', order or 0) end
function AceConfigOption:desc(desc) return self:set('desc', desc) end

function AceConfigBuilder:initialize(options, path)
    self.options = options or {}
    self.path = path or nil
    self.pending = nil
end

local _Embeds = {
    'build',
    'args',
    'header',
    'group',
    'toggle',
    'execute',
    'description',
    'select',
}

local function _Embed(builder, option)
    for _, method in pairs(_Embeds) do
        option[method] = function(_, ...)
            return builder[method](builder, ...)
        end
    end
    return option
end


local function _ParameterName(self, param)
    return self.path and (self.path .. '.' .. param) or param
end

local function _CheckPending(self)
    if self.pending then
        Util.Tables.Set(self.options, self.pending.param, self.pending.attrs)
        self.pending = nil
    end
end

local function _CreateOption(self, param, ...)
    _CheckPending(self)
    self.pending = _Embed(self, AceConfigOption(self, _ParameterName(self, param), ...))
    return self.pending
end


function AceConfigBuilder:SetPath(path)
   _CheckPending(self)
    self.path  = path
    return self
end

function AceConfigBuilder:args()
    local path = self.pending and Util.Strings.Join('.', self.pending.param, 'args') or 'args'
    _CheckPending(self)
    Util.Tables.Set(self.options, path, { })
    self.path = path
    return self
end

function AceConfigBuilder:header(param, name)
    return _CreateOption(self, param, 'header', name)
end

function AceConfigBuilder:group(param, name)
    return _CreateOption(self, param, 'group', name)
end

function AceConfigBuilder:toggle(param, name)
    return _CreateOption(self, param, 'toggle', name)
end

function AceConfigBuilder:execute(param, name)
    return _CreateOption(self, param, 'execute', name)
end

function AceConfigBuilder:description(param, name)
    return _CreateOption(self, param, 'description', name):set('fontSize', 'medium')
end

function AceConfigBuilder:select(param, name)
    return _CreateOption(self, param, 'select', name)
end

function AceConfigBuilder:build()
    _CheckPending(self)
    return self.options
end
