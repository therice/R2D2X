--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type Models.Award
local Award = AddOn.ImportPackage('Models').Award
--- @type Models.History.Traffic
local Traffic = AddOn.ImportPackage('Models.History').Traffic
--- @type Models.History.TrafficStatistics
local TrafficStatistics = AddOn.ImportPackage('Models.History').TrafficStatistics
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.DropDown
local DropDown =  AddOn.Require('UI.DropDown')
local Dialog = AddOn:GetLibrary("Dialog")
--- @type Models.CompressedDb
local CDB = AddOn.Package('Models').CompressedDb
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type LibEncounter
local LibEncounter = AddOn:GetLibrary("Encounter")

--- @type TrafficHistory
local TrafficHistory = AddOn:GetModule("TrafficHistory", true)

local RightClickMenu, FilterMenu, FilterSelection = nil, nil, {dates = nil, name = nil, action = nil, resource = nil}
local ScrollColumns =
	ST.ColumnBuilder()
			:column(L['actor']):width(100)                                                          -- 1 (actor)
			:column(""):width(20)                                                                   -- 2 (class icon)
			:column(L['subject']):width(100)                                                        -- 3 (subject)
			:column(L['date']):width(125)                                                           -- 4 (date)
				:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
				:comparesort(function(...) return TrafficHistory.SortByTimestamp(... )end)
			:column(L['action']):width(50)                                                          -- 5 (action)
			:column(L['resource']):width(50)                                                        -- 6 (resource)
			:column(L['amount']):width(50)                                                          -- 7 (amount)
				:comparesort(function(...) return TrafficHistory.SortByResourceQuantity(...) end)
			:column(L['before']):width(50)                                                          -- 8 (amount before)
			:column(L['after']):width(50)                                                           -- 9 (amount after)
			:column(L['description']):width(300)                                                    -- 10 (desc)
			:column(""):width(20)                                                                   -- 11 (delete icon)
		:build()

local DateFilterColumns, NameFilterColumns, ActionFilterColumns, ResourceFilterColumns =
	ST.ColumnBuilder():column(L['date']):width(60):sort(STColumnBuilder.Descending):build(),
	ST.ColumnBuilder():column(""):width(20):column(_G.NAME):width(100):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(L['action']):width(50):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(L['resource']):width(50):sort(STColumnBuilder.Ascending):build()

local SubjectTypesForDisplay, ActionTypesForDisplay, ResourceTypesForDisplay = {}, {}, {}

do
	for key, value in pairs(Award.SubjectType) do
		if value ~= Award.SubjectType.Character then
			SubjectTypesForDisplay[key] = {
				{DoCellUpdate =  ST.DoCellUpdateFn(function(_, frame, ...) TrafficHistory.SetSubjectIcon(frame, _, _, _, value) end)},
				{value = key, DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) TrafficHistory.SetSubject(frame,  _, _, _, value) end)},
			}
		end
	end

	for key, value in pairs(Award.ActionType) do
		Util.Tables.Push(
				ActionTypesForDisplay,
				{
					{ value = key, name = key, DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) TrafficHistory.SetAction(frame,  _, _, _, value) end)},
				}
		)
	end

	for key, value in pairs(Award.ResourceType) do
		Util.Tables.Push(
				ResourceTypesForDisplay,
				{
					{ value = key, name = key, DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) TrafficHistory.SetResource(frame,  _, _, _, value) end)},
				}
		)
	end
end

function TrafficHistory:GetFrame()
	if not self.frame then
		RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.TrafficHistoryRightClick, UIParent)
		FilterMenu = MSA_DropDownMenu_Create(C.DropDowns.TrafficHistoryFilter, UIParent)
		MSA_DropDownMenu_Initialize(RightClickMenu, self.RightClickMenu, "MENU")
		MSA_DropDownMenu_Initialize(FilterMenu, self.FilterMenu)

		local f = UI:NewNamed('Frame', UIParent, 'TrafficHistory', self:GetName(), L['frame_traffic_history'], 450, 475, true)
		local st = ST.New(ScrollColumns, 15, 20, nil, f)
		st:RegisterEvents({
			["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
				if button == C.Buttons.Right and row then
					RightClickMenu.entry = data[realrow].entry
					MSA_ToggleDropDownMenu(1, nil, RightClickMenu, cellFrame, 0, 0)
				elseif button == C.Buttons.Left and row then
					MI.Update(f, data, realrow)
			    end

				return false
			end,
			--[[
			["OnEnter"] = function(...)
				return false
			end,
			["OnLeave"] = function(...)
				return false
			end,
			--]]
		})
		st:EnableSelection(true)
		st:SetFilter(self.FilterFunc)
		MI.EmbedWidgets(self:GetName(), f, function(...) self:UpdateMoreInfo(...) end)

		f.date = ST.New(DateFilterColumns, 5, 20, nil, f, false)
		f.date.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -20)
		f.date:EnableSelection(true)
		f.date:RegisterEvents({
              ["OnClick"] = function(_, _, data, _, row, realrow, _, _, button, ...)
                  if button == C.Buttons.Left and row then
                      FilterSelection.dates = data[realrow].timestamps or nil
                      self:Update()
                  end
                  return false
              end
          })

		f.name = ST.New(NameFilterColumns, 5, 20, nil, f, false)
		f.name.frame:SetPoint("TOPLEFT", f.date.frame, "TOPRIGHT", 20, 0)
		f.name:EnableSelection(true)
		f.name:RegisterEvents({
              ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
                  if button == C.Buttons.Left and row then
                      FilterSelection.name = data[realrow][column].name or nil
                      self:Update()
                  end
                  return false
              end
        })

		f.action = ST.New(ActionFilterColumns, 5, 20, nil, f, false)
		f.action.frame:SetPoint("TOPLEFT", f.name.frame, "TOPRIGHT", 20, 0)
		f.action:EnableSelection(true)
		f.action:RegisterEvents({
              ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
                  if button == C.Buttons.Left and row then
                      FilterSelection.action = data[realrow][column].name or nil
                      self:Update()
                  end
                  return false
              end
          })

		f.resource = ST.New(ResourceFilterColumns, 5, 20, nil, f, false)
		f.resource.frame:SetPoint("TOPLEFT", f.action.frame, "TOPRIGHT", 20, 0)
		f.resource:EnableSelection(true)
		f.resource:RegisterEvents({
            ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
                if button == C.Buttons.Left and row then
                    FilterSelection.resource = data[realrow][column].name or nil
                    self:Update()
                end
                return false
            end
        })

		local close = UI:New('Button', f.content)
		close:SetText(_G.CLOSE)
		close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -100)
		close:SetScript("OnClick", function() self:Disable() end)
		f.close = close

		local filter = UI:New('Button', f.content)
		filter:SetText(_G.FILTER)
		filter:SetPoint("RIGHT", f.close, "LEFT", -10, 0)
		filter:SetScript("OnClick", function(self) MSA_ToggleDropDownMenu(1, nil, FilterMenu, self, 0, 0) end )
		f.filter = filter
		f.filter:SetSize(100,25)

		local clear = UI:New('Button', f.content)
		clear:SetText(L['clear_selection'])
		clear:SetPoint("RIGHT", f.filter, "LEFT", -10, 0)
		clear:SetScript("OnClick", function()
			FilterSelection = {dates = nil, name = nil, action = nil, resource = nil}
			self.frame.date:ClearSelection()
			self.frame.name:ClearSelection()
			self.frame.action:ClearSelection()
			self.frame.resource:ClearSelection()
			self:Update()
		end)
		self.clear = clear

		self.frame = f
	end

	return self.frame
end

TrafficHistory.SortByTimestamp =
	ST.SortFn(
		function(row)
			return row.entry:TimestampAsDate()
		end
	)

TrafficHistory.SortByResourceQuantity =
	ST.SortFn(
		function(row)
			return row.entry.resourceQuantity + .0
		end
	)

local cpairs = CDB.static.pairs
-- todo : only load a fixed number of rows to start and display option for loading more
function TrafficHistory:BuildData()
	if self.frame then
		local tsData, nameData = {}, {}
		self.frame.rows = {}
		for row, entryData in cpairs(self:GetHistory()) do
			--- @type Models.History.Traffic
			local entry = Traffic:reconstitute(entryData)
			self.frame.rows[row] = {
				num   = row,
				entry = entry,
				cols =
					STCellBuilder()
						:classColoredCell(AddOn.Ambiguate(entry.actor), entry.actorClass)
						:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficHistory.SetCellSubjectIcon(...) end))
						:cell(entry.subjectType):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficHistory.SetCellSubject(...) end))
						:cell(entry:FormattedTimestamp() or "")
						:cell(entry.actionType):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficHistory.SetCellAction(...) end))
						:cell(entry.resourceType):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficHistory.SetCellResource(...) end))
						:cell(math.floor(entry.resourceQuantity) == entry.resourceQuantity and entry.resourceQuantity or (entry.resourceQuantity * 100) .. '%')
						:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function (...) TrafficHistory.SetCellResourceBefore(...) end))
						:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) TrafficHistory.SetCellResourceAfter(...) end))
						:cell(entry.description)
						:deleteCell(
							-- todo : consolidate into delete function
							function(_, data, r)
								local history, num = self:GetHistory(), data[r].num
								history:del(num)
								tremove(data, r)

								-- adjust indices based upon delete
								for _, v in pairs(data) do
									if v.num >= num then
										v.num = v.num - 1
									end
								end

								self.frame.st:SortData()
							end
						)
					:build()
			}

			local fmtDate = entry:FormattedDate()
			if not Util.Tables.ContainsKey(tsData, fmtDate) then
				tsData[fmtDate] = {entry:FormattedDate(), timestamps = {}}
			end

			Util.Tables.Push(tsData[fmtDate].timestamps, entry.timestamp)

			-- Add all the individual character's to name data
			if entry.subjectType == Award.SubjectType.Character then
				local subject = entry.subjects[1]
				if not Util.Tables.ContainsKey(nameData, subject[1]) then
					local subjectName, subjectClass = subject[1], subject[2]
					nameData[subjectName] = {
						{ DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) UIUtil.ClassIconFn()(frame, subjectClass) end)},
						{ value = AddOn.Ambiguate(subjectName), color = UIUtil.GetClassColor(subjectClass), name = subjectName}
					}
				end
			end
		end

		Util.Tables.CopyInto(nameData, SubjectTypesForDisplay)

		self.frame.st:SetData(self.frame.rows)
		self.frame.date:SetData(Util.Tables.Values(tsData), true)
		self.frame.name:SetData(Util.Tables.Values(nameData), true)
		self.frame.action:SetData(ActionTypesForDisplay, true)
		self.frame.resource:SetData(ResourceTypesForDisplay, true)
		self:Update()
	end
end

function TrafficHistory:Update()
	local function IsFiltering()
		local settings = AddOn:ModuleSettings(self:GetName())
		for _, v in pairs(settings.filters.class) do
			-- Logging:Debug("IsFiltering(%s) : %s", tostring(k), tostring(v))
			if not v then return true end
		end

		return false
	end

	if self.frame then
		self.frame.st:SortData()

		if IsFiltering() then
			self.frame.filter.Text:SetTextColor(0.86,0.5,0.22) -- #db8238
		else
			self.frame.filter.Text:SetTextColor(_G.NORMAL_FONT_COLOR:GetRGB()) --#ffd100
		end
	end
end

function TrafficHistory.SetCellSubjectIcon(_, frame, data, _, _, realrow, column, ...)
	local entry = data[realrow].entry
	local subjectType = entry.subjectType
	-- single character, so will be only one entry in subjects
	if subjectType == Award.SubjectType.Character then
		local subjectEntry = entry.subjects[1]
		UIUtil.ClassIconFn()(frame, subjectEntry[2])
	else
		TrafficHistory.SetSubjectIcon(frame, data, realrow, column, subjectType)
	end
end

function TrafficHistory.SetSubjectIcon(frame, data, realrow, column, subjectType)
	--Logging:Debug("SetSubjectIcon() : %s, %s", tostring(x), tostring(subjectType))
	subjectType = subjectType or data[realrow][column].args[1]
	-- https://wow.gamepedia.com/API_Texture_SetTexCoord
	if subjectType == Award.SubjectType.Guild then
		frame:SetNormalTexture(134157)
		frame:GetNormalTexture():SetTexCoord(0,1,0,1)
	elseif subjectType == Award.SubjectType.Raid then
		frame:SetNormalTexture(134156)
		frame:GetNormalTexture():SetTexCoord(0,1,0,1)
	elseif subjectType == Award.SubjectType.Standby then
		frame:SetNormalTexture(134155)
		frame:GetNormalTexture():SetTexCoord(0,1,0,1)
	end
end

function TrafficHistory.SetCellSubject(_, frame, data, _, _, realrow, column, ...)
	local entry = data[realrow].entry
	local subjectType = entry.subjectType
	-- single character, so will be only one entry in subjects
	if subjectType == Award.SubjectType.Character then
		frame.text:SetText(AddOn.Ambiguate(entry.subjects[1][1]))
		local classColor = UIUtil.GetClassColor(entry.subjects[1][2])
		if classColor and classColor.GetRGB then
			frame.text:SetTextColor(classColor:GetRGB())
		end
	else
		TrafficHistory.SetSubject(frame, data, realrow, column, subjectType)
	end
end

function TrafficHistory.SetSubject( frame, data, realrow, column, subjectType)
	subjectType = subjectType or data[realrow][column].args[1]
	if subjectType == Award.SubjectType.Guild then
		frame.text:SetText(_G.GUILD)
		frame.text:SetTextColor(UIUtil.GetSubjectTypeColor(Award.SubjectType.Guild):GetRGB())
	elseif subjectType == Award.SubjectType.Raid then
		frame.text:SetText(_G.GROUP)
		frame.text:SetTextColor(UIUtil.GetSubjectTypeColor(Award.SubjectType.Raid):GetRGB())
	elseif subjectType == Award.SubjectType.Standby then
		frame.text:SetText(L["standby"])
		frame.text:SetTextColor(UIUtil.GetSubjectTypeColor(Award.SubjectType.Standby):GetRGB())
	end
end

function TrafficHistory.SetCellAction(_, frame, data, _, _, realrow, column, _)
	TrafficHistory.SetAction(frame, data, realrow, column, data[realrow].entry.actionType)
end


function TrafficHistory.SetAction(frame, data, realrow, column, actionType)
	actionType = actionType or data[realrow][column].args[1]
	frame.text:SetText(Award.TypeIdToAction[actionType])
	frame.text:SetTextColor(UIUtil.GetActionTypeColor(actionType):GetRGB())
end


function TrafficHistory.SetCellResource(_, frame, data, _, _, realrow, column, _)
	TrafficHistory.SetResource(frame, data, realrow, column, data[realrow].entry.resourceType)
end

function TrafficHistory.SetResource(frame, data, realrow, column, resourceType)
	resourceType = resourceType or data[realrow][column].args[1]
	frame.text:SetText(Award.TypeIdToResource[resourceType]:upper())
	frame.text:SetTextColor(UIUtil.GetResourceTypeColor(resourceType):GetRGB())
end

function TrafficHistory.SetCellResourceBefore(_, frame, data, _, _, realrow, column)
	local entry = data[realrow].entry
	local value = entry.resourceBefore
	frame.text:SetText(value or "N/A")
	data[realrow].cols[column].value = value or 0
end

function TrafficHistory.SetCellResourceAfter(_, frame, data, _, _, realrow, column)
	local entry = data[realrow].entry
	local value = entry.resourceBefore
	if value then
		if entry.actionType == Award.ActionType.Add then
			value = value + entry.resourceQuantity
		elseif entry.actionType == Award.ActionType.Subtract then
			value = value - entry.resourceQuantity
		elseif entry.actionType == Award.ActionType.Reset then
			value = value
		end
	else
		value = nil
	end

	frame.text:SetText(value or "N/A")
	data[realrow].cols[column].value = value or 0
end

local MaxSubjects = 40

local CountDecorator = UIUtil.ColoredDecorator(1, 1, 1, 1)
local TotalDecorator = UIUtil.ColoredDecorator(0, 1, 0.59, 1)
local DecayDecorator = UIUtil.ActionTypeDecorator(Award.ActionType.Decay)
local ResetDecorator = UIUtil.ActionTypeDecorator(Award.ActionType.Reset)

function TrafficHistory:UpdateMoreInfo(f, row, data)
	local proceed, entry = MI.Context(f, row, data, 'entry')
	if proceed then
		local tip = f.moreInfo
		tip:SetOwner(f, "ANCHOR_RIGHT")
		if Util.Objects.In(entry.subjectType, Award.SubjectType.Guild,  Award.SubjectType.Raid, Award.SubjectType.Standby) then
			local color = UIUtil.GetSubjectTypeColor(entry.subjectType)
			tip:AddLine(Award.TypeIdToSubject[entry.subjectType], color.r, color.g, color.b)
			tip:AddLine(" ")
			local subjectCount = Util.Tables.Count(entry.subjects)
			tip:AddDoubleLine(L["members"], subjectCount)
			tip:AddLine(" ")

			local shown = 0
			for _, subject in pairs(Util.Tables.Sort(entry.subjects, function (a, b) return a[1] < b[1 ]end)) do
				if shown < MaxSubjects then
					tip:AddLine(UIUtil.ClassColorDecorator(subject[2]):decorate(AddOn.Ambiguate(subject[1])))
					shown = shown + 1
				else
					tip:AddLine("... (" .. tostring(subjectCount - shown) .. " more)")
					break
				end
			end
		else
			local subject = entry.subjects[1]
			local name, class = subject[1], subject[2]
			local color = UIUtil.GetClassColor(class)
			tip:AddLine(AddOn.Ambiguate(name), color.r, color.g, color.b)
			tip:AddLine(" ")

			local stats, interval = TrafficHistory:GetStatistics(), self.StatsIntervalInDays
	        local se = stats and stats:Get(name) or nil
	        if stats and se then
	            tip:AddLine("For the past " .. tostring(interval) .. " days")
	            tip:AddLine(" ")
	            tip:AddDoubleLine("Resource",
	                            CountDecorator:decorate("Count") .. " / " ..
	                            TotalDecorator:decorate("Awarded") .. " / " ..
	                            DecayDecorator:decorate("Decays") .. " / " ..
	                            ResetDecorator:decorate("Resets")
	            )
	            local totals = se:CalculateTotals()
	            for _, resource in pairs({Award.ResourceType.Ep, Award.ResourceType.Gp}) do
	                local decorator = UIUtil.ResourceTypeDecorator(resource)
	                tip:AddDoubleLine(
	                        decorator:decorate(Util.Strings.Upper(Award.TypeIdToResource[resource])),
	                        CountDecorator:decorate(tostring(totals.awards[resource].count)) .. ' / ' ..
	                        TotalDecorator:decorate(tostring(totals.awards[resource].total)) .. ' / ' ..
	                        DecayDecorator:decorate(tostring(totals.awards[resource].decays)) .. ' / ' ..
	                        ResetDecorator:decorate(tostring(totals.awards[resource].resets))
	                )
	            end
	            tip:AddLine(" ")

		        if totals.raids and totals.raids.count > 0 then
			        local raidTotals, aggregated = stats:Get(TrafficStatistics.Summary):CalculateTotals(), {}
			        tip:AddDoubleLine("Raid",
			                          TotalDecorator:decorate("Total") .. " / " ..
			                          DecayDecorator:decorate("Attended") .. " / " ..
			                          ResetDecorator:decorate("Percentage")
			        )

			        aggregated[L['all']] = {raidTotals.raids.count, totals.raids and totals.raids.count or 0}

			        for instanceId, total in pairs(raidTotals.raids) do
				        if Util.Objects.IsNumber(instanceId) then
					        local instanceName = LibEncounter:GetMapName(instanceId)
					        local attended = totals.raids[instanceId] and totals.raids[instanceId] or 0
					        aggregated[instanceName] = {total, attended}
				        end
			        end

			        for _, n in pairs(Util.Tables.Sort(Util.Tables.Keys(aggregated), function (a, b) return a < b end)) do
				        local d = aggregated[n]
				        local total, attended = d[1], d[2]
				        tip:AddDoubleLine(
				                CountDecorator:decorate(n),
				                TotalDecorator:decorate(tostring(total)) .. " / " ..
		                        DecayDecorator:decorate(tostring(attended)) .. " / " ..
		                        ResetDecorator:decorate(tostring(Util.Numbers.Round2(attended/total * 100.0)) .. '%')
				        )
			        end
				else
			        tip:AddLine("No raid entries in the past " .. tostring(interval) .. " days")
		        end
	        else
	            tip:AddLine("No entries in the past " .. tostring(interval) .. " days")
	        end

		end

		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end

TrafficHistory.RightClickEntries =
	DropDown.EntryBuilder()
		:nextlevel()
			:add():checkable(false):set('isTitle', true):disabled(true)
				:text(
					--- @param entry Models.History.Traffic
					function(_, entry)
						local displaySubject
						if entry.subjectType == Award.SubjectType.Character then
							local subject = entry.subjects[1]
							displaySubject = UIUtil.ClassColorDecorator(subject[2]):decorate(subject[1])
						else
							displaySubject =
								UIUtil.SubjectTypeDecorator(entry.subjectType)
									:decorate(Award.TypeIdToSubject[entry.subjectType])
						end

						return format("%s - %s",
						              displaySubject,
						              entry:FormattedTimestamp()
						)
					end
				)
			:add():text(""):checkable(false):disabled(true)
			:add():text(L['revert']):checkable(false)
				-- i think it should be fine to apply revert to guild/raid, we have the list of subjects
				-- :hidden(function(_, entry) return entry.subjectType ~= Award.SubjectType.Character end)
				:fn(
					--- @param entry Models.History.Traffic
					function(_, entry)
						Dialog:Spawn(C.Popups.ConfirmRevert, entry)
					end
				)
			-- todo why can't this handle characters?
			:add():text(L['amend']):checkable(false)
				-- i think it should be fine to apply revert to guild/raid, we have the list of subjects
				-- :hidden(function(_, entry) return entry.subjectType ~= Award.SubjectType.Character end)
				:fn(
					--- @param entry Models.History.Traffic
					function(_, entry)
						AddOn:CallModule("Standings")
						AddOn:StandingsModule():AmendAction(entry)
					end
				)
		:build()

TrafficHistory.RightClickMenu = DropDown.RightClickMenu(
		function() return AddOn:DevModeEnabled() or CanEditOfficerNote() end,
		TrafficHistory.RightClickEntries
)

function TrafficHistory.FilterFunc(_, row)
	local settings = AddOn:ModuleSettings(TrafficHistory:GetName())

	local function SelectionFilter(entry)
		local include = true

		if Util.Tables.IsSet(FilterSelection.dates) then
			include = Util.Tables.ContainsValue(FilterSelection.dates, entry.timestamp)
		end

		if include and Util.Strings.IsSet(FilterSelection.name) then
			local selectedName, subjectType = FilterSelection.name, entry.subjectType
			if subjectType == Award.SubjectType.Character then
				include = Util.Strings.Equal(selectedName, entry.subjects[1][1])
			elseif subjectType == Award.SubjectType.Guild then
				include = Util.Strings.Equal(selectedName, _G.GUILD)
			elseif subjectType == Award.SubjectType.Raid then
				include = Util.Strings.Equal(selectedName, _G.GROUP)
			elseif subjectType == Award.SubjectType.Standby then
				include = Util.Strings.Equal(selectedName, L["standby"])
			end
		end

		if include and Util.Strings.IsSet(FilterSelection.action) then
			include =  entry.actionType == Award.ActionType[FilterSelection.action]
		end

		if include and Util.Strings.IsSet(FilterSelection.resource) then
			include = (entry.resourceType == Award.ResourceType[Util.Strings.UcFirst(Util.Strings.Lower(FilterSelection.resource))])
		end

		return include
	end

	local function ClassFilter(class)
		return settings.filters.class and settings.filters.class[ItemUtil:ClassTransitiveMapping(class)]
	end

	local entry = row.entry
	local selectionFilter, classFilter = SelectionFilter(entry), true
	if settings and settings.filters and entry.subjectType == Award.SubjectType.Character then
		-- character means one subject and index 2 will be their class
		classFilter = ClassFilter(entry.subjects[1][2])
	end

	return selectionFilter and classFilter
end

function TrafficHistory.FilterMenu(_, level)
	local settings = AddOn:ModuleSettings(TrafficHistory:GetName())
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
			TrafficHistory:Update()
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

		-- todo : add section for (de)select all
	end
end

function TrafficHistory:Show()
	if self.frame then
		self.frame:Show()
	end
end

function TrafficHistory:Hide()
	if self.frame then
		self.frame.moreInfo:Hide()
		self.frame:Hide()
	end
end
