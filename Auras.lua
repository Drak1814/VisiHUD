--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...

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
			[123059] = true, -- Destabilize (Amber-Shaper Un'sok)
			[184449] = true, -- Mark of the Necromancer
			[184450] = true, -- Mark of the Necromancer
			[184676] = true, -- Mark of the Necromancer
			[185065] = true, -- Mark of the Necromancer
			[185066] = true, -- Mark of the Necromancer
		},
		always = { -- whitelist
		},
		never = { -- blacklist
			[116631] = true, -- Colossus
			[104993] = true, -- Jade Spirit
		}
	}
}
