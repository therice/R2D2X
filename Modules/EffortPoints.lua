--- @type AddOn
local _, AddOn = ...
local L, C  = AddOn.Locale, AddOn.Constants
--- @type LibLogging
local Logging =  AddOn:GetLibrary("Logging")
--- @type LibUtil
local Util =  AddOn:GetLibrary("Util")
--- @type LibEncounter
local Encounter =  AddOn:GetLibrary("Encounter")
--- @type UI.Ace
local AceUI = AddOn.Require('UI.Ace')
--- @type Models.Award
local Award = AddOn.Package('Models').Award
--- @type LibDialog
local Dialog = AddOn:GetLibrary("Dialog")
--- @class EffortPoints
local EP = AddOn:NewModule('EffortPoints')

EP.defaults = {
	profile = {
		enabled = true,
		-- this is the minimum amount of EP needed to qualify for awards
		ep_min  = 1,
		raid = {
			-- should EP be auto-awarded for kills
			auto_award_victory = true,
			-- should EP be awarded for defeats
			award_defeat       = false,
			-- should EP be auto-awarded for wipes
			auto_award_defeat  = false,
			-- the percent of victory EP to award on defeat
			award_defeat_pct   = 0.25,
			-- EP values by creature (id)
			-- These are represented as strings instead of numbers in order to facilitate
			-- easy access by path when reading/writing values
			creatures          = {
				-- AQ20
				-- Kurinaxx
				['15348']            = 7,
				-- Rajaxx
				['15341']            = 7,
				-- Moam
				['15340']            = 7,
				-- Buru
				['15370']            = 7,
				-- Ayamiss
				['15369']            = 7,
				-- Ossirian
				['15339']            = 10,
				-- ZG
				-- Venoxis
				['14507']            = 5,
				-- Jeklik
				['14517']            = 5,
				-- Marli
				['14510']            = 5,
				-- Thekal
				['14509']            = 5,
				-- Arlokk
				['14515']            = 5,
				-- Mandokir
				['11382']            = 7,
				-- Gahzranka
				['15114']            = 5,
				-- Edge of Madness
				['edge_of_madness']  = 5,
				-- Jindo
				['11380']            = 7,
				-- Hakkar
				['14834']            = 8,
				-- MC
				-- Lucifron
				['12118']            = 10,
				-- Magmadar
				['11982']            = 10,
				-- Gehennas
				['12259']            = 10,
				-- Garr
				['12057']            = 10,
				-- Geddon
				['12056']            = 10,
				-- Shazzrah
				['12264']            = 10,
				-- Sulfuron
				['12098']            = 10,
				-- Golemagg
				['11988']            = 10,
				-- Domo
				['12018']            = 12,
				-- Ragnaros
				['11502']            = 14,
				-- Onyxia's Lair
				-- Onyxia
				['10184']            = 12,
				-- BWL
				-- Razorgore
				['12435']            = 20,
				-- Vaelastrasz
				['13020']            = 20,
				-- Broodlord
				['12017']            = 20,
				-- Firemaw,
				['11983']            = 20,
				-- Ebonroc
				['14601']            = 20,
				-- Flamegor
				['11981']            = 20,
				-- Chromaggus
				['14020']            = 24,
				-- Nefarian
				['11583']            = 28,
				-- AQ40
				-- Skeram
				['15263']            = 26,
				-- Silithid Royalty (Three Bugs)
				['silithid_royalty'] = 26,
				-- Battleguard Sartura
				['15516']            = 26,
				-- Fankriss the Unyielding
				['15510']            = 26,
				-- Viscidus
				['15299']            = 26,
				-- Princess Huhuran
				['15509']            = 26,
				-- Ouro
				['15517']            = 26,
				-- Twin Emperors
				['twin_emperors']    = 32,
				-- C'Thun
				['15727']            = 38,
				-- Naxx
				-- Anub'Rekhan
				['15956']            = 30,
				-- Faerlina
				['15953']            = 30,
				--  Maexxna
				['15952']            = 33,
				-- Noth
				['15954']            = 30,
				-- Heigan
				['15936']            = 30,
				-- Loatheb
				['16011']            = 33,
				-- Razuvious
				['16061']            = 30,
				-- Gothik
				['16060']            = 30,
				-- Four Horsemen
				['four_horsemen']    = 36,
				-- Patchwerk
				['16028']            = 30,
				-- Grobbulus
				['15931']            = 30,
				-- Gluth
				['15932']            = 30,
				-- Thaddius
				['15928']            = 33,
				-- Sapphiron
				['15989']            = 42,
				-- Kel'Thuzad
				['15990']            = 50,
			},
			maps = {

			}
		}
	}
}

do
	local defaults = EP.defaults.profile.raid.maps
	-- update defaults to set scaling off for all raids
	for mapId, _ in pairs(Encounter.Maps) do
		defaults[tostring(mapId)] = {
			scaling = false,
			scaling_pct = 1.0,
		}
	end
end


function EP:OnInitialize()
	Logging:Debug("OnInitialize(%s)", self:GetName())
	self.db = AddOn.db:RegisterNamespace(self:GetName(), EP.defaults)
end

function EP:OnEnable()
	Logging:Debug("OnEnable(%s)", self:GetName())
end

function EP:OnDisable()
	Logging:Debug("OnEnable(%s)", self:GetName())
end


-- Mapping from translation key to actual creatures are part of encounter
local MultiCreatureEncounters = {
	['edge_of_madness']  = Encounter:GetEncounterCreatureId(788),
	['silithid_royalty'] = Encounter:GetEncounterCreatureId(710),
	['twin_emperors']    = Encounter:GetEncounterCreatureId(715),
	['four_horsemen']    = Encounter:GetEncounterCreatureId(1121),
}

--- @param value number
--- @param mapId number
--- @return number
function EP:ScaleIfRequired(value, mapId)
	Logging:Trace("ScaleIfRequired() : value = %s, mapId = %s", tostring(value), tostring(mapId))

	if Util.Objects.IsNil(mapId) then
		-- only applicable if in instance and part of a raid
		if IsInInstance() and IsInRaid() then
			_, _, _, _, _, _, _, mapId = GetInstanceInfo()
			Logging:Trace("ScaleIfRequired() : mapId = %s via GetInstanceInfo()", tostring(mapId))
		end

		-- check again, if not found then return value
		if Util.Objects.IsNil(mapId) then
			Logging:Trace("ScaleIfRequired() : Unable to determine map id, returning original value")
			return value
		end
	end

	local raidScalingSettings =
		AddOn:HaveMasterLooterDb() and
		AddOn:MasterLooterDbValue('raid', tostring(mapId)) or
		self:GetDbValue('raid.maps', tostring(mapId))

	Logging:Debug("ScaleIfRequired() : mapId = %s, scaling_settings = %s", tostring(mapId), Util.Objects.ToString(raidScalingSettings))
	if raidScalingSettings then
		local scaleAward = raidScalingSettings.scaling or false
		local scalePct = raidScalingSettings.scaling_pct or 1.0
		-- if the raid has reduced (scaled) awards, apply them now
		if scaleAward then
			local scaled = Util.Numbers.Round(value * scalePct)
			Logging:Debug("ScaleIfRequired() : Scaling %d by %.1f %% = %d", value, (scalePct * 100.0), scaled)
			return scaled
		else
			Logging:Debug("ScaleIfRequired() : Scaling disabled for mapId = %s , returning original value", tostring(mapId))
			return value
		end
	else
		Logging:Debug("ScaleIfRequired() : No scaling settings available for mapId = %s , returning original value", tostring(mapId))
		return value
	end
end

--- @param encounter Models.Encounter
function EP:OnEncounterEnd(encounter)
	-- don't adjust EP if disabled or not handling loot
	if not AddOn.enabled or not AddOn.handleLoot then
		Logging:Warn(
				"OnEncounterEnd() : not handling encounter end, enabled=%s, handleLoot=%s",
	             tostring(AddOn.enabled), tostring(AddOn.handleLoot)
		)
		return
	end

	if not encounter then
		Logging:Warn("OnEncounterEnd() : no encounter provided")
		return
	end

	-- (1) lookup associated EP for encounter
	-- (2) scale based upon victory/defeat
	-- (3) award to current members of raid
	-- (4) award to anyone on standby (bench), scaled by standby percentage

	-- basic settings for awarding EP based upon encounter
	local autoAwardVictory =  self.db.profile.raid.auto_award_victory
	local awardDefeat = self.db.profile.raid.award_defeat
	local autoAwardDefeat = self.db.profile.raid.auto_award_defeat

	local creatureIds = Encounter:GetEncounterCreatureId(encounter.id)
	local mapId = Encounter:GetEncounterMapId(encounter.id)
	Logging:Debug("OnEncounterEnd(%s) : mapId = %s, creatureIds = %s",
	              Util.Objects.ToString(encounter:toTable()),
	              tostring(mapId),
	              Util.Objects.ToString(creatureIds)
	)


	if creatureIds then
		local success = encounter:IsSuccess()
		-- normalize creature ids into a table, typically will only be one but may be multiple
		if not Util.Objects.IsTable(creatureIds) then
			creatureIds = { creatureIds }
		end

		local creatureEp
		-- this will handle the typical case with one creature per encounter
		for _, id in pairs(creatureIds) do
			creatureEp = self.db.profile.raid.creatures[tostring(id)]
			if not Util.Objects.IsNil(creatureEp) then
				break
			end
		end

		-- didn't find the mapping, see if there is a  match in our multiple creature encounters
		if Util.Objects.IsNil(creatureEp) then
			creatureIds = Util.Tables.Sort(creatureIds)
			for encounter_name, creatures in pairs(MultiCreatureEncounters) do
				local compareTo = Util.Tables.Sort(Util.Tables.Copy(creatures))
				if Util.Tables.Equals(creatureIds, compareTo) then
					creatureEp = self.db.profile.raid.creatures[encounter_name]
					break
				end
			end
		end

		Logging:Debug("OnEncounterEnd(%s) : EP = %d",
		              Util.Objects.ToString(encounter:toTable()), tonumber(creatureEp)
		)

		-- have EP and either victory or defeat with awarding of defeat EP
		if creatureEp and (success or (not success and awardDefeat)) then
			creatureEp = tonumber(creatureEp)
			-- if defeat, scale EP based upon defeat percentage
			if not success then
				creatureEp = Util.Numbers.Round(creatureEp * self.db.profile.raid.award_defeat_pct)
				Logging:Debug("OnEncounterEnd(%s) : EP (Defeat) = %d",
				              Util.Objects.ToString(encounter:toTable()), tonumber(creatureEp)
				)
			end

			creatureEp = self:ScaleIfRequired(creatureEp, mapId)
			local award = Award()
			-- track the instance and encounter, can be used later for determining
			-- raid attendance and more neat stuff
			award.instanceId = mapId
			award.encounterId = encounter.id
			-- implicitly to group/raid
			award:SetSubjects(Award.SubjectType.Raid)
			award:SetAction(Award.ActionType.Add)
			award:SetResource(Award.ResourceType.Ep, creatureEp)
			award.description = format(
					success and L["award_n_ep_for_boss_victory"] or L["award_n_ep_for_boss_defeat"],
					creatureEp, encounter.name
			)

			-- Logging:Debug("OnEncounterEnd() : %s", Util.Objects.ToString(award:toTable(), 10))

			if (success and autoAwardVictory) or (not success and autoAwardDefeat) then
				AddOn:StandingsModule():Adjust(award)
			else
				Dialog:Spawn(C.Popups.ConfirmAdjustPoints, award)
			end

			-- now look at standby\
			local standbyRoster, standbyAwardPct = AddOn:StandbyModule():GetAwardRoster()
			if standbyRoster and Util.Tables.Count(standbyRoster) > 0 and standbyAwardPct then
				award = Award()
				award.instanceId = mapId
				award.encounterId = encounter.id
				award:SetSubjects(Award.SubjectType.Standby, standbyRoster)
				award:SetAction(Award.ActionType.Add)
				award:SetResource(Award.ResourceType.Ep, Util.Numbers.Round(creatureEp * standbyAwardPct))
				award.description = L["standby"] .. ' : ' .. format(
						success and L["award_n_ep_for_boss_victory"] or L["award_n_ep_for_boss_defeat"],
						creatureEp, encounter.name
				)

				-- todo : do we want to prompt for standby/bench awards?
				AddOn:PointsModule():Adjust(award)
			end
		else
			Logging:Warn("OnEncounterEnd(%s) : EP not found or awarded for creature id(s) %s, EP=%s",
			             Util.Objects.ToString(encounter:toTable()),
			             Util.Objects.ToString(creatureIds),
			             tostring(creatureEp)
			)
		end
	else
		Logging:Warn("OnEncounterEnd(%s) : no creature id found for encounter",  Util.Objects.ToString(encounter:toTable()))
	end
end

--- @return table
local Options = Util.Memoize.Memoize(function(self)
	-- base template upon which we'll be attaching additional options
	local builder = AceUI.ConfigBuilder()

	builder:group(self:GetName(), L["ep"]):desc(L["ep_desc"])
		:args()
			:group('awards', L['awards']):desc(L['awards_desc']):set('childGroups', 'tab'):order(1)
				:args()
					:group('general', L['general_options']):set('inline', true):order(1)
						:args()
							:range("ep_min", L["minimum"], 0, 1000):desc(L["ep_min_desc"]):order(1)
						:close()
					:group('auto_award_settings', L['awards']):set('inline', true):order(2)
						:args()
							:toggle('raid.auto_award_victory', L["auto_award_victory"]):desc(L["auto_award_victory_desc"]):order(1)
							:toggle('raid.award_defeat', L["award_defeat"]):desc(L["award_defeat_desc"]):order(2)
							:toggle('raid.auto_award_defeat', L["auto_award_defeat"]):desc(L["auto_award_defeat_desc"]):order(3)
								:set('disabled', function() return not self.db.profile.raid.award_defeat end)
							:range("raid.award_defeat_pct", L["award_defeat_pct"], 0, 1, 0.1):desc(L["award_defeat_pct_desc"]):order(4)
								:set('isPercent', true)
								:set('disabled', function () return not self.db.profile.raid.award_defeat end)
						:close()
				:close()
			:group('raid', L['raids']):desc(L['raids_desc']):set('childGroups', 'select'):order(2)
				:args()

	-- table for storing processed defaults which needed added as arguments
	-- Creatures indexed by map name
	local creature_ep = Util.Tables.New()

	-- iterate all the creatures and group by map (instance)
	for id, _ in pairs(EP.defaults.profile.raid.creatures) do
		-- if you don't convert to number, library calls will fail
		local creature_id, creature, map = tonumber(id)
		-- also need to account for multi-creature encounters wherein display name
		-- is not one of the individual creatures
		if creature_id then
			creature, map = Encounter:GetCreatureDetail(creature_id)
		else
			-- take name from localization
			creature = L[id]
			creature_id = id
			_, map = Encounter:GetCreatureDetail(MultiCreatureEncounters[id][1])
		end

		local creatures = creature_ep[map] or Util.Tables.New()
		Util.Tables.Push(creatures, {
			creature_id = creature_id,
			creature_name = creature,
		})
		creature_ep[map] = creatures
	end

	builder:SetPath(self:GetName() .. '.args.raid.args')
	local index = 1
	for _, map in pairs(Util.Tables.Sort(Util.Tables.Keys(creature_ep))) do
		-- key will be the map name
		-- add settings for scaling (reducing) EP and GP awards from the raid
		local mapId = Encounter:GetMapId(map)
		-- Logging:Debug("%s -> %s", Util.Objects.ToString(map), tostring(mapId))
		if mapId then
			local settingPrefix = 'raid.maps.' .. tostring(mapId) .. '.'
			builder
				:group('map_'..tostring(mapId), map):desc(map):order(index)
					:args()
						:toggle(settingPrefix .. 'scaling', L["scale_ep_gp"]):desc(L["scale_ep_gp_desc"]):order(1)
						:range(settingPrefix .. 'scaling_pct', L["scale_ep_gp_pct"], 0, 1, 0.01):order(2)
							:desc(L['scale_ep_gp_pct_desc'])
							:set('width', 'full'):set('isPercent', true)
							:set('hidden', function () return not self.db.profile.raid.maps[tostring(mapId)]['scaling'] end)

			for _, c in pairs(creature_ep[map]) do
				builder:group(Util.Strings.ToCamelCase(c.creature_name), c.creature_name)
						:args()
							:range('raid.creatures.' .. tostring(c.creature_id), L["ep"], 1, 100, 1):desc(L['ep_victory'])
						:close()
			end

			-- close out the map group, as all creatures have been added
			builder:close()
		end

		index = index + 1
	end

	return builder:build()
end)


function EP:BuildConfigOptions()
	local options = Options(self)
	-- Logging:Debug("%s", Util.Objects.ToString(options, 8))
	return options[self:GetName()], true
end