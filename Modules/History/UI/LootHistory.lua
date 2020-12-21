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
--- @type Models.History.Loot
local Loot = AddOn.ImportPackage('Models.History').Loot
--- @type Models.History.LootStatistics
local LootStatistics = AddOn.ImportPackage('Models.History').LootStatistics
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
--- @type LibItemUtil
local ItemUtil = AddOn:GetLibrary("ItemUtil")
--- @type LibEncounter
local LibEncounter = AddOn:GetLibrary("Encounter")
--- @type Models.CompressedDb
local CDB = AddOn.Package('Models').CompressedDb

--- @type LootHistory
local LootHistory = AddOn:GetModule("LootHistory", true)

local FilterMenu, FilterSelection = nil, {dates = nil, instance = nil, name = nil}
local ScrollColumns =
	ST.ColumnBuilder()
		:column(""):width(20):sortnext(2)                                                           -- 1 (class icon)
		:column(_G.NAME):width(100):sortnext(3):defaultsort(STColumnBuilder.Ascending)              -- 2 (player name)
		:column(L['date']):width(125)                                                               -- 3 (date)
			:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
			:comparesort(function(...) return LootHistory.SortByTimestamp(...) end)
		:column(L['instance']):width(125)                                                           -- 4 (instance)
			:defaultsort(STColumnBuilder.Descending):sort(STColumnBuilder.Descending)
		:column(""):width(20)                                                                       -- 5 (item icon)
		:column(L['item']):width(250)                                                               -- 6 (item string)
			:defaultsort(STColumnBuilder.Ascending):sortnext(2)
			:comparesort(function(...) return LootHistory.SortByItem(...) end)
		:column(L['reason']):width(220)                                                             -- 7 (response)
			:defaultsort(STColumnBuilder.Ascending):sortnext(2)
			:comparesort(function(...) return LootHistory.SortByResponse(...) end)
		:column(""):width(20)                                                                       -- 8 (delete icon)
	:build()

local DateFilterColumns, InstanceFilterColumns, NameFilterColumns =
	ST.ColumnBuilder():column(L['date']):width(80):sort(STColumnBuilder.Descending):build(),
	ST.ColumnBuilder():column(L['instance']):width(100):sort(STColumnBuilder.Ascending):build(),
	ST.ColumnBuilder():column(""):width(20):column(_G.NAME):width(100):sort(STColumnBuilder.Ascending):build()

function LootHistory:GetFrame()
	if not self.frame then
		FilterMenu = MSA_DropDownMenu_Create(C.DropDowns.LootHistoryFilter, UIParent)
		MSA_DropDownMenu_Initialize(FilterMenu, self.FilterMenu)

		local f = UI:NewNamed('Frame', UIParent, 'LootHistory', self:GetName(), L['frame_loot_history'], 450, 475, true)
		local st = ST.New(ScrollColumns, 15, 20, nil, f)
		st:RegisterEvents({
              ["OnClick"] = function(_, _, data, _, row, realrow, _, _, button, ...)
                  if button == C.Buttons.Left and row then
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

		f.instance = ST.New(InstanceFilterColumns, 5, 20, nil, f, false)
		f.instance.frame:SetPoint("TOPLEFT", f.name.frame, "TOPRIGHT", 20, 0)
		f.instance:EnableSelection(true)
		f.instance:RegisterEvents({
	          ["OnClick"] = function(_, _, data, _, row, realrow, column, _, button, ...)
	              if button == C.Buttons.Left and row then
	                  FilterSelection.instance = data[realrow].instanceId or nil
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
			FilterSelection = {dates = nil, instance = nil, name = nil}
			self.frame.date:ClearSelection()
			self.frame.instance:ClearSelection()
			self.frame.name:ClearSelection()
			self:Update()
		end)
		self.clear = clear

		self.frame = f
	end

	return self.frame
end

local cpairs = CDB.static.pairs
function LootHistory:BuildData()
	if self.frame then
		local data = {}
		for name, entries in cpairs(self:GetHistory()) do
			for index, entryTable in pairs(entries) do
				local entry = Loot:reconstitute(entryTable)
				local ts = entry.timestamp

				if not Util.Tables.ContainsKey(data, ts) then
					data[ts] = {}
				end

				if not Util.Tables.ContainsKey(data[ts], name) then
					data[ts][name] = {}
				end

				if not Util.Tables.ContainsKey(data[ts][name], index) then
					data[ts][name][index] = {}
				end

				data[ts][name][index] = entry
			end
		end

		table.sort(data)
		self.frame.rows = {}
		local tsData, instanceData, nameData, row = {}, {}, {}, 1
		for _, names in pairs(data) do
			for _, entries in pairs(names) do
				for index, entry in pairs(entries) do
					local instanceName = LibEncounter:GetMapName(entry.instanceId)
					local player = AddOn.Ambiguate(entry.owner)
					self.frame.rows[row] = {
						rownum = row,   -- this is the index in the rows table
						num = index,    -- this is the index within the player's table
						entry = entry,
						cols =
							STCellBuilder()
								:classIconCell(entry.class)
								:classColoredCell(player, entry.class)
								:cell(entry:FormattedTimestamp() or "")
								:cell(instanceName or "")
								:itemIconCell(entry.item)
								:cell(entry.item)
								:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function (...) LootHistory.SetCellResponse(...) end))
								:deleteCell(
									function(_, data, row)

									end
								)
							:build()
					}

					-- keep a copy of all the timestamps that map to date
					-- could probably calculate later
					local fmtDate = entry:FormattedDate()
					if not Util.Tables.ContainsKey(tsData, fmtDate) then
						tsData[fmtDate] = {fmtDate, timestamps = {}}
					end
					Util.Tables.Push(tsData[fmtDate].timestamps, entry.timestamp)

					if not Util.Tables.ContainsKey(instanceData, instanceName) then
						instanceData[instanceName] = {instanceName, instanceId = entry.instanceId}
					end

					if not Util.Tables.ContainsKey(nameData, player) then
						nameData[player] = {
							{ DoCellUpdate = ST.DoCellUpdateFn(function(_, frame, ...) UIUtil.ClassIconFn()(frame, entry.class) end)},
							{ value = player, color = UIUtil.GetClassColor(entry.class), name = player}
						}
					end

					row = row + 1
				end
			end
		end

		self.frame.st:SetData(self.frame.rows)
		self.frame.date:SetData(Util.Tables.Values(tsData), true)
		self.frame.instance:SetData(Util.Tables.Values(instanceData), true)
		self.frame.name:SetData(Util.Tables.Values(nameData), true)
	end
end

local NonUserVisibleResponse = Util.Memoize.Memoize(
		function(responseId)
			local _, response = Util.Tables.FindFn(
					AddOn:LootAllocateModule().db.profile.awardReasons,
					function(e) return e.sort == responseId end
			)

			return response
		end
)

function LootHistory.SetCellResponse(_, frame, data, _, _, realrow, ...)
	local entry = data[realrow].entry
	frame.text:SetText(entry.response)
	local responseId = entry:GetResponseId()
	if entry:IsCandidateResponse() then
		local response = AddOn:GetResponse(responseId)
		frame.text:SetTextColor(response.color:GetRGBA())
	else
		local response = NonUserVisibleResponse(responseId)
		if response then
			frame.text:SetTextColor(response.color:GetRGBA())
		else
			frame.text:SetTextColor(1,1,1,1)
		end
	end
end

LootHistory.SortByTimestamp =
	ST.SortFn(
			function(row)
				return row.entry:TimestampAsDate()
			end
	)

LootHistory.SortByItem =
	ST.SortFn(
			function(row)
				return ItemUtil:ItemLinkToItemString(row.entry.item)
			end
	)

LootHistory.SortByResponse =
	ST.SortFn(
			function(row)
				return AddOn:GetResponse(row.entry:GetResponseId()).sort or 500
			end
	)

function LootHistory.FilterMenu(_, level)
	local settings = AddOn:ModuleSettings(LootHistory:GetName())
	if not settings.filters then settings.filters = {} end
	local filters, info = settings.filters

	if level == 1 then
		local data = {
			[C.Responses.AutoPass] = true,
			[C.Responses.Pass]     = true,
		}

		for i = 1, AddOn:GetButtonCount() do
			data[i] = i
		end

		info = MSA_DropDownMenu_CreateInfo()
		info.text = _G.CLASS
		info.isTitle = false
		info.hasArrow = true
		info.notCheckable = true
		info.disabled = true
		info.value = "CLASS"
		MSA_DropDownMenu_AddButton(info, level)

		info = MSA_DropDownMenu_CreateInfo()
		info.text = L["responses"]
		info.isTitle = true
		info.notCheckable = true
		info.disabled = true
		MSA_DropDownMenu_AddButton(info, level)

		info = MSA_DropDownMenu_CreateInfo()
		for k in ipairs(data) do
			local r = AddOn:GetResponse(k)
			info.text = r.text
			info.colorCode = UIUtil.RGBToHexPrefix(r.color:GetRGB())
			info.func = function()
				filters[k] = not filters[k]
				LootHistory:Update()
			end
			info.checked = filters[k]
			MSA_DropDownMenu_AddButton(info, level)
		end

		for k in pairs(data) do
			if Util.Objects.IsString(k) then
				if k == "STATUS" then
					info.text = L["Status texts"]
					info.colorCode = "|cffde34e2"
				else
					local r = AddOn:GetResponse(k)
					info.text = r.text
					info.colorCode = UIUtil.RGBToHexPrefix(r.color:GetRGB())
				end
				info.func = function()
					filters[k] = not filters[k]
					LootHistory:Update(true)
				end
				info.checked = filters[k]
				MSA_DropDownMenu_AddButton(info, level)
			end
		end
	elseif level == 2 then
		local value = _G.MSA_DROPDOWNMENU_MENU_VALUE
		if Util.Strings.Equal(value, "CLASS") then

			local function setfilter(section, value)
				Logging:Debug("setfilter(%s)", value)
				filters[section][value] = not filters[section][value]
				LootHistory:Update()
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

			-- there is an issue here with display reflecting what is selected
			-- with the '(de)select all'
			info = MSA_DropDownMenu_CreateInfo()
			info.text = L['deselect_all']
			info.notCheckable = true
			info.keepShownOnClick = true
			info.func = function()
				for _, k in pairs(classes) do
					filters.class[k] = not filters.class[k]
					MSA_DropDownMenu_SetSelectedName(FilterMenu, k, false)
					LootHistory:Update()
				end
			end
			MSA_DropDownMenu_AddButton(info, level)
		end
	end
end

function LootHistory.FilterFunc(_, row)
	local settings = AddOn:ModuleSettings(LootHistory:GetName())

	local function SelectionFilter(entry)
		local include = true

		if Util.Tables.IsSet(FilterSelection.dates) then
			include = Util.Tables.ContainsValue(FilterSelection.dates, entry.timestamp)
		end

		if include and Util.Objects.IsNumber(FilterSelection.instance) then
			include = entry.instanceId == FilterSelection.instance
		end

		if include and Util.Strings.IsSet(FilterSelection.name) then
			include = AddOn.UnitIsUnit(FilterSelection.name, entry.owner)
		end

		return include
	end

	local function ClassFilter(class)
		return settings.filters.class and settings.filters.class[ItemUtil:ClassTransitiveMapping(class)]
	end

	local function ResponseFilter(entry)
		local include = true

		local responseId, isAwardReason = entry:GetResponseId(), entry:IsAwardReason()

		if Util.Objects.In(responseId, C.Responses.AutoPass, C.Responses.Pass) or Util.Objects.IsNumber(responseId) and not isAwardReason then
			include =  settings.filters[responseId]
		end

		return include
	end

	local entry = row.entry
	local selectionFilter, classFilter, responseFilter = SelectionFilter(entry), true, true

	if settings and settings.filters then
		classFilter = ClassFilter(entry.class)
		responseFilter = ResponseFilter(entry)
	end

	return selectionFilter and classFilter and responseFilter
end

function LootHistory:Update()
	local function IsFiltering()
		local settings = AddOn:ModuleSettings(self:GetName())
		for _, v in pairs(settings.filters.class) do
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

local EncounterCreatures = Util.Memoize.Memoize(
		function(encounterId)
			if encounterId then
				local creatureIds = LibEncounter:GetEncounterCreatureId(encounterId)
				if creatureIds then
					local creatureNames =
						Util(creatureIds):Copy()
			                :Map(function(id)  return LibEncounter:GetCreatureName(id) end)()
					return Util.Strings.Join(", ", Util.Tables.Values(creatureNames))
				end
			end

			return nil
		end
)

function LootHistory:UpdateMoreInfo(f, row, data)
	local proceed, entry = MI.Context(f, row, data, 'entry')
	if proceed then
		local tip = f.moreInfo
		tip:SetOwner(f, "ANCHOR_RIGHT")
		local color = UIUtil.GetClassColor(entry.class)
		tip:AddLine(AddOn.Ambiguate(entry.owner), color.r, color.g, color.b)
		tip:AddLine(" ")
		tip:AddDoubleLine(L["date"] .. ":", entry:FormattedTimestamp() or _G.UNKNOWN, 1,1,1, 1,1,1)
		tip:AddDoubleLine(L["loot_won"] .. ":", entry.item or _G.UNKNOWN, 1,1,1, 1,1,1)
		tip:AddDoubleLine(L["dropped_by"] .. ":", EncounterCreatures(entry.encounterId) or _G.UNKNOWN, 1,1,1, 0.862745, 0.0784314, 0.235294)
		if entry.note then
			tip:AddDoubleLine(_G.LABEL_NOTE .. ":", entry.note, 1,1,1, 1,1,1)
		end
		tip:AddLine(" ")

		local stats, interval = self:GetStatistics():Get(entry.owner), LootHistory.StatsIntervalInDays
		if stats then
			stats:CalculateTotals()
			tip:AddLine(L["total_awards"] .. " for the past " .. tostring(interval) .. " days")
			tip:AddLine(" ")
			table.sort(stats.totals.responses,
			           function(a, b)
				           local responseId1, responseId2 = a[3], b[3]
				           return Util.Objects.IsNumber(responseId1) and Util.Objects.IsNumber(responseId2) and responseId1 < responseId2 or false
			           end
			)
			-- v => {text, count, id}
			for _, v in pairs(stats.totals.responses) do
				local text, count, id = v[1], v[2], v[3]
				local response = id < 10 and AddOn:GetResponse(id) or  NonUserVisibleResponse(id)
				local r, g, b = 1, 1, 1
				if response and response.color then
					r, g, b = response.color:GetRGB()
				end
				tip:AddDoubleLine(text, count, r, g, b, 1, 1, 1)
			end
			tip:AddLine(" ")
			tip:AddDoubleLine(L["number_of_raids_from which_loot_was_received"] .. ":", stats.totals.raids.count, 1,1,1, 1,1,1)
			tip:AddDoubleLine(L["total_items_won"] .. ":", stats.totals.count, 1,1,1, 0,1,0)
		else
			tip:AddLine("No awards in the past " .. tostring(interval) .. " days")
		end

		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end

function LootHistory:Show()
	if self.frame then
		self.frame:Show()
	end
end

function LootHistory:Hide()
	if self.frame then
		self.frame.moreInfo:Hide()
		self.frame:Hide()
	end
end
