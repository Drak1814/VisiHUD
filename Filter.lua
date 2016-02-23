--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...
local _, _, playerClass = UnitClass("player")
local debug = ns.debug

ns.aura.filter = {}
ns.aura.effect = {}

ns.UpdateAuraFilter = function()

	ns.aura.filter = {}
	ns.aura.effect = {}

	-- compile the filters & effects
	for s, t in pairs(ns.auraSet) do
		if type(t) == 'table' then
			if ns.config.filter[s] ~= nil then
				if ns.config.filter[s] and ns.config.filter[s].enabled then
					local show = ns.config.filter[s].show
					local effect = ns.config.filter[s].effect
					for _, v in ipairs(t.auras) do
						if not v.class or v.class == playerClass then
							if type(v.id) == 'number' then
								ns.aura.filter[v.id] = show
								ns.aura.effect[v.id] = effect
							elseif type(v.id) == 'table' then
								for _, v in ipairs(v.id) do
									if type(v) == 'number' then
										ns.aura.filter[v] = show
										ns.aura.effect[v] = effect
									end
								end
							end
						end
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

local tracker = {}

local function smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, isPlayer, isDebuff)
	--[[
	debug("smartFilter", "[unit]", unit, "[caster]", caster, "[name]", name, "[id]", spellID,
		"[count]", count, "[duration]", duration, "[expires]", expirationTime,
		"[boss]", isBoss, "[player]", isPlayer)
	]]

	local show = false
	local isTemp = (duration and duration > 0 and duration <= 60) or ns.aura.override.temp[spellID]
	local isBoss = isBoss or unitIsBoss[caster] or ns.aura.override.boss[spellID]
	local isPlayer = isPlayer or unitIsPlayer[caster] or ns.aura.override.player[spellID]
	local isParty = unitIsParty[caster] or ns.aura.override.party[spellID]
	local unitname = GetUnitName(unit, true)

	-- never show if you are the targettarget
	if unit == "targettarget" and unitname == ns.playername then return false end
	-- never show "Glyph of" Buffs
	if name and string.find(name, "^Glyph of ") then return false end

	if unitIsPlayer[unit] or unit == 'targettarget' then
		-- temp buffs you applied
		if isTemp and not isDebuff and isPlayer then show = true end
		-- temp debuffs from anything
		if isTemp and isDebuff then show = true end
	else
		-- temp buffs & debuffs you applied to others
		if isTemp and isPlayer then show = true end
	end

	-- show/hide all boss applied debuffs
	if isBoss and isDebuff then show = ns.config.smartFilter.boss end
	-- show/hide temp party buffs on yourself
	if unitIsPlayer[unit] and not isDebuff and isParty and isTemp then show = ns.config.smartFilter.party end

	if ns.aura.override.never and ns.aura.override.never[spellID] then show = false end
	if ns.aura.override.always and ns.aura.override.always[spellID] then show = true end

	if ns.config.debug then
		if not tracker[unit] then tracker[unit] = {} end
		if not tracker[unit][spellID] then
			debug("Aura",
				format("(%s) %d %s (%s)", unit, spellID, name, caster),
				table.concat({
					isDebuff and 'D' or '-',
					isTemp and 'T' or '-',
					isBoss and 'B' or '-',
					isPlayer and 'P' or '-',
					isParty and 'Y' or '-'
				}),
				(show and 'SHOW' or 'HIDE')
			)
			tracker[unit][spellID] = time() + 10
		else
			if time() > tracker[unit][spellID] then
				tracker[unit][spellID] = nil
			end
		end
	end

	return show

end

local function customFilter(self, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBoss)
	local show = true
	local caster = caster or 'unknown'
	if ns.config.smartFilter.enable then
		show = smartFilter(unit, caster, name, spellID, count, duration, expirationTime, isBoss, icon.isPlayer, icon.isDebuff)
	end
	-- apply current compiled aura filter
	if ns.aura.filter[spellID] ~= nil then show = ns.aura.filter[spellID] end
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
