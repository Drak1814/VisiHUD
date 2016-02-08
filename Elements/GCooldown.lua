-- based on dUF_GCD by Exactly.
--[[--------------------------------------------------------------------
	VisiHUD
	dUF-based Combat HUD for PvE.
	https://github.com/VisiHUD1814/VisiHUD
----------------------------------------------------------------------
	Global Cooldown Bar.

	You may embed this module in your own layout, but please do not
	distribute it as a standalone plugin.
----------------------------------------------------------------------]]

local _, ns = ...
assert(dUF, "dUF_GCooldown requires dUF")

--[[
Spell IDs to check if they are available as GCD refs. The
original dUF_GCD used spell names and didn't play well
with other locales. We use the spell id to lookup the
spell name and look that up in the spell book ...
--]]

local referenceSpells = {
	49892,			-- Death Coil (Death Knight)
	66215,			-- Blood Strike (Death Knight)
	1978,			-- Serpent Sting (Hunter)
	585,			-- Smite (Priest)
	19740,			-- Blessing of Might (Paladin)
	172,			-- Corruption (Warlock)
	5504,			-- Conjure Water (Mage)
	772,			-- Rend (Warrior)
	331,			-- Healing Wave (Shaman)
	1752,			-- Sinister Strike (Rogue)
	5176,			-- Wrath (Druid)
}


local GetTime = GetTime
local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local GetSpellCooldown = GetSpellCooldown

local spellid = nil

--
-- find a spell to use.
--
local Init = function()
	local FindInSpellbook = function(spell)
		for tab = 1, 4 do
			local _, _, offset, numSpells = GetSpellTabInfo(tab)
			for i = (1+offset), (offset + numSpells) do
				local bspell = GetSpellName(i, BOOKTYPE_SPELL)
				if (bspell == spell) then
					return i   
				end
			end
		end
		return nil
	end

	for _, lspell in pairs(referenceSpells) do
		local na = GetSpellInfo (lspell)
		local x = FindInSpellbook(na)
		if x ~= nil then
			spellid = lspell
			break
		end
	end

	if spellid == nil then
		-- XXX: print some error ..
		print ("Foo!")
	end

	return spellid
end


local OnUpdateGCD = function(self)
	local perc = (GetTime() - self.starttime) / self.duration
	if perc > 1 then
		self:Hide()
	else
		self:SetValue(perc)
	end
end


local OnHideGCD = function(self)
 	self:SetScript('OnUpdate', nil)
end


local OnShowGCD = function(self)
	self:SetScript('OnUpdate', OnUpdateGCD)
end


local Update = function(self, event, unit)
	if self.GCD then
		if spellid == nil then
			if Init() == nil then
				return
			end
		end

		local start, dur = GetSpellCooldown(spellid)

		if (not start) then return end
		if (not dur) then dur = 0 end

		if (dur == 0) then
			self.GCD:Hide() 
		else
			self.GCD.starttime = start
			self.GCD.duration = dur
			self.GCD:Show()
		end
	end
end


local Enable = function(self)
	if (self.GCD) then
		self.GCD:Hide()
		self.GCD.starttime = 0
		self.GCD.duration = 0
		self.GCD:SetMinMaxValues(0, 1)

		self:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN', Update)
		self.GCD:SetScript('OnHide', OnHideGCD)
		self.GCD:SetScript('OnShow', OnShowGCD)
	end
end


local Disable = function(self)
	if (self.GCD) then
		self:UnregisterEvent('ACTIONBAR_UPDATE_COOLDOWN')
		self.GCD:Hide()  
	end
end


dUF:AddElement('GCooldown', Update, Enable, Disable)
