--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...
local _, playerClass = UnitClass("player")
local debug = ns.debug

------------------------------------------------------------------------

local aura = {
	class = {
		DRUID = {
			-- feral
			5217, -- Tiger's Fury
			58180, -- Infected Wounds
			69369, -- Predatory Swiftness
			135700, -- Clearcasting
			-- guardian 
			158792, -- Pulverize
			159233, -- Ursa Major
			135286, -- Tooth & Claw
			63058, -- Glyph of Barkskin
		},
	},
	enchant = { 
		159234, -- Mark of the Thunderlord
		159675, -- Mark of Warsong
		173322, -- Mark of Bleeding Hollow
		159676, -- Mark of the Frostwolf
		159679, -- Mark of Blackrock
		159678, -- Mark of Shadowmoon
		159238, -- Mark of the Shattered Hand
	},
	override = {
		player = {},
		party = {},
		temp = {},
		boss = { -- applied by boss
			106648, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
			106784, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
			123059, -- Destabilize (Amber-Shaper Un'sok)
		},
		always = { -- whitelist
			178776, -- Rune of Power (Crit)
		},
		never = { -- blacklist
			116631, -- Colossus
			118334, -- Dancing Steel (agi)
			118335, -- Dancing Steel (str)
			104993, -- Jade Spirit
			116660, -- River's Song
			104509, -- Windsong (crit)
			104423, -- Windsong (haste)
			104510, -- Windsong (mastery)
		}
	},
}

local auraDB = {}

ns.UpdateAuraList = function()
	
	auraDB = {}
	
	-- compile the aura DB
	for c, t in pairs(aura) do
		if type(t) == 'table' then
			if not auraDB[c] then auraDB[c] = {} end
			for s, v in pairs(t) do
				if type(v) == 'number' then auraDB[c][v] = true end
				if type(v) == 'table' then
					if not auraDB[c][s] then auraDB[c][s] = {} end
					for _, v in pairs(v) do
						if type(v) == 'number' then auraDB[c][s][v] = true end
					end
				end
			end			
		end
	end
	
	-- Update all the things
	for _, obj in pairs(dUF.objects) do
		if obj.Auras then
			obj.Auras:ForceUpdate()
		end
		if obj.Buffs then
			obj.Buffs:ForceUpdate()
		end
		if obj.Debuffs then
			obj.Debuffs:ForceUpdate()
		end
	end
end

local unitIsPlayer = { player = true, pet = true, vehicle = true }
local unitIsParty = { party1 = true, party2 = true, party3 = true, party4 = true,
	raid1 = true, raid2 = true, raid3 = true, raid4 = true, raid5 = true, raid6 = true, raid7 = true, raid8 = true, raid9 = true, raid10 = true,
	raid11 = true, raid12 = true, raid13 = true, raid14 = true, raid15 = true, raid16 = true, raid17 = true, raid18 = true, raid19 = true, raid20 = true,
	raid21 = true, raid22 = true, raid23 = true, raid24 = true, raid25 = true, raid26 = true, raid27 = true, raid28 = true, raid29 = true, raid30 = true,
	raid31 = true, raid32 = true, raid33 = true, raid34 = true, raid35 = true, raid36 = true, raid37 = true, raid38 = true, raid39 = true, raid40 = true }
local unitIsBoss = { boss1 = true, boss2 = true, boss3 = true, boss4 = true }
	
local function smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, isPlayer, isDebuff)
	--[[
	debug("smartFilter", "[unit]", unit, "[caster]", caster, "[name]", name, "[id]", spellID, 
		"[count]", count, "[duration]", duration, "[expires]", expirationTime, 
		"[boss]", isBoss, "[player]", isPlayer)
	]]
	local filter = ns.config.filter
	local _, playerClass = UnitClass("player")
	local show = false
	local isTemp = (duration and duration > 0 and duration <= 30) or auraDB.override.temp[spellID]
	local isBoss = isBoss or unitIsBoss[caster] or auraDB.override.boss[spellID]
	local isPlayer = isPlayer or unitIsPlayer[caster] or auraDB.override.player[spellID]
	local isParty = unitIsParty[caster] or auraDB.override.party[spellID]

	if unitIsParty[unit] then 
		-- temp buffs you applied to yourself
		if isTemp and not isDebuff and isPlayer then show = true end
		-- temp debuffs applied to you
		if isTemp and isDebuff then show = true end
	else 
		-- temp buffs & debuffs you applied to others
		if isTemp and isPlayer then show = true end
	end
	
	-- show/hide all boss applied debuffs
	if isBoss and isDebuff then show = filter.boss end
 	-- show/hide temp party buffs on yourself
	if unitIsPlayer[unit] and isParty and isTemp then show = filter.party end
	-- show/hide trinket procs
	--if auraDB.trinket and auraDB.trinket[spellID] then show = filter.trinket end
	-- show/hide enchant procs
	if auraDB.enchant and auraDB.enchant[spellID] then show = filter.enchant end
	-- show/hide class procs
	if auraDB.class and auraDB.class[playerClass] and auraDB.class[playerClass][spellID] then show = filter.class end

	if auraDB.never and auraDB.never[spellID] then	show = false end
	if auraDB.always and auraDB.always[spellID] then show = true end
	
	if show then debug("Aura", spellID, name, "/", caster) end	
	return show
end

local function customFilter(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
	local show = true
	if ns.config.filter.enable then
		show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer, icon.isDebuff)
	end
	-- TODO: check player white/blacklist
	return show
end
		
ns.CustomAuraFilters = {
	player = customFilter,
	pet = customFilter,
	target = customFilter,
	targettarget = customFilter,
	focus = customFilter,
	focustarget = customFilter
}
