local _, AddOn = ...
local Models = AddOn.ImportPackage('Models')
local Date, DateFormat, SemanticVersion = Models.Date, Models.DateFormat, Models.SemanticVersion

local counter, fullDf, shortDf = 0, DateFormat:new("mm/dd/yyyy HH:MM:SS"), DateFormat("mm/dd/yyyy")

local function counterGetAndIncr()
    local value = counter
    counter = counter + 1
    return value
end

local History = AddOn.Package('Models.History'):Class('History')
function History:initialize(instant)
    -- all timestamps will be in UTC/GMT and require use cases to convert to local TZ
    local di = instant and Date(instant) or Date('utc')
    -- for versioning history entries, this is independent of add-on version
    self.version = SemanticVersion(1, 0)
    -- unique identifier should multiple instances be created at same instant
    self.id = di.time .. '-' .. counterGetAndIncr()
    self.timestamp = di.time
end

function History:TimestampAsDate()
    return Date(self.timestamp)
end

function History:afterReconstitute(instance)
    instance.version = SemanticVersion(instance.version)
    return instance
end

-- @return the entry's timestamp formatted in local TZ in format of mm/dd/yyyy HH:MM:SS
function History:FormattedTimestamp()
    return fullDf:format(self.timestamp)
end

-- @return the entry's timestamp formatted in local TZ in format of mm/dd/yyyy
function History:FormattedDate()
    return shortDf:format(self.timestamp)
end

function History:TimestampAsDate()
    return Date(self.timestamp)
end