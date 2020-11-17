local _, AddOn = ...
local L, C, Logging, Util, ItemUtil =
    AddOn.Locale, AddOn.Constants,
    AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"),
    AddOn:GetLibrary("ItemUtil")
local UI, UIUtil, ST, Award =
    AddOn.Require('UI.Native'), AddOn.Require('UI.Util'),
    AddOn.Require('UI.ScrollingTable'), AddOn.Package('Models').Award
local STColumnBuilder, STCellBuilder =
    AddOn.Package('UI.ScrollingTable').ColumnBuilder, AddOn.Package('UI.ScrollingTable').CellBuilder

local Standings = AddOn:GetModule("Standings", true)

local RightClickMenu, FilterMenu
local ScrollColumns =
        STColumnBuilder()
                :column(""):width(20) -- class (1)
                :column(_G.NAME):width(120):defaultsort(STColumnBuilder.Ascending) -- name (2)
                :column(_G.RANK):width(120):defaultsort(STColumnBuilder.Ascending):sortnext(6)  -- rank (3)
                    :comparesort(ST.SortFn(function(row) return row.entry.rankIndex end))
                :column(L["ep_abbrev"]):width(60):defaultsort(STColumnBuilder.Descending):sortnext(5) -- ep (4)
                :column(L["gp_abbrev"]):width(60):defaultsort(STColumnBuilder.Descending):sortnext(2) -- gp (5)
                :column(L["pr_abbrev"]):width(60):sort(STColumnBuilder.Descending):sortnext(4) -- pr (6)
                :build()

function Standings:BuildFrame()
    if not self.frame then
        RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.StandingsRightClick, UIParent)
        FilterMenu = MSA_DropDownMenu_Create(C.DropDowns.StandingsFilter, UIParent)
        MSA_DropDownMenu_Initialize(RightClickMenu, self.RightClickMenu, "MENU")
        MSA_DropDownMenu_Initialize(FilterMenu, self.FilterMenu)

        local frame = UI:NewNamed('Frame', UIParent, 'StandingsWindow', 'Standings', L['frame_standings'], 350, 600)
        local st = ST.New(ScrollColumns, 20, 25, nil, frame)
        st:SetFilter(Standings.FilterFunc)
        st:EnableSelection(true)

        local close = UI:NewNamed('Button', frame.content, "Close")
        close:SetText(_G.CLOSE)
        close:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -10, -20)
        close:SetScript("OnClick", function() self:Disable() end)
        frame.close = close

        local filter = UI:NewNamed('Button', frame.content, "Filter")
        filter:SetText(_G.FILTER)
        filter:SetPoint("RIGHT", frame.close, "LEFT", -10, 0)
        filter:SetScript("OnClick", function(self) MSA_ToggleDropDownMenu(1, nil, FilterMenu, self, 0, 0) end )
        frame.filter = filter

        local decay = UI:NewNamed('Button', frame.content, "Decay")
        decay:SetText(L["decay"])
        decay:SetPoint("RIGHT", frame.filter, "LEFT", -10, 0)
        if not (AddOn:DevModeEnabled() or CanEditOfficerNote()) then decay:Disable() end
        -- todo : scripts
        -- decay:SetScript("OnClick", function() self:UpdateDecayFrame() end)
        frame.decay = decay

        self.frame = frame
    end

    return self.frame
end

function Standings:BuildData()
    if self.frame then
        self.frame.rows = {}
        local row = 1
        for name, entry in pairs(self.subjects) do
            if Util.Objects.IsTable(entry) then
                self.frame.rows[row] = {
                    num = row,
                    name = name,
                    entry = entry,
                    cols =
                        STCellBuilder()
                            :classIconCell(entry.class)
                            :classColoredCell(AddOn.Ambiguate(name), entry.class)
                            :cell(entry.rank)
                            :cell(entry.ep):color(UIUtil.GetResourceTypeColor(Award.ResourceType.Ep))
                            :cell(entry.gp):color(UIUtil.GetResourceTypeColor(Award.ResourceType.Gp))
                            :cell(entry:GetPR()):color(C.Colors.ItemHeirloom)
                            :build()
                }
                row = row +1
            end
        end

        self.frame.st:SetData(self.frame.rows)
        self.pendingUpdate = false
    end
end

function Standings:Update(force)
    if not self:IsEnabled() then return end
    if self.frame then
        self.frame.st:SortData()
    end
end


function Standings.FilterFunc(table, row)
    local settings = AddOn:ModuleSettings(Standings:GetName())
    if not settings.filters then return true end

    local filters, name = settings.filters, row.name
    local subject = Standings:GetEntry(name)

     Logging:Debug("FilterFunc : %s", Util.Objects.ToString(subject:toTable()))

    local include = true

    -- class wil always be display cased (e.g. Warlock)
    if subject and subject.class then
        if Util.Tables.ContainsKey(filters.class, subject.class) then
            include = filters.class[subject.class]
        end
    end

    if include then
        if not AddOn.UnitIsUnit(subject, 'player') then
            local inGroup, inRaid = IsInGroup(), IsInRaid()
            local shortName = Ambiguate(name, "short")
            -- no need to check 'player', its encompassed by the 'inX' variables
            -- UnitInParty() states it returns nil when not in a party
            -- but it appears to be returning a boolean always (true, false)
            local groupCheck = inGroup and UnitInParty(shortName)
            -- UnitInRaid only returns value when in a raid, then returns a number
            local raidCheck = inRaid and (Util.Objects.IsNil(UnitInRaid(shortName)) and false or true)

            -- in a party -> true, <no value> (map to nil)
            -- in a raid -> true, 2
            -- Logging:Debug("%s -> %s, %s", 'Darkhavoc', tostring(UnitInParty('Darkhavoc')),  tostring(UnitInRaid('Darkhavoc') or nil))
            -- 5 man group -> inGroup = true, inRaid = false
            --  someone in group and raid => true, false/ true, false
            -- raid -> inGroup = true, inRaid = true
            --  someone in group and raid => true, true / true, 2
            --[[
            Logging:Debug("%s -> %s, %s / %s, %s", shortName,
                    tostring(inGroup), tostring(inRaid), tostring(groupCheck), tostring(raidCheck)
            )
            --]]

            for _, check in pairs({_G.PARTY, _G.RAID}) do
                if check == _G.PARTY then
                    include = groupCheck and filters.member_of[check] or not filters.member_of[check]
                else -- check ==  _G.RAID
                    include = raidCheck and filters.member_of[check] or not filters.member_of[check]
                end

                -- Logging:Debug("%s : %s, %s", shortName, check, tostring(include))
                if not include then break end
            end
        end
    end

    if include then
        if Util.Tables.ContainsKey(filters.minimums, 'ep') and filters.minimums['ep'] then
            -- include = member.ep >= AddOn:EffortPointsModule().db.profile.ep_min
        end
    end

    return include
end

function Standings.FilterMenu(_, level)
    local settings = AddOn:ModuleSettings(Standings:GetName())
    if level == 1 then
        if not settings.filters then settings.filters = {} end
        local filters = settings.filters

        local info = MSA_DropDownMenu_CreateInfo()
        info.text = _G.CLASS
        info.isTitle = true
        info.notCheckable = true
        info.disabled = true
        MSA_DropDownMenu_AddButton(info, level)

        local function setfilter(section, value)
            filters[section][value] = not filters[section][value]
            Standings:Update(true)
        end
        -- these will be a table of sorted display class names
        local classes =
            Util(ItemUtil.ClassDisplayNameToId)
                    :Keys()
                    :Filter(AddOn.FilterClassesByFactionFn)
                    :Sort()
                    :Copy()()

        info = MSA_DropDownMenu_CreateInfo()
        for _, class in pairs(classes) do
            info.text = class
            info.colorCode = "|cff" .. UIUtil.GetClassColorRGB(class)
            info.keepShownOnClick = true
            info.func = function() setfilter('class', class) end
            info.checked = filters.class[class]
            MSA_DropDownMenu_AddButton(info, level)
        end

        info = MSA_DropDownMenu_CreateInfo()
        info.text = L["member_of"]
        info.isTitle = true
        info.notCheckable = true
        info.disabled = true
        MSA_DropDownMenu_AddButton(info, level)

        info = MSA_DropDownMenu_CreateInfo()
        -- including GUILD doesn't make sense here, displayed rows are implicitly in the guild
        for _, what in pairs({_G.PARTY, _G.RAID}) do
            info.text = what
            info.keepShownOnClick = true
            info.func = function() setfilter('member_of', what) end
            info.checked = filters.member_of[what]
            MSA_DropDownMenu_AddButton(info, level)
        end

        info = MSA_DropDownMenu_CreateInfo()
        info.text = L["ep_abbrev"]
        info.isTitle = true
        info.notCheckable = true
        info.disabled = true
        MSA_DropDownMenu_AddButton(info, level)

        info = MSA_DropDownMenu_CreateInfo()
        info.text = L["greater_than_min"]
        info.func = function() setfilter('minimums', 'ep') end
        info.checked = filters.minimums['ep']
        MSA_DropDownMenu_AddButton(info, level)
    end
end

--[[
Standings.RightClickEntries = {
    -- level 1
    {
        -- 1 Adjust
        {
            text = "Adjust",
            notCheckable = true,
            hasArrow = true,
            value = "ADJUST"
        },
    },
    -- level 2
    {
        SubjectAdjustLevel:ToMenuOption(),
        GuildAdjustLevel:ToMenuOption(),
        GroupAdjustLevel:ToMenuOption(),
    },
    -- level 3
    {
        -- 1 EP
        {
            text = function()
                return UI.ColoredDecorator(AddOn.GetResourceTypeColor(Award.ResourceType.Ep)):decorate(L["ep_abbrev"])
            end,
            notCheckable = true,
            func = function(_)
                GetAdjustLevel():ChildAction(Award.ResourceType.Ep)
            end,
        },
        -- 2 GP
        {
            text = function()
                return UI.ColoredDecorator(AddOn.GetResourceTypeColor(Award.ResourceType.Gp)):decorate(L["gp_abbrev"])
            end,
            notCheckable = true,
            func = function(_)
                GetAdjustLevel():ChildAction(Award.ResourceType.Gp)
            end,
        },
        -- 3 Rescale
        -- 4 Decay
    }
}
]]--

Standings.RightClickMenu = UIUtil.RightClickMenu(
        function() return AddOn:DevModeEnabled() or CanEditOfficerNote() end,
        {} --Standings.RightClickEntries
)



function Standings:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Standings:Show()
    if self.frame then
        self.frame:Show()
    end
end

function Standings:Toggle()
    if self.frame then
        if self.frame:IsVisible() then self:Hide() else self:Show() end
    end
end

