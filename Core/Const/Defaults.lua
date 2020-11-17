local _, AddOn = ...
local Logging = LibStub("LibLogging-1.0")

-- The ['*'] key defines a default table for any key that was not explicitly defined in the defaults.
-- The second magic key is ['**']. It works similar to the ['*'] key, except that it'll also be inherited by all the keys in the same table.
AddOn.Defaults = {
    global = {
      cache = {}
    },
    profile = {
        logThreshold = Logging.Level.Trace,
        minimap = {
            shown       = true,
            locked      = false,
            minimapPos  = 218,
        },
        -- user interface element positioning and scale
        ui = {
            ['**'] = {
                y           = 0,
                x		    = 0,
                point	    = "CENTER",
                scale	    = 1.1,
            },
        },
        -- module specific data storage
        modules = {
            ['*'] = {
                -- by default, following are included
                filters = {
                    ['*'] = true,
                    class = {
                        ['*'] = true,
                    },
                    member_of = {
                        ['*'] = false,
                    },
                    minimums = {
                        ['*'] = false,
                    }
                },
            },
        },
    }
}

AddOn.BaseConfigOptions = {
    name = AddOn.Constants.name,
    type = 'group',
    childGroups = 'tab',
    handler = AddOn,
    get = "GetDbValue",
    set = "SetDbValue",
    args = {

    }
}