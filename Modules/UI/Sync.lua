--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util = AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.Util
local UIUtil = AddOn.Require('UI.Util')
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type Models.Award
local Award = AddOn.Package('Models').Award

--- @type Sync
local Sync = AddOn:GetModule("Sync", true)


local function AddNameToList(l, name, class)
	l[name] = UIUtil.ClassColorDecorator(class):decorate(name)
end

function Sync:AvailableGuildTargets()
	local name, online, class, targets = nil, nil, nil, {}

	for i = 1, GetNumGuildMembers() do
		name, _, _, _, _, _, _, _, online,_,class = GetGuildRosterInfo(i)
		if online then
			AddNameToList(targets, AddOn:UnitName(name), class)
		end
	end

	return targets
end

function Sync:AvailableGroupTargets()
	local name, online, class, targets = nil, nil, nil, {}

	for i = 1, GetNumGroupMembers() do
		name, _, _, _, _, class, _, online = GetRaidRosterInfo(i)
		if online then
			AddNameToList(targets, AddOn:UnitName(name), class)
		end
	end

	return targets
end

function Sync:AvailableSyncTargets()
	local targets = {}

	Util.Tables.CopyInto(targets, self:AvailableGuildTargets())
	Util.Tables.CopyInto(targets, self:AvailableGroupTargets())

	if not AddOn:DevModeEnabled() then
		targets[AddOn.playerName] = nil
	end

	if Util.Tables.Count(targets) == 0 then
		targets[1] = format("-- %s --", L['no_recipients_avail'])
	else
		-- add guild and group targets, which will processed dynamically if selected
		targets[AddOn.Constants.guild] = UIUtil.SubjectTypeDecorator(Award.SubjectType.Guild):decorate(_G.GUILD)
		targets[AddOn.Constants.group] = UIUtil.SubjectTypeDecorator(Award.SubjectType.Raid):decorate(_G.GROUP)
	end

	-- table.sort(targets, function (a,b) return a > b end)
	Logging:Trace("%s", Util.Objects.ToString(targets))

	return targets
end

function Sync.ConfirmSyncOnShow(frame, data)
	UIUtil.DecoratePopup(frame)
	local sender, _, text = unpack(data)
	Logging:Trace("ConfirmSyncOnShow() : %s, %s", tostring(sender), tostring(text))
	frame.text:SetText(format(L["incoming_sync_message"], text, sender:GetName()))
end

function Sync:OnDataTransmit(num, total)
	if not self:IsEnabled() or not self.frame then
		return
	end

	Logging:Debug("OnDataTransmit(%d, %d)", num, total)
	local pct = (num/total) * 100
	self.frame.statusBar.Update(
			pct,
			Util.Numbers.Round2(pct) .. "% - " ..
			Util.Numbers.Round2(num/1000) .."KB / "..
			Util.Numbers.Round2(total/1000) .. "KB"
	)

	if num == total then
		AddOn:Print(format(L["sync_complete"], AddOn.GetDateTime()))
		Logging:Debug("OnDataTransmit() : Data transmission complete")
	end
end

function Sync:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'Sync', self:GetName(), L['frame_sync'], 400, 150, true)

		local type =
			AceUI('Dropdown')
				.SetWidth(f.content:GetWidth() * 0.4 - 20)
				.SetPoint("TOPLEFT", f.content, "TOPLEFT", 10, -50)
				.SetParent(f)()
		type:SetCallback(
				"OnValueChanged",
				function(_,_, key) self.type = key end
		)
		f.type = type
		f.type.Update = function()
			local syncTypes, syncTypesSort = self:HandlersSelect(), {}
			for i, v in pairs(Util.Tables.ASort(syncTypes, function(a,b) return a[2] < b[2] end)) do
				syncTypesSort[i] = v[1]
			end

			if not self.type then
				self.type = syncTypesSort[1]
			end

			f.type:SetList(syncTypes, syncTypesSort)
			f.type:SetValue(self.type)
			f.type:SetText(syncTypes[self.type])
		end

		local typeLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		typeLabel:SetPoint("TOPLEFT", f.content, "TOPLEFT", 15, -35)
		typeLabel:SetTextColor(1, 1, 1)
		typeLabel:SetText(L['sync_type'])
		f.typeLabel = typeLabel


		local target =
			AceUI('Dropdown')
				.SetWidth(f.content:GetWidth() * 0.6 - 20)
				.SetPoint("LEFT", f.type.frame, "RIGHT", 20, 0)
				.SetParent(f)()
		target:SetCallback(
				"OnValueChanged",
				function(_,_, key) self.target = key end
		)
		f.target = target
		f.target.Update = function()
			local availTargets, availTargetsSort = self:AvailableSyncTargets(), {}
			for i, v in pairs(Util.Tables.Sort(Util.Tables.Keys(availTargets), function(a,b)  return string.lower(a) < string.lower(b) end)) do
				availTargetsSort[i] = v
			end

			f.target:SetList(availTargets, availTargetsSort)
		end

		local targetLabel = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		targetLabel:SetPoint("BOTTOMLEFT", f.target.frame, "TOPLEFT", 0, 5)
		targetLabel:SetTextColor(1, 1, 1)
		targetLabel:SetText(L['sync_target'])
		f.targetLabel = targetLabel

		local close = UI:New('Button', f.content)
		close:SetText(_G.CLOSE)
		close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
		close:SetScript("OnClick", function() self:Disable() end)
		f.close = close

		local help = UI:New('Button', f.content)
		help:SetNormalTexture("Interface/GossipFrame/ActiveQuestIcon")
		help:SetSize(15,15)
		help:SetPoint("TOPRIGHT", f.content, "TOPRIGHT", -10, -10)
		help:SetScript("OnLeave", function() UIUtil:HideTooltip() end)
		help:SetScript("OnEnter", function()
			UIUtil.CreateTooltip(L["sync_header"], " ", L["sync_detailed_description"])
		end)
		f.help = help

		local sync = UI:New('Button', f.content)
		sync:SetText(L['sync'])
		sync:SetPoint("RIGHT", f.close, "LEFT", -10, 0)
		sync:SetScript(
				"OnClick",
				function()
					if not self.target then
						return AddOn:Print(L["sync_target_not_specified"])
					end
					if not self.type then
						return AddOn:Print(L["sync_type_not_specified"])
					end

					Logging:Debug("Sync() : %s, %s, %s", tostring(self.target), tostring(self.type), Util.Objects.ToString(self.handlers[self.type]))
					self:SendSyncSYN(self.target, self.type, self.handlers[self.type].send())
				end
		)
		f.sync = sync

		local statusBar = CreateFrame("StatusBar", nil, f.content, "TextStatusBar")
		statusBar:SetSize(f.content:GetWidth() - 20, 15)
		statusBar:SetPoint("TOPLEFT", f.type.frame, "BOTTOMLEFT", 0, -10)
		statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		statusBar:SetStatusBarColor(0.1, 0, 0.6, 0.8)
		statusBar:SetMinMaxValues(0, 100)
		statusBar:Hide()
		f.statusBar = statusBar

		statusBar.text = f.statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		statusBar.text:SetPoint("CENTER", f.statusBar)
		statusBar.text:SetTextColor(1,1,1)
		statusBar.text:SetText("")

		f.statusBar.Reset = function()
			f.statusBar:Hide()
			f.statusBar.text:Hide()
		end

		f.statusBar.Update = function(value, text)
			f.statusBar:Show()
			if tonumber(value) then f.statusBar:SetValue(value) end
			f.statusBar.text:Show()
			f.statusBar.text:SetText(text)
		end

		self.frame = f
		self.frame.Update = function()
			self.frame.type.Update()
			self.frame.target.Update()
			self.frame.statusBar.Reset()
		end
	end
end

function Sync:Show()
	if self.frame then
		self.frame.Update()
		self.frame:Show()
	end
end

function Sync:Hide()
	if self.frame then
		self.frame:Hide()
	end
end