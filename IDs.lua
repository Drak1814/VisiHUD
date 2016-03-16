--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...

ns.classID = {
	Warrior = 1,
	Paladin = 2,
	Hunter = 3,
	Rogue = 4,
	Priest = 5,
	Deathknight = 6,
	Shaman = 7,
	Mage = 8,
	Warlock = 9,
	Monk = 10,
	Druid = 11,
	Demonhunter = 12 -- ???
}

ns.specID = {
	[ns.classID.Hunter] = {
		Beastmaster = 253,
		Marksmanship = 254,
		Survival = 255
	},
	[ns.classID.Deathknight] = {
		Blood = 250,
		Frost = 251,
		Unholy = 252
	},
	[ns.classID.Mage] = {
		Arcane = 62,
		Fire = 63,
		Frost = 64
	},
	[ns.classID.Monk] = {
		Brewmaster = 268,
		Windwalker = 269,
		Mistweaver = 270
	},
	[ns.classID.Druid] = {
		Balance = 102,
		Feral = 103,
		Guardian = 104,
		Restoration = 105
	},
	[ns.classID.Paladin] = {
	   Holy = 65,
	   Protection = 66,
	   Retribution = 70
	},
	[ns.classID.Priest]  = {
	   Discipline = 256,
	   Holy = 257,
	   Shadow = 258
	},
	[ns.classID.Rogue] = {
	   Assassination = 259,
	   Combat = 260,
	   Subtlety = 261
	},
	[ns.classID.Shaman] = {
	   Elemental = 262,
	   Enhancement = 263,
	   Restoration = 264
	},
	[ns.classID.Warlock] = {
	   Affliction = 265,
	   Demonology = 266,
	   Destruction = 267
	},
	[ns.classID.Warrior] = {
	   Arms = 71,
	   Fury = 72,
	   Protection = 73
	}
}

ns.spellID = {
	GCD = 61304
}
