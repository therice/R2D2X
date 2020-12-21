--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
local Dialog = AddOn:GetLibrary("Dialog")
--- @type UI.Native
local UI =  AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.DropDown
local DropDown =  AddOn.Require('UI.DropDown')
--- @type Models.Award
local Award = AddOn.Package('Models').Award
--- @type Models.Subject
local Subject = AddOn.Package('Models').Subject
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type Models.Date
local Date = AddOn.Package('Models').Date
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat

--- @type Standings
local Standings = AddOn:GetModule("Standings", true)

local RightClickMenu, FilterMenu
local ScrollColumns =
        STColumnBuilder()
                :column(""):width(20)                                                                   -- class (1)
                :column(_G.NAME):width(120):defaultsort(STColumnBuilder.Ascending)                      -- name (2)
                :column(_G.RANK):width(120):defaultsort(STColumnBuilder.Ascending):sortnext(6)          -- rank (3)
                    :comparesort(ST.SortFn(function(row) return row.entry.rankIndex end))
                :column(L["ep_abbrev"]):width(60):defaultsort(STColumnBuilder.Descending):sortnext(5)   -- ep (4)
                :column(L["gp_abbrev"]):width(60):defaultsort(STColumnBuilder.Descending):sortnext(2)   -- gp (5)
                :column(L["pr_abbrev"]):width(60):sort(STColumnBuilder.Descending):sortnext(4)          -- pr (6)
                :build()

function Standings:GetFrame()
    if not self.frame then
        RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.StandingsRightClick, UIParent)
        FilterMenu = MSA_DropDownMenu_Create(C.DropDowns.StandingsFilter, UIParent)
        MSA_DropDownMenu_Initialize(RightClickMenu, self.RightClickMenu, "MENU")
        MSA_DropDownMenu_Initialize(FilterMenu, self.FilterMenu)

        local frame = UI:NewNamed('Frame', UIParent, 'Standings', 'Standings', L['frame_standings'], 350, 600)
        local st = ST.New(ScrollColumns, 20, 25, nil, frame)
        st:RegisterEvents({
            -- https://www.wowace.com/projects/lib-st/pages/ui-events
            -- function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            ["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
                if button == C.Buttons.Right and row then
                    RightClickMenu.name = data[realrow].name
                    RightClickMenu.entry = data[realrow].entry
                    DropDown.ToggleMenu(1, RightClickMenu, cellFrame)
                elseif button == "LeftButton" and row then
                    -- data : the information provided to SetData()
                    -- row : index of the row that the event was triggered for
                    -- realrow : exact index (after sorting and filtering) that the event was triggered for
                    --
                    -- local celldata = data[realrow].cols[column]
                    MI.Update(frame, data, realrow)
                end
                return false
            end,
            ["OnEnter"] = function(_, _, data, _, row, realrow, _, _, _, ...)
                if row then
                    MI.Update(frame, data, realrow)
                end
                return false
            end,
            ["OnLeave"] = function()
                MI.Update(frame, nil, nil)
                return false
            end
        })
        st:SetFilter(Standings.FilterFunc)
        st:EnableSelection(true)

        MI.EmbedWidgets(self:GetName(), frame, MI.UpdateMoreInfoWithLootStats)

        local close = UI:NewNamed('Button', frame.content, "Close")
        close:SetText(_G.CLOSE)
        close:SetPoint("RIGHT", frame.moreInfoBtn, "LEFT", -10, 0)
        close:SetScript("OnClick", function() self:Disable() end)
        frame.close = close

        local filter = UI:NewNamed('Button', frame.content, "Filter")
        filter:SetText(_G.FILTER)
        filter:SetPoint("RIGHT", frame.close, "LEFT", -10, 0)
        filter:SetScript("OnClick", function(self) DropDown.ToggleMenu(1, FilterMenu, self) end )
        frame.filter = filter

        local decay = UI:NewNamed('Button', frame.content, "Decay")
        decay:SetText(L["decay"])
        decay:SetPoint("RIGHT", frame.filter, "LEFT", -10, 0)
        if not (AddOn:DevModeEnabled() or CanEditOfficerNote()) then decay:Disable() end
        decay:SetScript("OnClick", function() self:GetDecayFrame().Update() end)
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

        self.frame.st:SetData(self.frame.rows)
    end
end

function Standings:Update(force)
    force = Util.Objects.Default(force, false)
    Logging:Trace("Update(%s)", tostring(force or false))

    if not force and not self.alarm:Fired() then
        return
    end

    if not self:IsEnabled() then return end
    if not self.frame then return end
    self.frame.st:SortData()
end

function Standings.FilterFunc(table, row)
    local settings = AddOn:ModuleSettings(Standings:GetName())
    if not settings.filters then return true end

    local filters, name = settings.filters, row.name
    local subject = Standings:GetEntry(name)

    -- Logging:Debug("FilterFunc : %s", Util.Objects.ToString(subject:toTable()))

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
            include = subject.ep >= AddOn:EffortPointsModule().db.profile.ep_min
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

        for _, class in pairs(classes) do
            info = MSA_DropDownMenu_CreateInfo()
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

        -- including GUILD doesn't make sense here, displayed rows are implicitly in the guild
        for _, what in pairs({_G.PARTY, _G.RAID}) do
            info = MSA_DropDownMenu_CreateInfo()
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

        -- todo : add section for (de)select all
        --[[
	        info.text = "Deselect All"
			info.notCheckable = true
			info.keepShownOnClick = true
			info.func = function()
				for k in pairs(db.modules["RCLootHistory"].filters.class) do
					db.modules["RCLootHistory"].filters.class[k] = false
					MSA_DropDownMenu_SetSelectedName(filterMenu, addon.classIDToDisplayName[k], false)
					useClassFilters = false
					LootHistory:Update()
				end
			end
			MSA_DropDownMenu_AddButton(info, level)
        --]]
    end
end

Standings.RightClickEntries =
    DropDown.EntryBuilder()
            :nextlevel()
                :add():text('Adjust'):checkable(false):arrow(true):value('ADJUST')
            :nextlevel()
                :add():text(UIUtil.SubjectTypeDecorator(Award.SubjectType.Guild)
                    :decorate(_G.GUILD)):checkable(false):arrow(true):value(Award.SubjectType.Guild)
                :add():text(UIUtil.SubjectTypeDecorator(Award.SubjectType.Raid)
                    :decorate(_G.GROUP)):checkable(false):arrow(true):value(Award.SubjectType.Raid)
                :add():text(
                        function(name, entry)
                            return UIUtil.ClassColorDecorator(entry.class):decorate(AddOn.Ambiguate(name))
                        end
                    ):checkable(false):arrow(true):value(Award.SubjectType.Character)
            :nextlevel()
                :add():text(UIUtil.ResourceTypeDecorator(Award.ResourceType.Ep):decorate(L["ep_abbrev"]))
                    :checkable(false):arrow(false)
                    :fn(function(_, entry)
                            Standings:AdjustAction(MSA_DROPDOWNMENU_MENU_VALUE, Award.ResourceType.Ep, entry)
                        end
                    )
                :add():text(UIUtil.ResourceTypeDecorator(Award.ResourceType.Gp):decorate(L["gp_abbrev"]))
                   :checkable(false):arrow(false)
                    :fn(
                        function(_, entry)
                            Standings:AdjustAction(MSA_DROPDOWNMENU_MENU_VALUE, Award.ResourceType.Gp, entry)
                        end
                    )
            :build()


Standings.RightClickMenu = DropDown.RightClickMenu(
        function() return AddOn:DevModeEnabled() or CanEditOfficerNote() end,
        Standings.RightClickEntries
)

local function EmbedErrorTooltip(f)
    f.errorTooltip = UI:NewNamed('GameTooltip', f, 'ErrorTooltip')
    f.UpdateErrorTooltip = function(errors)
        local tip = f.errorTooltip
        tip:SetOwner(f, "ANCHOR_LEFT")
        tip:AddLine(UIUtil.ColoredDecorator(0.77, 0.12, 0.23):decorate(L["errors"]))
        tip:AddLine(" ")
        local errorDeco = UIUtil.ColoredDecorator(1, 0.96, 0.41)
        for _, error in pairs(errors) do
            tip:AddLine(errorDeco:decorate(error))
        end
        tip:Show()
        tip:SetAnchorType("ANCHOR_LEFT", 0, -tip:GetHeight())
    end
end

function Standings:GetAdjustFrame()
    if not self.adjustFrame then
        local f = UI:NewNamed('Frame', UIParent, 'AdjustPoints', 'Standings', L['frame_adjust_points'], 230, 275)
        f:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -150)

        local name = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("CENTER", f.content, "TOP", 0, -30)
        name:SetText("...")
        f.name = name

        local rtLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rtLabel:SetPoint("TOPLEFT", f.content, "TOPLEFT", 15, -45)
        rtLabel:SetText(L["resource_type"])
        f.rtLabel = rtLabel

        local resourceType =
            AceUI('Dropdown')
                .SetPoint("TOPLEFT", f.rtLabel, "BOTTOMLEFT", 0, -5)
                .SetParent(f)()
        local values = Util(Award.TypeIdToResource):Copy()()
        resourceType:SetList(values)
        f.resourceType = resourceType

        local atLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        atLabel:SetPoint("TOPLEFT", f.rtLabel, "TOPLEFT", 0, -45)
        atLabel:SetText(L["action_type"])
        f.atLabel = atLabel

        local actionType =
            AceUI('Dropdown')
                .SetPoint("TOPLEFT", f.resourceType.frame, "BOTTOMLEFT", 0, -20)
                .SetParent(f)()
        local actions = Util(Award.TypeIdToAction):Copy()()
        tremove(actions, Award.ActionType.Decay)
        actionType:SetList(actions)
        f.actionType = actionType

        local qtyLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        qtyLabel:SetPoint("TOPLEFT", f.atLabel, "TOPLEFT", 0, -45)
        qtyLabel:SetText(L["quantity"])
        f.qtyLabel = qtyLabel

        local quantity = UI:New("EditBox", f.content)
        quantity:SetHeight(25)
        quantity:SetWidth(100)
        quantity:SetPoint("TOPLEFT", f.actionType.frame , "BOTTOMLEFT", 3, -23)
        quantity:SetPoint("TOPRIGHT", f.actionType.frame , "TOPRIGHT", -6, 0)
        quantity:SetNumeric(true)
        f.quantity = quantity

        local descLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descLabel:SetPoint("TOPLEFT", f.qtyLabel, "TOPLEFT", 0, -48)
        descLabel:SetText(L["description"])
        f.descLabel = descLabel

        local desc = UI:New("EditBox", f.content)
        desc:SetHeight(25)
        desc:SetWidth(100)
        desc:SetPoint("TOPLEFT", f.quantity, "BOTTOMLEFT", 0, -23)
        desc:SetPoint("TOPRIGHT", f.quantity, "TOPRIGHT",  0, 0)
        f.desc = desc

        local close = UI:New('Button', f.content)
        close:SetText(_G.CANCEL)
        close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 7)
        close:SetScript("OnClick",
                function()
                    if f.errorTooltip then f.errorTooltip:Hide() end
                    if f.subjectTooltip then f.subjectTooltip:Hide() end
                    f:Hide()
                end)
        f.close = close

        local adjust = UI:New('Button', f.content)
        adjust:SetText(L["adjust"])
        adjust:SetPoint("RIGHT", f.close, "LEFT", -10, 0)
        adjust:SetScript("OnClick",
                function()
                    local award, validationErrors = f.Validate()
                    if Util.Tables.Count(validationErrors) ~= 0 then
                        f.UpdateErrorTooltip(validationErrors)
                    else
                        f.errorTooltip:Hide()
                        Dialog:Spawn(AddOn.Constants.Popups.ConfirmAdjustPoints, award)
                    end
                end
        )
        f.adjust = adjust

        EmbedErrorTooltip(f)

        f.subjectTooltip = UI:NewNamed('GameTooltip', f, 'SubjectTooltip')
        f.UpdateSubjectTooltip = function(subjects)
            local tip = f.subjectTooltip
            tip:SetOwner(f, "ANCHOR_LEFT")
            tip:AddLine(UIUtil.ColoredDecorator(1, 1, 1):decorate(L["characters"]))
            tip:AddLine(" ")

            for _, subject in pairs(subjects) do
                tip:AddLine(
                    UIUtil.ClassColorDecorator(subject[2]):decorate(subject[1])
                )
            end
            tip:Show()
            tip:SetAnchorType("ANCHOR_LEFT", 0, -tip:GetHeight())
        end

        f.Validate = function()
            local validationErrors = {}
            local award = Award()

            local subject = f.name:GetText()
            if Util.Strings.IsEmpty(subject) then
                Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["name"]))
            else
                local subjectType = tonumber(f.subjectType)
                if Util.Objects.IsEmpty(subjectType) then
                    Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["subject"]))
                elseif subjectType== Award.SubjectType.Character then
                    award:SetSubjects(subjectType, subject)
                else
                    if f.subjects and Util.Tables.Count(f.subjects) ~= 0 then
                        local subjects =
                            Util(f.subjects):Map(
                                function(subject)
                                    return AddOn:UnitName(subject[1])
                                end
                            ):Copy()()
                        award:SetSubjects(subjectType, unpack(subjects))
                    else
                        award:SetSubjects(subjectType)
                    end
                end
            end

            local actionType = f.actionType:GetValue()
            if Util.Objects.IsEmpty(actionType) or not Util.Objects.IsNumber(actionType) then
                Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["action_type"]))
            else
                award:SetAction(tonumber(actionType))
            end

            local setResource = true
            local resourceType = f.resourceType:GetValue()
            if Util.Objects.IsEmpty(resourceType) or not Util.Objects.IsNumber(resourceType) then
                Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["resource_type"]))
                setResource = false
            end

            local quantity = f.quantity:GetText()
            if Util.Objects.IsEmpty(quantity) or not Util.Strings.IsNumber(quantity) then
                Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["quantity"]))
                setResource = false
            end

            if setResource then award:SetResource(tonumber(resourceType), tonumber(quantity)) end

            local description = f.desc:GetText()
            if Util.Strings.IsEmpty(description) then
                Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["description"]))
            else
                award.description = description
            end

            return award, validationErrors
        end

        f.Update = function(subjectType, resourceType, subjects)
            Logging:Trace('Update(%d, %d) : %s', subjectType, resourceType, Util.Objects.ToString(subjects))

            local subjectColor, text

            if subjectType == Award.SubjectType.Character then
                local subject = subjects[1][1]
                subjectColor = UIUtil.GetPlayerClassColor(subject)
                text = subject
            else
                subjectColor = UIUtil.GetSubjectTypeColor(subjectType)
                text = Award.TypeIdToSubject[subjectType]
            end

            if subjectType ~= Award.SubjectType.Character and Util.Objects.IsTable(subjects) then
                f.subjects = subjects

                text = text .. "(" .. Util.Tables.Count(subjects) .. ")"
                f.UpdateSubjectTooltip(
                    Util(subjects)
                            :Sort(function (a, b) return a[1] < b[1] end)
                            :Map(function(e) return { AddOn.Ambiguate(e[1]), e[2] } end)
                            :Copy()()
                )
            else
                f.subjectTooltip:Hide()
                f.subjects = nil
            end

            f.subjectType = subjectType

            f.name:SetText(text)
            f.name:SetTextColor(subjectColor.r, subjectColor.g, subjectColor.b, subjectColor.a)

            f.resourceType:SetValue(resourceType)
            f.resourceType:SetText(Award.TypeIdToResource[resourceType]:upper())

            f.actionType:SetValue(nil)
            f.actionType:SetText(nil)

            f.quantity:SetText('')
            f.desc:SetText('')

            if not f:IsVisible() then f:Show() end
        end

        self.adjustFrame = f
    end

    return self.adjustFrame
end

-- all 3 parameters are passed, but entry may not be applicable based upon subjectType
function Standings:AdjustAction(subjectType, resourceType, entry)
    Logging:Trace("AdjustAction() : %d, %d, %s", tostring(subjectType), tostring(resourceType), type(entry))

    local subjects
    -- plain table, expect input to be a table of tables of format {{PLAYER, CLASS}, {...}}
    if Util.Objects.IsTable(entry) and not entry.clazz then
        subjects = entry
    -- an individual subject, convert to expected format
    elseif entry:isInstanceOf(Subject) then
        subjects = {{entry.name, entry.classTag}}
    else
        error("cannot handle entry of type : " .. type(entry))
    end

    self:GetAdjustFrame().Update(subjectType, resourceType, subjects)
end

--- @param entry Models.History.Traffic
function Standings:AmendAction(entry)
    -- i think it should be fine to apply revert to guild/raid, we have the list of subjects
    --[[
    if entry.subjectType == Award.SubjectType.Character then
        error("Unsupported subject type for amending an award : " .. Award.TypeIdToSubject[entry.subjectType])
    end
    --]]

    if not Util.Objects.In(entry.actionType, Award.ActionType.Add, Award.ActionType.Subtract) then
        error("Unsupported resource type for amending an award : " .. Award.TypeIdToAction[entry.actionType])
    end

    self:AdjustAction(entry.subjectType, entry.resourceType, entry.subjects)
    self.adjustFrame.desc:SetText(format(L['amend'] .. " '%s'", entry.description))
end

function Standings.AdjustOnShow(frame, award)
    UIUtil.DecoratePopup(frame)

    local decoratedText
    if award.subjectType == Award.SubjectType.Character then
        local subject = award.subjects[1]
        decoratedText = UIUtil.ClassColorDecorator(subject[2]):decorate(AddOn.Ambiguate(subject[1]))
    else
        decoratedText = UIUtil.SubjectTypeDecorator(award.subjectType):decorate("the " .. award:GetSubjectOriginText())
    end

    -- Are you certain you want to %s %d %s %s %s?
    frame.text:SetText(
            format(L["confirm_adjust_player_points"],
                    Award.TypeIdToAction[award.actionType]:lower(),
                    tostring(award.resourceQuantity),
                    Award.TypeIdToResource[award.resourceType]:upper(),
                    award.actionType == Award.ActionType.Add and "to" or "from",
                    decoratedText
            )
    )
end

function Standings.AdjustOnClickYes(_, award, ...)
    Standings:Adjust(award)
    Standings:HideAdjust()
end

function Standings:GetDecayFrame()
    if not self.decayFrame then
        local f = UI:NewNamed('Frame', UIParent, 'DecayPoints', 'Standings', L['frame_decay_points'], 230, 275)
        f:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -150)

        local rtLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rtLabel:SetPoint("TOPLEFT", f.content, "TOPLEFT", 15, -25)
        rtLabel:SetText(L["resource_type"])
        f.rtLabel = rtLabel

        local resourceType =
            AceUI('Dropdown')
                    .SetPoint("TOPLEFT", f.rtLabel, "BOTTOMLEFT", 0, -5)
                    .SetParent(f)()
        local values = Util(Award.TypeIdToResource):Copy()()
        values[0] = L["all"]
        resourceType:SetList(values)
        -- default to 'All'
        resourceType:SetValue(0)
        f.resourceType = resourceType

        local pctLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pctLabel:SetPoint("TOPLEFT", f.rtLabel, "TOPLEFT", 0, -50)
        pctLabel:SetText(L["percent"])
        f.pctLabel = pctLabel

        local pct =
            AceUI('Slider')
                .SetSliderValues(0, 1, 0.01)
                .SetIsPercent(true)
                .SetValue(.10)
                .SetPoint("TOPLEFT", f.pctLabel, "BOTTOMLEFT")
                .SetParent(f)()
        f.pct = pct

        local descLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descLabel:SetPoint("TOPLEFT", f.pctLabel, "TOPLEFT", 0, -65)
        descLabel:SetText(L["description"])
        f.descLabel = descLabel

        local desc = UI:New("EditBox", f.content)
        desc:SetHeight(25)
        desc:SetWidth(200)
        desc:SetPoint("TOPLEFT", f.descLabel, "BOTTOMLEFT", 0, -15)
        f.desc = desc

        local close = UI:New('Button', f.content)
        close:SetText(_G.CANCEL)
        close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 7)
        close:SetScript("OnClick", function() f:Hide() end)
        f.close = close

        local decay = UI:New('Button', f.content)
        decay:SetText(L["decay"])
        decay:SetPoint("RIGHT", f.close, "LEFT", -10, 0)
        decay:SetScript("OnClick",
                function()
                    local awards, validationErrors = f.Validate()
                    if Util.Tables.Count(validationErrors) ~= 0 then
                        f.UpdateErrorTooltip(validationErrors)
                    else
                        f.errorTooltip:Hide()
                        Dialog:Spawn(AddOn.Constants.Popups.ConfirmDecayPoints, awards)
                    end
                end
        )
        f.decay = decay

        EmbedErrorTooltip(f)

        f.Validate = function()
            local validationErrors, decayAwards = {}, {}
            local  resourceType, pct , description =
                f.resourceType:GetValue(), f.pct:GetValue(), f.desc:GetText()
            local resourceTypes = resourceType == 0 and Util(Award.TypeIdToResource):Keys():Copy()() or {resourceType}

            if Util.Strings.IsEmpty(description) then
                Util.Tables.Push(validationErrors, format(L["x_unspecified_or_incorrect_type"], L["description"]))
            end

            for _, type in pairs(resourceTypes) do
                Logging:Debug("DecayFrame.Validate() : processing resourceType=%d", type)
                local decay
                if #decayAwards == 0 then
                    decay = Award()
                    decay:SetSubjects(Award.SubjectType.Guild)
                    decay:SetAction(Award.ActionType.Decay)
                    decay.description = description
                else
                    decay = Award:reconstitute(decayAwards[#decayAwards]:toTable())
                end

                decay:SetResource(type, pct)
                Util.Tables.Push(decayAwards, decay)
            end

            Logging:Debug("DecayFrame.Validate() : decay entries %s", Util.Objects.ToString(decayAwards, 2))


            return decayAwards, validationErrors
        end

        f.Update = function()
            f.desc:SetText(format(L["decay_on_d"], DateFormat.Short:format(Date())))
            if not f:IsVisible() then f:Show() end
        end

        self.decayFrame = f
    end

    return self.decayFrame
end

function Standings.DecayOnShow(frame, awards)
    UIUtil.DecoratePopup(frame)

    -- just grab one, they will both be the same except
    -- one will be for EP and other for GP
    local award = awards[1]
    local decoratedText = UIUtil.SubjectTypeDecorator(award.subjectType):decorate("the " .. award:GetSubjectOriginText())

    frame.text:SetText(
            format(L["confirm_decay"],
                    #awards == 1 and (award.resourceType == Award.ResourceType.Ep and L["ep_abbrev"] or L["gp_abbrev"]) or L["all_values"],
                    award.resourceQuantity * 100,
                    decoratedText
            )
    )
end

function Standings.DecayOnClickYes(_, awards)
    Logging:Debug("DecayOnClickYes(%d)", #awards)
    Standings:BulkAdjust(Util.Tables.Unpack(awards))
    Standings:HideAdjust()
end

function Standings.RevertOnShow(frame, entry)
    UIUtil.DecoratePopup(frame)

    local decoratedText

    if entry.subjectType == Award.SubjectType.Character then
        local subject = entry.subjects[1]
        decoratedText = UIUtil.ClassColorDecorator(subject[2]):decorate(subject[1])
    else
        decoratedText = UIUtil.SubjectTypeDecorator(entry.subjectType):decorate(Award.TypeIdToSubject[entry.subjectType])
    end

    frame.text:SetText(
            format(L["confirm_revert"],
                   Award.TypeIdToAction[entry.actionType]:lower(),
                   entry.resourceQuantity,
                   Award.TypeIdToResource[entry.resourceType]:upper(),
                   entry.actionType == Award.ActionType.Add and L["to"] or L["from"],
                   decoratedText
            )
    )
end

function Standings.RevertOnClickYes(_, entry)
    Standings:RevertAdjust(entry)
end

function Standings:Hide()
    if self.frame then
        self.frame:Hide()
    end

    self:HideAdjust()
    self:HideDecay()
end

function Standings:HideAdjust()
    if self.adjustFrame then
        self.adjustFrame:Hide()
        self.adjustFrame.errorTooltip:Hide()
        self.adjustFrame.subjectTooltip:Hide()
    end
end

function Standings:HideDecay()
    if self.decayFrame then
        self.decayFrame:Hide()
        self.decayFrame.errorTooltip:Hide()
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

