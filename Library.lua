--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...
local cID = ns.classID
local sID = ns.specID

ns.lib = {}

ns.lib.tracker = {
	[sID[cID.Hunter].Beastmaster] = {
		{type = "spell", id = 34026}, -- Kill Command
		{type = "spell", id = 53351}, -- Kill Shot
		{type = "spell", id = 120360}, -- Barrage
		{type = "spell", id = 5116}, -- Concussive Shot
		{type = "spell", id = 20736}, -- Distracting Shot
		{type = "spell", id = 34477}, -- Misdirection
		{type = "spell", id = 19801}, -- Tranquilizing Shot
		-- Interrupt
		{type = "spell", id = 147362}, -- Counter Shot
		-- Defensives
		{type = "spell", id = 781}, -- Disengage
		{type = "spell", id = 19263}, -- Deterrence
		{type = "spell", id = 538}, -- Feign Death
		-- Level 30 talents
		{type = "spell", id = 109248}, -- Binding Shot
		{type = "spell", id = 19386}, -- Wyvern Sting
		{type = "spell", id = 19577}, -- Intimidation

	},
	[sID[cID.Warrior].Protection] = {
		{type = "spell", id = 355}, -- Taunt
		{type = "spell", id = 6572}, -- Revenge
		{type = "spell", id = 23922}, -- Shield Slam
		{type = "spell", id = 6343}, -- Thunder Clap
		{type = "spell", id = 5308}, -- Execute
		{type = "spell", id = 100}, -- Charge
		-- Interrupt
		{type = "spell", id = 6552}, -- Pummel
		-- Defensives
		{type = "spell", id = 2565}, -- Shield Block
		{type = "spell", id = 156321}, -- Shield Charge
		{type = "spell", id = 871}, -- Shield Wall
		{type = "spell", id = 34428}, -- Victory Rush
		-- Mobility
		{type = "spell", id = 6544}, -- Heroic Leap
		-- Buffs
		{type = "spell", id = 18499}, -- Berserker Rage
		-- Level 30 talents
		{type = "spell", id = 55694}, -- Enraged Regeneration
		{type = "spell", id = 103840}, -- Impending Victory
		-- Level 60 talents
		{type = "spell", id = 107570}, -- Storm Bolt
		{type = "spell", id = 46968}, -- Shockwave
		{type = "spell", id = 118000}, -- Dragon Roar
		-- Level 90 talents
		{type = "spell", id = 107574}, -- Avatar
		{type = "spell", id = 12292}, -- Bloodbath
		{type = "spell", id = 46924}, -- Bladestorm
		-- Level 100 talents
		{type = "spell", id = 152277}, -- Ravager
	},
	[sID[cID.Druid].Feral] = {
		-- Interrupt
		{name = "Skull Bash"},
		-- Defensives
		{name = "Survival Instincts"},
		-- Mobility
		{name = "Stampeding Roar"},
		-- Buffs
		{name = "Tiger's Fury"},
		-- Level 15 talents
		{name = "Displacer Beast"},
		{name = "Wild Charge"},
		-- Level 30 talents
		{name = "Renewal"},
		{name = "Cenarion Ward"},
		-- Level 45 talents
		{name = "Mass Entanglement"},
		{name = "Typhoon"},
		-- Level 60 talents
		{name = "Force of Nature"},
		-- Level 75 talents
		{name = "Incapacitating Roar"},
		{name = "Ursol's Vortex"},
		{name = "Mighty Bash"},
		-- Level 90 talents
		{name = "Heart of the Wild"},
		{name = "Nature's Vigil"}
	},
	[sID[cID.Druid].Guardian] = {
		{name = "Maul"},
		{name = "Mangle"},
		-- Interrupt
		{name = "Skull Bash"},
		-- Defensives
		{name = "Savage Defense"},
		{name = "Barkskin"},
		{name = "Survival Instincts"},
		-- Mobility
		{name = "Stampeding Roar"},
		-- Level 15 talents
		{name = "Displacer Beast"},
		{name = "Wild Charge"},
		-- Level 30 talents
		{name = "Renewal"},
		{name = "Cenarion Ward"},
		-- Level 45 talents
		{name = "Mass Entanglement"},
		{name = "Typhoon"},
		-- Level 60 talents
		{name = "Force of Nature"},
		-- Level 75 talents
		{name = "Incapacitating Roar"},
		{name = "Ursol's Vortex"},
		{name = "Mighty Bash"},
		-- Level 90 talents
		{name = "Heart of the Wild"},
		{name = "Nature's Vigil"},
		-- Level 100 talents
		{name = "Bristling Fur"}
	}
}

-- TODO: replace with Aura List Library
--[=[

ns.lib.aura = {
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
