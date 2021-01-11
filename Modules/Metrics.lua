--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type Core.Comm
local Comm = AddOn.RequireOnUse('Core.Comm')
--- @type Core.Event
local Event = AddOn.RequireOnUse('Core.Event')

--- @class Metrics
local Metrics = AddOn:NewModule("Metrics")

local MetricsType = {
	Comms  = 1,
	Events = 2,
}

Metrics.MetricsType = MetricsType

function Metrics:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.metricType = -1
	self.alarm = AddOn.Alarm(1.0, function () self:Update() end)
end

function Metrics:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self:GetFrame()
	self.alarm:Start()
	self:Show()
end

function Metrics:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.alarm:Stop()
	self:Hide()
end

function Metrics:GetMetrics()
	--- @type table<number, Models.Metrics>
	local rawMetrics
	if Util.Objects.Equals(self.metricType, MetricsType.Comms) then
		rawMetrics = Comm():GetMetrics()
	elseif Util.Objects.Equals(self.metricType, MetricsType.Events) then
		rawMetrics = Event():GetMetrics()
	end

	local metrics = {}
	if rawMetrics then
		for _, metric in pairs(rawMetrics) do
			Util.Tables.Push(metrics, metric:Summarize())
		end
	end

	return metrics
end