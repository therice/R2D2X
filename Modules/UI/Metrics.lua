--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.ScrollingTable.ColumnBuilder
local STColumnBuilder = AddOn.Package('UI.ScrollingTable').ColumnBuilder
--- @type UI.ScrollingTable.CellBuilder
local STCellBuilder = AddOn.Package('UI.ScrollingTable').CellBuilder
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')

--- @type Metrics
local Metrics = AddOn:GetModule("Metrics", true)

local ScrollColumns =
	ST.ColumnBuilder()
		:column(L["category"]):sort(STColumnBuilder.Ascending):width(100)
		:column(L["metric"]):defaultsort(STColumnBuilder.Ascending):width(150)
		:column(L["count"]):defaultsort(STColumnBuilder.Descending):width(45)
		:column(L["mean"]):width(45)
		:column(L["median"]):width(45)
		:column(L["stddev"]):width(45)
		:column(L["rate"]):width(45)
		:column(L["sum"]):width(45)
	:build()

function Metrics:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'Metrics', self:GetName(), L['frame_metrics'], 350, 325, true)

		local metricsToggle = CreateFrame("Frame", "MetricsToggleFrame", f.content)
		metricsToggle:SetWidth(40)
		metricsToggle:SetHeight(f:GetHeight())
		metricsToggle:SetPoint("TOPRIGHT", f, "TOPLEFT", -2, 0)
		f.metricsToggle = metricsToggle

		local comms = UI:NewNamed('IconBordered', f.metricsToggle, "CommsMetrics")
		comms.type = Metrics.MetricsType.Comms
		comms:SetPoint("TOPRIGHT", f.metricsToggle)
		comms:SetNormalTexture(format("Interface\\AddOns\\%s\\Media\\Textures\\comms.blp", C.name))
		comms:SetScript("OnEnter", function() UIUtil.CreateTooltip(L["comms"]) end)
		comms:SetScript("Onclick", function() self:Switch(comms.type) end)
		f.comms = comms

		local events = UI:NewNamed('IconBordered', f.metricsToggle, "EventsMetrics")
		events.type = Metrics.MetricsType.Events
		events:SetPoint("TOP", f.comms, "BOTTOM", 0, -2)
		events:SetNormalTexture(format("Interface\\AddOns\\%s\\Media\\Textures\\events.blp", C.name))
		events:SetScript("OnEnter", function() UIUtil.CreateTooltip(L["events"]) end)
		events:SetScript("Onclick", function() self:Switch(events.type) end)
		f.events = events

		local close = UI:New('Button', f.content)
		close:SetText(_G.CLOSE)
		close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
		close:SetScript("OnClick", function() self:Disable() end)
		f.close = close

		local st = ST.New(ScrollColumns, 12, 20, nil, f)
		st:EnableSelection(true)

		f.rows = {}
		self.frame = f
	end
end

function Metrics:UpdateButtons()
	local function UpdateButton(b)
		if b.type == self.metricType then
			b:SetBorderColor("yellow")
		else
			b:SetBorderColor("white")
		end
	end

	if self.frame then
		UpdateButton(self.frame.comms)
		UpdateButton(self.frame.events)
	end
end

function Metrics:Switch(type)
	if self.frame and self.metricType ~= type then
		self.metricType = type
		self:UpdateButtons()

		FauxScrollFrame_OnVerticalScroll(self.frame.st.scrollframe, 0, self.frame.st.rowHeight, function() self.frame.st:Refresh() end)
		self:Update(true)
	end
end

function Metrics:Update(forceUpdate)
	if self.frame then
		forceUpdate = Util.Objects.Default(forceUpdate, false)
		Logging:Trace('Update(%s) : fired=%s', tostring(forceUpdate), tostring(self.alarm:Fired()))

		if not forceUpdate and not self.alarm:Fired() then
			return
		end

		self:BuildData()
		self.frame.st:SortData()
		self.frame.st:SortData()
	end
end

function Metrics:BuildData()
	local metrics = self:GetMetrics()
	if self.frame and metrics then
		self.frame.rows = {}
		local row = 1
		for _, metricGroup in pairs(metrics) do
			for metricCategory, metricsC in pairs(metricGroup) do
				for metricName, metricN in pairs(metricsC) do
					--Logging:Debug("BuildData(%d) : %s/%s => %s", self.metricType, metricCategory, metricName, Util.Objects.ToString(metricN))
					self.frame.rows[row] = {
						num = row,
						cols =
							STCellBuilder()
								:cell(
									UIUtil.ColoredDecorator(C.Colors.MageBlue):decorate(
										Util.Strings.Split(Util.Strings.FromCamelCase(metricCategory), " ")[3]
									)
								)
								:cell(UIUtil.ColoredDecorator(C.Colors.Evergreen):decorate(metricName))
								:cell(metricN.count or 0)
								:cell(metricN.mean and Util.Numbers.Round(metricN.mean, 2) or 0)
								:cell(metricN.median and Util.Numbers.Round(metricN.median, 2) or 0)
								:cell(metricN.stddev and Util.Numbers.Round(metricN.stddev, 2) or 0)
								:cell(metricN.rate and Util.Numbers.Round(metricN.rate, 2) or 0)
								:cell(metricN.sum and Util.Numbers.Round(metricN.sum, 2) or 0)
							:build()
					}
					row = row + 1
				end
			end
		end

		self.frame.st:SetData(self.frame.rows)
	end
end

function Metrics:Show()
	if self.frame then
		self.frame:Show()
		self:Switch(Metrics.MetricsType.Comms)
	end
end

function Metrics:Hide()
	if self.frame then
		self.frame:Hide()
		self.frame.rows = {}
		self.metricType = -1
	end
end