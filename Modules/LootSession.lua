--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @class LootSession
local LootSession = AddOn:NewModule('LootSession')

function LootSession:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
end

function LootSession:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
	self.loadingItems = false
end

function LootSession:OnDisable()
	Logging:Debug("OnDisable(%s)", self:GetName())
	self.loadingItems = false
end

function LootSession:EnableOnStartup()
	return false
end

function LootSession:Start()
	-- todo
	-- self:StartMLSession()
end

function LootSession:Cancel()
	-- todo
	-- ML.lootTable = {}
	self:Disable()
end
