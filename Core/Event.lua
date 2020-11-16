local _, AddOn = ...
local L, Logging, Util, Rx = AddOn.Locale, AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('Rx')
local C, Subject, Events = AddOn.Constants, Rx.rx.Subject, AddOn.Package('Core'):Class('Events')

-- private stuff only for use within this scope
function Events:initialize()
    self.registered = {}
    self.subjects = {}
    self.AceEvent = {}
end

function Events:Subject(event)
    local name = event
    if not self.subjects[name] then
        self.subjects[name] = Subject.create()
    end
    return self.subjects[name]
end

function Events:HandleEvent(event, ...)
    Logging:Debug("HandleEvent(%s) : %s", event, Util.Objects.ToString({...}))
    self:Subject(event):next(event, ...)
end

function Events:RegisterEvent(event)
    Logging:Debug("RegisterEvent(%s)", event)

    if not self.registered[event] then
        Logging:Debug("RegisterEvent(%s) : registering 'self' with AceEvent", event)
        self.registered[event] = true
        self.AceEvent:RegisterEvent(event, function(event, ...) return self:HandleEvent(event, ...) end)
    end
end


-- anything attached to 'Event' will be available via the instance
local Event = AddOn.Instance(
        'Core.Event',
        function()
            return {
                private = Events()
            }
        end
)

AddOn:GetLibrary('AceEvent'):Embed(Event.private.AceEvent)

function Event:Subscribe(event, func)
    assert(Util.Strings.IsSet(event), "'event' was not provided")
    assert(Util.Objects.IsFunction(func), "'func' was not provided")
    Logging:Debug("Subscribe(%s) : %s", tostring(event), Util.Objects.ToString(func))
    self.private:RegisterEvent(event)
    return self.private:Subject(event):subscribe(func)
end

function Event:BulkSubscribe(funcs)
    assert(
            funcs and Util.Objects.IsTable(funcs) and
                    Util.Tables.CountFn(
                            funcs,
                            function(v, k)
                                if Util.Objects.IsString(k) and Util.Objects.IsFunction(v) then return 1 end
                                return 0
                            end,
                            true, false
                    ) == Util.Tables.Count(funcs),
            "each 'func' table entry must be an event(string) to function mapping"
    )

    local subs, idx = {}, 1
    for event, func in pairs(funcs) do
        subs[idx] = self:Subscribe(event, func)
        idx = idx + 1
    end
    return subs
end

