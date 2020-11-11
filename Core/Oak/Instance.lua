local _, AddOn = ...
local instances = {}

function AddOn.Instance(name, meta, ...)
    assert(name and type(name) == 'string', 'Instance name was not provided')
    assert(meta, format('Instance meta-data not provided for \'%s\'', name))

    if instances[name] then error(format("Instance already exists named '%s'", name)) end

    local class
    -- resolve the class
    if type(meta) == 'table' then
        -- package and class names provided
        if meta.pkg and meta.class then
            class = AddOn.ImportPackage(meta.pkg)[meta.class]
        -- meta itself is a class
        elseif meta.clazz then
            class = meta
        -- meta is callable
        elseif getmetatable(meta) and getmetatable(meta).__call ~= nil then
            class = meta
        end
    -- meta is a function
    elseif type(meta) == 'function' then
        class = meta
    end

    if not class then error(format("Could not resolve class for '%s' from meta-data", name)) end

    local instance = class(...)
    instances[name] = instance
    return instance
end

function AddOn.Require(name)
    assert(name and type(name) == "string", 'Instance name was not provided')
    local instance = instances[name]
    if not instance then error(format("Instance '%s' does not exist", name)) end
    return instance
end

if _G.Instance_Testing or _G.R2D2X_Testing then
    function AddOn.DiscardInstances()
        wipe(instances)
    end
end