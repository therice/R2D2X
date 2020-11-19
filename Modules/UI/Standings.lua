local _, AddOn = ...
local L, C, Logging, Util, ItemUtil, Dialog =
    AddOn.Locale, AddOn.Constants,
    AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Util"),
    AddOn:GetLibrary("ItemUtil"), AddOn:GetLibrary("Dialog")
local UI, UIUtil, MI, ST, DropDown =
    AddOn.Require('UI.Native'), AddOn.Require('UI.Util'), AddOn.Require('UI.MoreInfo'),
    AddOn.Require('UI.ScrollingTable'), AddOn.Require('UI.DropDown')
local Award, STColumnBuilder, STCellBuilder =
    AddOn.Package('Models').Award, AddOn.Package('UI.ScrollingTable').ColumnBuilder,
    AddOn.Package('UI.ScrollingTable').CellBuilder
local AceUI = AddOn.Require('UI.Ace')

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
            -- todo (maybe)
            ["OnEnter"] = Util.Functions.Noop,
            ["OnLeave"] = Util.Functions.Noop,
        })
        st:SetFilter(Standings.FilterFunc)
        st:EnableSelection(true)

        MI.EmbedWidgets(self:GetName(), frame, AddOn.UpdateMoreInfo)

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

function Standings:GetAdjustFrame()
    if not self.adjustFrame then
        local f = UI:NewNamed('Frame', UIParent, 'AdjustPoints', 'AdjustPoints', L['frame_adjust_points'], 230, 275)
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
        values[0] = L["all"]
        resourceType:SetList(values)
        resourceType:SetValue(0) -- default to 'All'
        f.resourceType = resourceType

        local atLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        atLabel:SetPoint("TOPLEFT", f.rtLabel, "TOPLEFT", 0, -45)
        atLabel:SetText(L["action_type"])
        f.atLabel = atLabel

        -- todo : remove decay and maybe reseet
        local actionType =
            AceUI('Dropdown')
                .SetPoint("TOPLEFT", f.resourceType.frame, "BOTTOMLEFT", 0, -20)
                .SetParent(f)()
        local actions = Util(Award.TypeIdToAction):Copy()()
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

        f.errorTooltip = UI:NewNamed('GameTooltip', f, 'ErrorTooltip')
        f.subjectTooltip = UI:NewNamed('GameTooltip', f, 'SubjectTooltip')

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

        f.UpdateSubjectTooltip = function (subjects)
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
                if subjectType== Award.SubjectType.Character then
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
            local subjectColor, text

            if subjectType == Award.SubjectType.Character then
                subjectColor = UIUtil.GetPlayerClassColor(subjects)
                text = subjects
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
    Logging:Debug("AdjustAction() : %d, %d, %s", subjectType, resourceType, entry.name)
    self:GetAdjustFrame().Update(subjectType, resourceType, AddOn.Ambiguate(entry.name))
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

function Standings:Hide()
    if self.frame then
        self.frame:Hide()
    end

    self:HideAdjust()
end

function Standings:HideAdjust()
    if self.adjustFrame then
        self.adjustFrame:Hide()
        self.adjustFrame.errorTooltip:Hide()
        self.adjustFrame.subjectTooltip:Hide()
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

