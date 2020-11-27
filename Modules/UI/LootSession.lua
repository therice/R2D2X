--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type UI.Native
local UI = AddOn.Require('UI.Native')
--- @type UI.ScrollingTable
local ST = AddOn.Require('UI.ScrollingTable')
--- @type LootSession
local LootSession = AddOn:GetModule('LootSession')

local ScrollColumns =
	ST.ColumnBuilder()
		:column(""):width(30)   -- remove item (1)
		:column(""):width(40)   -- item icon (2)
		:column(""):width(50)   -- item level (3)
		:column(""):width(160)  -- item link (4)
	:build()

function LootSession:GetFrame()
	if not self.frame then
		local f = UI:NewNamed('Frame', UIParent, 'LootSession', 'LootSession', L['frame_loot_session'], 450, 305, false)

		local st = ST.New(ScrollColumns, 5, 40, nil, f.content)
		-- disable sorting
		st:RegisterEvents({
          ["OnClick"] = function(_, _, _, _, row, realrow)
              if not (row or realrow) then
                  return true
              end
          end,
        })

		local start = UI:NewNamed('Button', f.content, "Start")
		start:SetText(_G.START)
		start:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
		start:SetScript("OnClick", function() self:Start() end)
		f.start = start

		local cancel = UI:NewNamed('Button', f.content, "Cancel")
		cancel:SetText(_G.CANCEL)
		cancel:SetPoint("LEFT", start, "RIGHT", 15, 0)
		start:SetScript("OnClick", function() self:Cancel() end)
		f.cancel = cancel


		f.Update = function()
			-- todo
			--if ML.running then
			--	self.frame.start:SetText(_G.ADD)
			--else
			--	self.frame.start:SetText(_G.START)
			--end
		end

		self.frame = f
	end

	return self.frame
end

function LootSession:IsRunning()
	return self.frame and self.frame:IsVisible()
end


function LootSession:Show(items)
	local frame = self:GetFrame()
	frame:Show()

	if items then
		self.loadingItems = true
		self:AddItems(items)
		frame.Update()
	end
end

function LootSession:AddItems(items)
	if self.frame then
		self.frame.rows = {}
		for session, item in pairs(items) do

		end

		self.frame.st:SetData(self.frame.rows)
	end
end

function LootSession:Update()

end

function LootSession:Hide()
	if self.frame then
		self.frame:Hide()
	end
end
