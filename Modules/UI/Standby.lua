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
--- @type Models.DateFormat
local DateFormat = AddOn.Package('Models').DateFormat
--- @type UI.Native
local UI =  AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.MoreInfo
local MI = AddOn.Require('UI.MoreInfo')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type UI.DropDown
local DropDown = AddOn.Require('UI.DropDown')

--- @type Standby
local Standby = AddOn:GetModule("Standby", true)

local RightClickMenu
local ScrollColumns =
	STColumnBuilder()
			:column(""):width(20)                                                                   -- class (1)
			:column(_G.NAME):width(100):defaultsort(STColumnBuilder.Ascending):sortnext(1)          -- name (2)
			:column(L['added']):width(115):defaultsort(STColumnBuilder.Descending):sortnext(2)      -- added (3)
			:column(L['pinged']):width(115):defaultsort(STColumnBuilder.Descending):sortnext(2)     -- pinged (4)
			:column(L['status']):width(55):defaultsort(STColumnBuilder.Descending):sortnext(2)      -- status (5)
			:column(""):width(20)                                                                   -- remove (6)
		:build()

function Standby:GetFrame()
	if not self.frame then

		RightClickMenu = MSA_DropDownMenu_Create(C.DropDowns.StandbyRightClick, UIParent)
		MSA_DropDownMenu_Initialize(RightClickMenu, self.RightClickMenu, "MENU")

		local f = UI:NewNamed('Frame', UIParent, 'Standby', self:GetName(), L['frame_standby_bench'], 225, 300)
		local st = ST.New(ScrollColumns, 8, 25, nil, f)
		st:RegisterEvents({
			                  -- https://www.wowace.com/projects/lib-st/pages/ui-events
			                  -- function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
			                  ["OnClick"] = function(_, cellFrame, data, _, row, realrow, _, _, button, ...)
				                  if button == C.Buttons.Right and row then
					                  RightClickMenu.name = data[realrow].name
					                  RightClickMenu.module = self
					                  MSA_ToggleDropDownMenu(1, nil, RightClickMenu, cellFrame, 0, 0)
				                  elseif button == C.Buttons.Left  and row then
					                  MI.Update(f, data, realrow)
				                  end
				                  return false
			                  end,
			                  ["OnEnter"] = function(_, _, data, _, row, realrow, _, _, _, ...)
				                  if row then
									MI.Update(f, data, realrow)
				                  end
				                  return false
			                  end,
			                  ["OnLeave"] = function()
				                  MI.Update(f, nil, nil)
				                  return false
			                  end
		                  })
		st:EnableSelection(true)
		MI.EmbedWidgets(self:GetName(), f, function(...) self:UpdateMoreInfo(...) end)

		local close = UI:NewNamed('Button', f.content, "Close")
		close:SetText(_G.CLOSE)
		close:SetPoint("RIGHT", f.moreInfoBtn, "LEFT", -10, 0)
		close:SetScript("OnClick", function() self:Disable() end)
		f.close = close

		self.frame = f
	end

	return self.frame
end

--- @type Models.DateFormat
local FullDf = DateFormat("mm/dd/yyyy HH:MM:SS")
--- @type UI.ColoredDecorator
local TsDecorator = UIUtil.ColoredDecorator(0.25, 0.78, 0.92)
--- @type UI.ColoredDecorator
local OnlineDecorator = UIUtil.ColoredDecorator(0, 1, 0.59)
--- @type UI.ColoredDecorator
local OfflineDecorator = UIUtil.ColoredDecorator(0.77, 0.12, 0.23)


--- @param status Models.StandbyStatus
local function DecorateOnlineStatusText(status)
	return status.online and OnlineDecorator:decorate(L['online']) or OfflineDecorator:decorate(L['offline'])
end

local function DecorateTimestamp(timestamp)
	return TsDecorator:decorate(FullDf:format(timestamp))
end

--- @param status Models.StandbyStatus
local function GetStandbyStatusText(status)
	return Util.Strings.Join("/", DecorateTimestamp(status.timestamp), DecorateOnlineStatusText(status))
end

function Standby:UpdateMoreInfo(frame, data, row)
	local proceed, player = MI.Context(frame, data, row, 'player')

	if proceed then
		local tip = frame.moreInfo
		tip:SetOwner(frame, "ANCHOR_RIGHT")
		if Util.Tables.Count(player.contacts) > 0 then
			tip:AddDoubleLine(L["contact"], Util.Strings.Join("/", L["pinged"], L["status"]))
			tip:AddLine(" ")

			for name, status in pairs(player.contacts) do
				tip:AddDoubleLine(name, GetStandbyStatusText(status), 1, 1, 1)
			end
		else
			tip:AddLine(L["no_contacts_for_standby_member"])
		end
		tip:Show()
		tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
	end
end

function Standby:BuildData()
	if self.frame then
		self.frame.rows = {}
		local row = 1
		for name, player in pairs(self.roster) do
			self.frame.rows[row] = {
				name = name,
				player = player,
				num = row,
				cols = STCellBuilder()
							:classIconCell(player.class)
							:classColoredCell(AddOn.Ambiguate(name), player.class)
							:cell(DecorateTimestamp(player:JoinedTimestamp()))
							:cell(DecorateTimestamp(player:PingedTimestamp()))
							:cell(""):DoCellUpdate(ST.DoCellUpdateFn(function(...) self:SetCellStatus(...) end))
							:deleteCell(function(_, data, row) self:RemovePlayer(data[row].player) end)
						:build()
			}
			row = row +1
		end

		self.frame.st:SetData(self.frame.rows)
	end
end

function Standby:Update()
	if self.frame then
		self:BuildData()
		self.frame.st:SortData()
		MI.Update(self.frame, nil, nil)
	end
end

function Standby:SetCellStatus(_, frame, data, _, _, realrow, column, ...)
	local player = data[realrow].player
	frame.text:SetText(DecorateOnlineStatusText(player.status))
	data[realrow].cols[column].value = player.status
end

Standby.RightClickEntries =
	DropDown.EntryBuilder()
		:nextlevel()
			:add():checkable(false):set('isTitle', true):disabled(true)
				:text(function(name) return AddOn.Ambiguate(name) end)
			:add():text(""):checkable(false):disabled(true)
			:add():text(L["ping"]):checkable(false):fn(function(name, _, self) self:PingPlayer(name) end)
		:build()

Standby.RightClickMenu = DropDown.RightClickMenu(
		function() return AddOn:DevModeEnabled() or CanEditOfficerNote() end,
		Standby.RightClickEntries
)

function Standby:Show()
	if self.frame then
		self.frame:Show()
	end
end

function Standby:Hide()
	if self.frame then
		self.frame:Hide()
	end
end