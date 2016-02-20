--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...

-- TODO: replace with Aura List Library
--[=[
local cID = ns.classID
local sID = ns.specID

ns.defaultAuras = {
	class = {
		title = "Class Ability Procs",
		auras = {
			-- DRUID
			-- Feral
			{ id = 5217, class = cID.Druid }, -- Tiger's Fury
			{ id = 58180, class = cID.Druid }, -- Infected Wounds
			{ id = 69369, class = cID.Druid }, -- Predatory Swiftness
			{ id = 135700, class = cID.Druid }, -- Clearcasting
			-- Guardian
			{ id = 158792, class = cID.Druid }, -- Pulverize
			{ id = 159233, class = cID.Druid }, -- Ursa Major
			{ id = 135286, class = cID.Druid }, -- Tooth & Claw
			{ id = 63058, class = cID.Druid }, -- Glyph of Barkskin
			-- Restoration
			{ id = 158478, class = cID.Druid }, -- Soul of the Forest
			{ id = 16879, class = cID.Druid }, -- Clearcasting
		}
	},
	enchant = {
		title = "Weapon Enchant Procs",
		auras = {
			{ id = 159234 }, -- Mark of the Thunderlord
			{ id = 159675 }, -- Mark of Warsong
			{ id = 173322 }, -- Mark of Bleeding Hollow
			{ id = 159676 }, -- Mark of the Frostwolf
			{ id = 159679 }, -- Mark of Blackrock
			{ id = 159678 }, -- Mark of Shadowmoon
			{ id = 159238 }, -- Mark of the Shattered Hand
		}
	},
}
]=]

ns.aura = {
	override = {
		player = { -- applied by player
		},
		party = { -- applied by party
		},
		temp = { -- temporary auras
		},
		boss = { -- applied by boss
			[106648] = true, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
			[106784] = true, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
			[106784] = true, -- Brew Explosion (Ook Ook in Stormsnout Brewery)
			[123059] = true, -- Destabilize (Amber-Shaper Un'sok)
		},
		always = { -- whitelist
		},
		never = { -- blacklist
			[116631] = true, -- Colossus
			[104993] = true, -- Jade Spirit
		}
	}
}
