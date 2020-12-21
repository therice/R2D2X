--- @type AddOn
local _, AddOn = ...
local L, C = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
local Models = AddOn.ImportPackage('Models')
--- @type Models.Date
local Date = Models.Date

--- @class Models.StandbyMember
local StandbyMember = AddOn.Package('Models'):Class('StandbyMember')
--- @class Models.StandbyStatus
local StandbyStatus = AddOn.Package('Models'):Class('StandbyStatus')

local function processContacts(contacts, timestamp)
	local processed = Util.Tables.New()
	-- only support a single name via contacts (if a string)
	if Util.Objects.IsString(contacts) then
		processed[AddOn.Ambiguate(contacts)] = {}
	elseif  Util.Objects.IsTable(contacts) then
		for _, name in pairs(contacts) do
			processed[AddOn.Ambiguate(name)] = {}
		end
	else
		error("Invalid type for parameter 'contacts' : " .. contacts and type(contacts) or 'nil')
	end

	Util.Tables.Map(
			processed,
			function() return StandbyStatus(timestamp, false) end
	)

	return processed
end

function StandbyMember:initialize(name, class, contacts, joined)
	-- If the name is nil, create an empty instance
	-- probably not the best approach, but for now it will do
	if Util.Objects.IsNil(name) then return end

	if not Date.isInstanceOf(joined, Date) then
		joined = joined and Date(joined) or Date('utc')
	end

	self.name = name
	self.class = class
	self.joined = joined.time
	self.status = StandbyStatus(self.joined, true)
	self.contacts = processContacts(contacts or {}, self.joined)
end

function StandbyMember:afterReconstitute(instance)
	instance.status = StandbyStatus(instance.status.timestamp, instance.status.online)
	instance.contacts = Util.Tables.Map(
			instance.contacts,
			function(e) return StandbyStatus:reconstitute(e) end
	)
	return instance
end

function StandbyMember:JoinedTimestamp()
	return self.joined
end

function StandbyMember:PingedTimestamp()
	return self.status:PingedTimestamp()
end

function StandbyMember:IsPlayer(name)
	return AddOn.UnitIsUnit(self.name, name)
end

function StandbyMember:IsContact(name)
	for contact, _ in pairs(self.contacts) do
		if AddOn.UnitIsUnit(contact, name) then
			return true
		end
	end

	return false
end

function StandbyMember:IsPlayerOrContact(name)
	return self:IsPlayer(name) or self:IsContact(name)
end

function StandbyMember:UpdateStatus(name, online)
	if self:IsPlayer(name) then
		self.status = StandbyStatus(nil, online)
	elseif self:IsContact(name) then
		self.contacts[AddOn.Ambiguate(name)] = StandbyStatus(nil, online)
	end
end

function StandbyMember:IsOnline()
	local online = self.status.online
	if not online then
		online = Util.Tables.CountFn(self.contacts, function(status) return status.online and 1 or 0 end) > 0
	end
	return online
end

function StandbyStatus:initialize(timestamp, online)
	if not Date.isInstanceOf(timestamp, Date) then
		timestamp = timestamp and Date(timestamp) or Date('utc')
	end

	self.timestamp = timestamp.time
	self.online = online
end


function StandbyStatus:PingedTimestamp()
	return self.timestamp
end