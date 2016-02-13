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
-- dynamic rules: all auras shown by default, 
-- filtered by player-cast OR boss-cast AND temporary

local override = {
	player = { -- applied by player
		[127372] = true -- Unstable Serum (Klaxxi Enhancement: Raining Blood)
	},
	boss = { -- applied by boss
		[106648] = true, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
		[106784] = true, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
		[123059] = true -- Destabilize (Amber-Shaper Un'sok)
	},
	temp = { -- temporary auras
	},
	class = { -- class procs
		DRUID = {
			-- feral
			[58180] = true, -- Infected Wounds
			[69369] = true, -- Predatory Swiftness
			[135700] = true, -- Clearcasting
			-- guardian 
			[158792] = true, -- Pulverize
			[159233] = true, -- Ursa Major
			[135286] = true, -- Tooth & Claw
			[63058] = true, -- Glyph of Barkskin
		}
	},
	always = { -- whitelist
		[178776] = true, -- Rune of Power (Crit)
	},
	never = { -- blacklist
		[116631] = true, -- Colossus
		[118334] = true, -- Dancing Steel (agi)
		[118335] = true, -- Dancing Steel (str)
		[104993] = true, -- Jade Spirit
		[116660] = true, -- River's Song
		[104509] = true, -- Windsong (crit)
		[104423] = true, -- Windsong (haste)
		[104510] = true, -- Windsong (mastery)
		-- trinkets
		[183926] = true, -- Malicious Censor
	}
}

ns.UpdateAuraList = function()
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
	
local function smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, isPlayer)
	--[[
	debug("smartFilter", "[unit]", unit, "[caster]", caster, "[name]", name, "[id]", spellID, 
		"[count]", count, "[duration]", duration, "[expires]", expirationTime, 
		"[boss]", isBoss, "[player]", isPlayer)
	]]
	local filter = ns.config.filter
	local _, playerClass = UnitClass("player")
	local show = false
	if filter.player then
		if isPlayer or override.player[spellID] then show = true end
	end
	if filter.boss then
		if isBoss or override.boss[spellID] then show = true end
	end
	if filter.temp and show then
		if (not duration or duration == 0 or duration > 30) and not override.temp[spellID] then show = false end
	end

	if override.class[playerClass][spellID] then show = filter.class end

	if override.never[spellID] then show = false end
	if override.always[spellID] then show = true end
	-- TODO: check player white/blacklist
	return show
end
		
local filterFuncs = {
	player = function(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
		local show = true
		if ns.config.filter.enable then
			show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer)
		end
		if show then debug("Aura", spellID, name) end
		return show
	end,
	pet = function(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
		local show = true
		if ns.config.filter.enable then
			show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer)
		end
		if show then debug("Aura", spellID, name) end
		return show
	end,
	target = function(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
		local show = true
		if ns.config.filter.enable then
			show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer)
		end
		if show then debug("Aura", spellID, name) end
		return show
	end,
	targettarget = function(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss3)
		local show = true
		if ns.config.filter.enable then
			show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer)
		end
		if show then debug("Aura", spellID, name) end
		return show
	end,	
	focus = function(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
		local show = true
		if ns.config.filter.enable then
			show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer)
		end
		if show then debug("Aura", spellID, name) end
		return show
	end,
	focustarget = function(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
		local show = true
		if ns.config.filter.enable then
			show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer)
		end
		if show then debug("Aura", spellID, name) end
		return show
	end	
}

ns.CustomAuraFilters = filterFuncs
