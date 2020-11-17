local _, AddOn = ...
local Util, Logging, ItemUtil, GuildStorage =
    AddOn:GetLibrary("Util"), AddOn:GetLibrary("Logging"), AddOn:GetLibrary("ItemUtil"), AddOn:GetLibrary("GuildStorage")
local Subject, Award = AddOn.Package('Models'):Class('Subject'), AddOn.Package('Models'):Class('Award')

local function MinimumGp()
    local GP = AddOn:GearPointsModule()
    return GP.db and GP.db.profile.gp_min or 1
end

local function NormalizeGp(gp)
    return math.max(gp, MinimumGp())
end

local function DecodeNode(note)
    if Util.Objects.IsSet(note) then
        local ep, gp = string.match(note, "^(%d+),(%d+)$")
        if ep and gp then
            return tonumber(ep), NormalizeGp(gp)
        end
    end
    return 0, MinimumGp()
end

local function EncodeNote(ep, gp)
    return string.format("%d,%d", math.max(ep, 0), NormalizeGp(gp))
end

function Subject:initialize(
        name, class, rank, rankIndex, ep, gp
)
    self.name = name
    if Util.Objects.IsEmpty(class) then
        error("Must specify 'class' (either display name or upper-case name)")
    end

    if not Util.Objects.IsNumber(ep) then error("Must specify 'ep' as number") end
    if not Util.Objects.IsNumber(gp) then error("Must specify 'gp' as number") end

    --[[
    https://wowwiki.fandom.com/wiki/API_GetGuildRosterInfo
        class can be either of the following formats, which will then be handled to provide class and classFileName
            class : String - The class (Mage, Warrior, etc) of the player.
            classFileName  String - Upper-case English classname - localisation independent.
        rank : String - The member's rank in the guild ( Guild Master, Member ...)
        rankIndex : Number - The number corresponding to the guild's rank. The Rank Index starts at 0, add 1 to correspond with the index used in GuildControlGetRankName(index)
    --]]

    -- if all upper case, assume it's the classFileName attribute
    if Util.Strings.IsUpper(class) then
        self.classId = ItemUtil.ClassTagNameToId[class]
        self.class = ItemUtil.ClassIdToDisplayName[self.classId]
        self.classTag = class
        -- otherwise, assume it's the class attribute
    else
        self.classId = ItemUtil.ClassDisplayNameToId[class]
        self.class = class
        self.classTag = ItemUtil.ClassIdToFileName[self.classId]
    end

    self.rank = rank or ""
    self.rankIndex = rankIndex or nil
    self.ep = ep
    self.gp = NormalizeGp(gp)
end

-- bridge from LibGuildStorage instance
function Subject:FromGuildMember(member)
    local ep, gp = DecodeNode(member.officerNote)
    return Subject:new(member.name, member.class, member.rank, member.rankIndex, ep, gp)
end

function Subject:GetPR()
    return Util.Numbers.Round(self.ep / NormalizeGp(self.gp), 2)
end

function Subject:Points()
    return self.ep, self.gp, self:GetPR()
end

function Subject:ToNote()
    return EncodeNote(self.ep, self.gp)
end

local ActionType = {
    Add      = 1,
    Subtract = 2,
    Reset    = 3,
    Decay    = 4,
}

local SubjectType = {
    Character = 1, -- one or more named characters
    Guild     = 2, -- guild members
    Raid      = 3, -- raid members
    Standby   = 4, -- standby/bench members
}

local ResourceType = {
    Ep  = 1,
    Gp  = 2,
}

Award.ActionType = ActionType
Award.TypeIdToAction = tInvert(ActionType)

Award.SubjectType = SubjectType
Award.TypeIdToSubject = tInvert(SubjectType)

Award.ResourceType = ResourceType
Award.TypeIdToResource = tInvert(ResourceType)

function Award:initialize(data)
    -- if data was specified, and not a table
    if data and not Util.Objects.IsTable(data) then
        error("the specified data was not of the appropriate type : " .. type(data))
    end

    -- the type of performed award
    self.actionType = data and data.actionType or nil
    -- the type of the subject on which award was performed
    self.subjectType = data and data.subjectType or nil
    -- the subjects of the award
    self.subjects = data and data.subjects or nil
    -- the type of the resource, for specified subject, on which award was performed
    self.resourceType = data and data.resourceType or nil
    -- the quantity of the award
    self.resourceQuantity = data and data.resourceQuantity or nil
    -- an optional description of award
    self.description = data and data.description or nil
    -- in the case of award being associated with an item, this will be set
    -- if set, will be of type ItemAward
    self.item = nil
end

function Award:GetSubjectOriginText()
    local text = Award.TypeIdToSubject[self.subjectType]
    local subjectCount = Util.Tables.Count(self.subjects)

    if self.subjectType ~= Award.SubjectType.Character and subjectCount ~= 0 then
        text = text .. "(" .. subjectCount .. ")"
    end

    return text
end

function Award:SetAction(type)
    if not Util.Tables.ContainsValue(ActionType, type) then
        error("Invalid Action Type specified")
    end

    self.actionType = type
end

function Award:SetResource(type, quantity)
    -- you don't have to specify a resource type if already set
    if Util.Objects.IsSet(type) then
        if not Util.Tables.ContainsValue(ResourceType, type) then error("Invalid Resource Type specified") end
        self.resourceType = type
    end

    if not Util.Objects.IsNumber(quantity) then error("Resource Quantity must be a number") end

    self.resourceQuantity = quantity
end

function Award:SetSubjects(type, ...)
    if not Util.Tables.ContainsValue(SubjectType, type) then error("Invalid Subject Type specified") end
    -- Logging:Debug("SetSubjects(%s)", tostring(type))
    self.subjectType = type
    if self.subjectType == SubjectType.Character or self.subjectType == SubjectType.Standby then
        local subjects = Util.Tables.New(...)
        self.subjects =  Util.Tables.Map(
                subjects,
                function (c) return AddOn:UnitName(c) end
        )
    else
        local subjects = Util.Tables.New(...)
        -- Logging:Debug("SetSubjects() : current subject count is %d, %s", Tables.Count(subjects), Objects.ToString(subjects))
        if Util.Tables.Count(subjects) == 0 then
            if self.subjectType == SubjectType.Guild then
                for name, _ in pairs(GuildStorage:GetMembers()) do
                    -- Logging:Debug("Adding %s", name)
                    Util.Tables.Push(subjects, name)
                end
            elseif self.subjectType == SubjectType.Raid then
                --[[
                    GetInstanceInfo() in IronForge (not in group/raid and not in an instance/dungeon)

                    #{GetInstanceInfo()} == 9

                    'Eastern Kingdoms' (zoneName)
                    none (instanceType)
                    0 (difficultyID)
                    0 (difficultyName)
                    0 (maxPlayers)
                    false (dynamicDifficulty)
                    0 (isDynamic)
                    0 (instanceMapID)
                    nil (instanceGroupSize)

                    https://wowwiki.fandom.com/wiki/API_GetInstanceInfo

                    zoneName, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty,
                        isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()

                --]]
                local instanceName, _, _, _, _, _, _, instanceId = GetInstanceInfo()
                Logging:Debug("SetSubjects() : instanceName=%s instanceId=%s", tostring(instanceName), tostring(instanceId))

                for i = 1, GetNumGroupMembers() do
                    -- the returned player name won't have realm, so convert using UnitName
                    -- https://wow.gamepedia.com/API_GetRaidRosterInfo
                    local name, _, _, _, _, _, zone, online = GetRaidRosterInfo(i)
                    Logging:Debug("SetSubjects(%s) : online=%s zone=%s", tostring(name), tostring(online), tostring(zone))
                    -- until 'in the zone' check can be addressed, only check if player is online
                    if not online then
                        Logging:Warn("SetSubjects(%s) : omitting from award, online=%s zone=%s",
                                tostring(name), tostring(online), tostring(zone)
                        )
                    else
                        Util.Tables.Push(subjects, AddOn:UnitName(name))
                    end
                end
            end
        end

        if Util.Tables.Count(subjects) == 0 then
            Logging:Warn("SetSubjects(%d) : no subjects could be discovered", self.subjectType)
        end

        self.subjects = subjects
    end

    --Logging:Debug("%s", Util.Objects.ToString(self.subjects))
    -- todo
    Util.Tables.Map(self.subjects, function(subject)
        Logging:Debug("%s => %s", subject, tostring(AddOn:UnitClass(subject) or "UNKNOWN"))
        return {subject, AddOn:UnitClass(subject)}
    end)
    --Logging:Debug("%s", Util.Objects.ToString(self.subjects))
end