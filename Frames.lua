--[[--------------------------------------------------------------------
	VisiHUD
	High visibility combat HUD for World of Warcraft
	Copyright (c) 2016 Drak <drak@derpydo.com>. All rights reserved.
	https://github.com/Drak1814/VisiHUD
----------------------------------------------------------------------]]

local _, ns = ...
local _, playerClass = UnitClass("player")
local colors = dUF.colors

local function noop() end
local debug = ns.debug

ns.frames, ns.headers, ns.objects = {}, {}, {}

local function Spawn(self, unit, isSingle)

	local config = ns.config

	if self:GetParent():GetAttribute("useOwnerUnit") then
		local suffix = self:GetParent():GetAttribute("unitsuffix")
		self:SetAttribute("useOwnerUnit", true)
		self:SetAttribute("unitsuffix", suffix)
		unit = unit .. suffix
	end

	debug("Spawning Unit", unit)

	local uconfig = ns.uconfig[unit]

	local playeronly = false
	if unit == 'draknalar' then
		uconfig = ns.uconfig['playeridle']
		unit = 'player'
		playeronly = true
	end

	self.spawnunit = unit

	tinsert(ns.objects, self)

	--self.menu = ns.UnitFrame_DropdownMenu

	self:HookScript("OnEnter", ns.UnitFrame_OnEnter)
	self:HookScript("OnLeave", ns.UnitFrame_OnLeave)

	self:RegisterForClicks("AnyUp")

	-- FastFocus Key
	if ns.config.fastFocus then
		self:SetAttribute("shift-type1", "focus")
	end

	local FRAME_WIDTH  = config.width  * (uconfig.width  or 1)
	local FRAME_HEIGHT = config.height * (uconfig.height or 1)
	local POWER_HEIGHT = FRAME_HEIGHT * config.powerHeight

	local BAR_TEXTURE = LibStub("LibSharedMedia-3.0"):Fetch("statusbar", config.statusbar) or "Interface\\TargetingFrame\\UI-StatusBar"

	if isSingle then
		self:SetAttribute("initial-width", FRAME_WIDTH)
		self:SetAttribute("initial-height", FRAME_HEIGHT)
		self:SetWidth(FRAME_WIDTH)
		self:SetHeight(FRAME_HEIGHT)
	else
		-- used for aura filtering
		self.isGroupFrame = true
	end

	for k, v in pairs(ns.framePrototype) do
		self[k] = v
	end

	-------------------------
	-- Border and backdrop --
	-------------------------
	ns.CreateBorder(self)
	self.UpdateBorder = ns.UpdateBorder

	self:SetBackdrop(config.backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(unpack(config.borderColor))

	-----------------------------------------------------------
	-- Overlay to avoid reparenting stuff on powerless units --
	-----------------------------------------------------------
	self.overlay = CreateFrame("Frame", nil, self)
	self.overlay:SetAllPoints(true)

	--health.value:SetParent(self.overlay)
	self:SetBorderParent(self.overlay)

	-------------------------
	-- Health bar and text --
	-------------------------
	local health = ns.CreateStatusBar(self, 20, "RIGHT")
	health:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1)
	health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -1)
	health:SetPoint("BOTTOM", self, "BOTTOM", 0, 1)
	self.Health = health

	health.texture:SetDrawLayer("ARTWORK")

	health.value:SetParent(self.overlay)
	health.value:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, FRAME_HEIGHT * config.powerHeight - 4)

	local healthColorMode = config.healthColorMode
	health.colorClass = healthColorMode == "CLASS"
	health.colorReaction = healthColorMode == "CLASS"
	health.colorSmooth = healthColorMode == "HEALTH"

	local healthBG = config.healthBG
	health.bg.multiplier = healthBG

	if healthColorMode == "CUSTOM" then
		local r, g, b = unpack(config.healthColor)
		health:SetStatusBarColor(r, g, b)
		health.bg:SetVertexColor(r * healthBG, g * healthBG, b * healthBG)
	end

	health.frequentUpdates = true

	health.PostUpdate = ns.Health_PostUpdate
	self:RegisterForMouseover(health)

	---------------------------------
	-- Predicted healing & absorbs --
	---------------------------------
	do
		local healing = ns.CreateStatusBar(health, nil, nil, true)
		healing:SetWidth(FRAME_WIDTH - 2) -- health:GetWidth() doesn't work for some reason
		healing:SetPoint("TOPLEFT", health.texture, "TOPRIGHT")
		healing:SetPoint("BOTTOMLEFT", health.texture, "BOTTOMRIGHT")
		healing:SetStatusBarColor(0.25, 1, 0.25, 0.5)

		local spark = healing:CreateTexture(nil, "OVERLAY")
		spark:SetPoint("TOP", healing, "TOPLEFT")
		spark:SetPoint("BOTTOM", healing, "BOTTOMLEFT")
		spark:SetWidth(16)
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetTexCoord(0, 1, 0.35, 0.6)
		spark:SetBlendMode("ADD")
		spark:SetAlpha(0.25)
		healing.spark = spark

		local cap = self.overlay:CreateTexture(nil, "OVERLAY")
		cap:SetPoint("CENTER", health, "RIGHT")
		cap:SetSize(16, 32)
		cap:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
		cap:SetBlendMode("ADD")
		cap:SetAlpha(0.75)
		healing.cap = cap

		local absorbs = ns.CreateStatusBar(health, nil, nil, true)
		absorbs:SetWidth(FRAME_WIDTH - 2) -- health:GetWidth() doesn't work for some reason
		absorbs:SetPoint("TOPLEFT", healing.texture, "TOPRIGHT")
		absorbs:SetPoint("BOTTOMLEFT", healing.texture, "BOTTOMRIGHT")
		absorbs:SetStatusBarColor(0.25, 0.8, 1, 0.5)

		local spark = absorbs:CreateTexture(nil, "OVERLAY")
		spark:SetPoint("TOP", absorbs, "TOPLEFT")
		spark:SetPoint("BOTTOM", absorbs, "BOTTOMLEFT")
		spark:SetWidth(16)
		spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		spark:SetTexCoord(0, 1, 0.35, 0.6)
		spark:SetBlendMode("ADD")
		spark:SetAlpha(0.25)
		absorbs.spark = spark

		local cap = self.overlay:CreateTexture(nil, "OVERLAY")
		cap:SetPoint("CENTER", health, "RIGHT")
		cap:SetSize(16, 32)
		cap:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
		cap:SetBlendMode("ADD")
		cap:SetAlpha(0.75)
		cap:SetDesaturated(true)
		cap:SetVertexColor(0, 1, 0)
		absorbs.cap = cap

		self.HealPrediction = {
			healingBar = healing,
			absorbsBar = absorbs,
			Override = ns.HealPrediction_Override,
		}
	end

	------------------------
	-- Power bar and text --
	------------------------
	if uconfig.power then
		local power = ns.CreateStatusBar(self, (uconfig.width or 1) > 0.75 and 16, "LEFT")
		--power:SetFrameLevel(self.Health:GetFrameLevel() + 2)
		power:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 1, 1)
		power:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1)
		power:SetHeight(POWER_HEIGHT)
		self.Power = power

		health:SetPoint("BOTTOM", power, "TOP", 0, 1)

		if power.value then
			power.value:SetParent(self.overlay)
			power.value:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 4, FRAME_HEIGHT * config.powerHeight - 2)
			power.value:SetPoint("BOTTOMRIGHT", self.Health.value, "BOTTOMLEFT", -8, 0)
			self:RegisterForMouseover(power)
		end

		local powerColorMode = config.powerColorMode
		power.colorClass = powerColorMode == "CLASS"
		power.colorReaction = powerColorMode == "CLASS"
		power.colorPower = powerColorMode == "POWER"

		local powerBG = config.powerBG
		power.bg.multiplier = powerBG

		if powerColorMode == "CUSTOM" then
			local r, g, b = unpack(config.powerColor)
			power:SetStatusBarColor(r, g, b)
			power.bg:SetVertexColor(r * powerBG, g * powerBG, b * powerBG)
		end

		power.frequentUpdates = unit == "player" or unit == "target" or unit == "focus"
		power.PostUpdate = ns.Power_PostUpdate
	end

	-----------------------
	-- Status icons --
	-----------------------
	if unit == "player" then
		self.Status = ns.CreateFontString(self.overlay, 16, "LEFT")
		self.Status:SetPoint("LEFT", self, "BOTTOMLEFT", 2, 2)
		self:Tag(self.Status, "[leadericon][mastericon]")

		self.Resting = self.overlay:CreateTexture(nil, "OVERLAY")
		self.Resting:SetPoint("LEFT", self, "TOPLEFT", 0, 6)
		self.Resting:SetSize(30, 28)

		self.Combat = self.overlay:CreateTexture(nil, "OVERLAY")
		self.Combat:SetPoint("RIGHT", self, "TOPRIGHT", 0, 6)
		self.Combat:SetSize(32, 32)
	elseif unit == "target" then
		self.Status = ns.CreateFontString(self.overlay, 16, "RIGHT")
		self.Status:SetPoint("RIGHT", self, "BOTTOMRIGHT", -2, 0)
		self:Tag(self.Status, "[mastericon][leadericon]")
	end

	---------------------------
	-- Name text, Level text --
	---------------------------
	if unit == "target" or unit == "focus" then
		self.Level = ns.CreateFontString(self.overlay, 14, "LEFT")
		self.Level:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 2, -1) -- -4
		self:Tag(self.Level, "[difficulty][level][shortclassification]")

		self.Name = ns.CreateFontString(self.overlay, 18, "LEFT")
		self.Name:SetPoint("LEFT", self.Level, "RIGHT", 1, 0)
		self.Name:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -2, -2) -- -5
		self:Tag(self.Name, "[unitcolor][name]")
	elseif unit ~= "player" and not strmatch(unit, "pet") then
		self.Name = ns.CreateFontString(self.overlay, 18, "LEFT")
		self.Name:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 2, -2)
		self.Name:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -2, -2) -- -5
		self:Tag(self.Name, "[unitcolor][name]")
--[[
		elseif unit == "player" then
		self.Name = ns.CreateFontString(self.overlay, 18, "LEFT")
		self.Name:SetPoint("LEFT", self.Resting, "RIGHT", 1, 0)
		self.Name:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -30, -2)
		self:Tag(self.Name, "[unitcolor][name]")
]]
		end

	-----------------
	-- Threat text --
	-----------------
	if unit == "target" and config.threatLevels then
		self.ThreatText = ns.CreateFontString(self.overlay, 16, "RIGHT")
		self.ThreatText:SetPoint("CENTER", self, "BOTTOM", 0, 0)
		self:Tag(self.ThreatText, "[threatpct]")
	end

	------------------
	-- Combo points --
	------------------
	-- TODO: make sure it never overlaps with ClassIcons
	if unit == "player" then
		local el = ns.Orbs.Create(self.overlay, MAX_COMBO_POINTS, 20)
		el.Override = ns.ComboPoints_Override
		self.CPoints = el

		for i = MAX_COMBO_POINTS, 1, -1 do
			local orb = el[i]
			if i == 1 then
				orb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 2, 5)
			else
				orb:SetPoint("BOTTOMRIGHT", el[i - 1], "BOTTOMLEFT", 2, 0)
			end
			orb.bg:SetVertexColor(0.25, 0.25, 0.25)
			orb.fg:SetVertexColor(1, 0.8, 0)
		end
	end

	------------------------------
	-- Class-specific resources --
	------------------------------
	if unit == "player" and (playerClass == "DRUID" or playerClass == "MONK" or playerClass == "PALADIN" or playerClass == "PRIEST" or playerClass == "WARLOCK") then
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[playerClass]
		local element, powerType, updateFunc = "ClassIcons"

		--------------------
		-- Wild mushrooms --
		--------------------
		if playerClass == "DRUID" then
			element = "WildMushrooms"
			updateFunc = ns.WildMushrooms_Override

		---------
		-- Chi --
		---------
		elseif playerClass == "MONK" then
			powerType = SPELL_POWER_LIGHT_FORCE
			updateFunc = ns.Chi_Override

		----------------
		-- Holy power --
		----------------
		elseif playerClass == "PALADIN" then
			powerType = SPELL_POWER_HOLY_POWER
			updateFunc = ns.HolyPower_Override

		-----------------
		-- Shadow orbs --
		-----------------
		elseif playerClass == "PRIEST" then
			powerType = SPELL_POWER_SHADOW_ORBS
			updateFunc = ns.ShadowOrbs_Override

		-----------------
		-- Soul shards --
		-----------------
		elseif playerClass == "WARLOCK" then
			powerType = SPELL_POWER_SOUL_SHARDS
			updateFunc = ns.SoulShards_Override
		end

		local el = ns.Orbs.Create(self.overlay, 6, 20) -- TODO: switch to multibar?
		el.powerType = powerType
		--el.Override = updateFunc
		el.UpdateTexture = noop
		self[element] = el

		local function SetAlpha(self, alpha)
			--print("SetAlpha", self.id, alpha)
			if alpha == 1 then
				self.bg:SetVertexColor(0.25, 0.25, 0.25)
				self.bg:SetAlpha(1)
				self.fg:Show()
			else
				self.bg:SetVertexColor(0.4, 0.4, 0.4)
				self.bg:SetAlpha(0.5)
				self.fg:Hide()
			end
		end
		for i = 1, 5 do
			local orb = el[i]
			if i == 1 then
				orb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 2, 5)
			else
				orb:SetPoint("BOTTOMRIGHT", el[i - 1], "BOTTOMLEFT", 2, 0)
			end
			orb.bg:SetVertexColor(0.25, 0.25, 0.25)
			orb.fg:SetVertexColor(color.r, color.g, color.b)
			orb.SetAlpha = SetAlpha
		end

		if CUSTOM_CLASS_COLORS then
			CUSTOM_CLASS_COLORS:RegisterCallback(function()
				local color = CUSTOM_CLASS_COLORS[playerClass]
				for i = 1, #el do
					el[i].fg:SetVertexColor(color.r, color.g, color.b)
				end
			end)
		end
	end

	--------------------
	-- Stacking buffs --
	--------------------
	if unit == "player" and (playerClass == "MAGE" or playerClass == "SHAMAN") then
		local aura, filter, maxCount, actviate, activateEvents
		if playerClass == "MAGE" then
			aura = GetSpellInfo(36032) -- Arcane Charge
			filter = "HARMFUL"
			maxCount = 4
			activate = function()
				return GetSpecialization() == 1
			end
			activateEvents = "PLAYER_SPECIALIZATION_CHANGED"
		elseif playerClass == "SHAMAN" then
			aura = GetSpellInfo(53817) -- Maelstrom Weapon
			maxCount = 5
			activate = function()
				return GetSpecialization() == 2 and UnitLevel("player") >= 50
			end
			activateEvents = "PLAYER_SPECIALIZATION_CHANGED PLAYER_LEVEL_UP"
		end

		local el = ns.Orbs.Create(self.overlay, maxCount, 20)
		el.aura = aura
		el.filter = filter
		el.activate = activate
		el.activateEvents = activateEvents
		self.AuraStack = el

		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[playerClass]

		local function SetAlpha(orb, alpha)
			if alpha == 1 then
				orb.bg:SetVertexColor(0.25, 0.25, 0.25)
				orb.bg:SetAlpha(1)
				orb.fg:Show()
			else
				orb.bg:SetVertexColor(0.4, 0.4, 0.4)
				orb.bg:SetAlpha(0.5)
				orb.fg:Hide()
			end
		end

		for i = 1, #el do
			local orb = el[i]
			if i == 1 then
				orb:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 2, 5)
			else
				orb:SetPoint("BOTTOMRIGHT", el[i - 1], "BOTTOMLEFT", 2, 0)
			end
			orb.bg:SetVertexColor(0.25, 0.25, 0.25)
			orb.fg:SetVertexColor(color.r, color.g, color.b)
			orb.SetAlpha = SetAlpha
		end

		if CUSTOM_CLASS_COLORS then
			CUSTOM_CLASS_COLORS:RegisterCallback(function()
				color = CUSTOM_CLASS_COLORS[playerClass]
				for i = 1, #el do
					el[i].fg:SetVertexColor(color.r, color.g, color.b)
				end
			end)
		end
	end

	--------------------
	-- Burning embers --
	--------------------
	if unit == "player" and playerClass == "WARLOCK" then
		self.BurningEmbers = ns.CreateBurningEmbers(self)
	end

	----------------
	-- EclipseBar --
	----------------
	if unit == "player" and playerClass == "DRUID" and config.eclipseBar then
		self.EclipseBar = ns.CreateEclipseBar(self)
	end

	-----------
	-- Runes --
	-----------
	if unit == "player" and playerClass == "DEATHKNIGHT" and config.runeBars then
		self.Runes = ns.CreateRunes(self)
	end

	------------
	-- Totems --
	------------
	if unit == "player" and playerClass == "SHAMAN" and config.totemBars then
		self.Totems = ns.CreateTotems(self)
	end

	----------------------------------------------
	-- Demonic fury / Druid mana / Monk stagger --
	----------------------------------------------
	if unit == "player" and (playerClass == "WARLOCK" or (playerClass == "DRUID" and config.druidMana) or (playerClass == "MONK" and config.staggerBar)) then
		local otherPower = ns.CreateStatusBar(self, 16, "CENTER")
		otherPower:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
		otherPower:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 0)
		otherPower:SetHeight(FRAME_HEIGHT * config.powerHeight / 2)

		otherPower.value:SetPoint("CENTER", otherPower, 0, 1)

		otherPower.value:Hide()
		self:RegisterForMouseover(otherPower.value)

		otherPower:Hide()
		otherPower:SetScript("OnShow", ns.ExtraBar_OnShow)
		otherPower:SetScript("OnHide", ns.ExtraBar_OnHide)
		otherPower.borderOffset = 2

		otherPower.colorPower = true
		otherPower.bg.multiplier = config.powerBG

		if playerClass == "WARLOCK" then
			local color = dUF.colors.power.DEMONIC_FURY
			otherPower.value:SetTextColor(color[1], color[2], color[3])
			otherPower.PostUpdate = ns.DemonicFury_PostUpdate
			self.DemonicFury = otherPower

		elseif playerClass == "DRUID" then
			local color = dUF.colors.power.MANA
			otherPower.value:SetTextColor(color[1], color[2], color[3])
			otherPower.PostUpdate = ns.DruidMana_PostUpdate
			self.DruidMana = otherPower

		else
			otherPower.PostUpdate = ns.Stagger_PostUpdate
			self.Stagger = otherPower
		end
	end

	----------------
	-- Phase icon --
	----------------
	if unit == "target" or unit == "focus" then
		local phase = self.Health:CreateTexture(nil, "OVERLAY")
		phase:SetPoint("TOP", self)
		phase:SetPoint("BOTTOM", self)
		phase:SetWidth(FRAME_HEIGHT * 2.5)
		phase:SetTexture("Interface\\Icons\\Spell_Frost_Stun")
		phase:SetTexCoord(0.05, 0.95, 0.5 - 0.25 * 0.9, 0.5 + 0.25 * 0.9)
		phase:SetAlpha(0.5)
		phase:SetBlendMode("ADD")
		phase:SetDesaturated(true)
		phase:SetVertexColor(0.4, 0.8, 1)
		self.PhaseIcon = phase
	end

	---------------------
	-- Quest boss icon --
	---------------------
	if unit == "target" then
		self.QuestIcon = self.overlay:CreateTexture(nil, "OVERLAY")
		self.QuestIcon:SetPoint("CENTER", self, "LEFT", 0, 0)
		self.QuestIcon:SetSize(32, 32)
	end

	-----------------------
	-- Raid target icon --
	-----------------------
	if unit == "target" then
		self.RaidIcon = self.overlay:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetPoint("CENTER", self, 0, 0)
		self.RaidIcon:SetSize(32, 32)
	end

	---------------
	-- PvP icons --
	---------------
	if unit == "target" then
		self.PvP = self.overlay:CreateFontString(nil, "OVERLAY")
		self.PvP:SetPoint("CENTER", self, "TOPLEFT", -1, 4) -- "BOTTOM")
		self.PvP:SetFont("Fonts\\ARIALN.ttf", 18, "OUTLINE")
		self.PvP:SetText(RANGE_INDICATOR)
		self.PvP.SetTexture = ns.noop
		self.PvP.PostUpdate = ns.PvP_PostUpdate
	end

	----------------
	-- Aura icons --
	----------------
	if unit == "player" and not playeronly then
		debug("Creating", unit, "Auras")
		local GAP = 6
		local SIZE = FRAME_HEIGHT
		local MAX_ICONS = floor((FRAME_WIDTH + GAP) / (SIZE + GAP))
		local NUM_BUFFS = MAX_ICONS - 2
		local NUM_DEBUFFS = 2
		local HEIGHT = (SIZE * 3) + (GAP * 4)

		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs:SetHeight(HEIGHT)
		self.Buffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 24)
		self.Buffs:SetWidth((SIZE * NUM_BUFFS) + (GAP * (NUM_BUFFS - 1)))

		self.Buffs["growth-x"] = "LEFT"
		self.Buffs["growth-y"] = "UP"
		self.Buffs.showType = false
		self.Buffs.size = SIZE
		self.Buffs["spacing-x"] = GAP
		self.Buffs["spacing-y"] = GAP * 2
		self.Buffs.initialAnchor = "BOTTOMRIGHT"
		self.Buffs.num = NUM_BUFFS * 3

		self.Buffs.CustomFilter   = ns.CustomAuraFilters.target
		self.Buffs.PostCreateIcon = ns.Auras_PostCreateIcon
		self.Buffs.PostUpdateIcon = ns.Auras_PostUpdateIcon
		self.Buffs.PostUpdate     = ns.Auras_PostUpdate -- required to detect Dead => Ghost

		self.Buffs.parent = self

		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs:SetHeight(HEIGHT)
		self.Debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 24)
		self.Debuffs:SetWidth((SIZE * NUM_DEBUFFS) + (GAP * (NUM_DEBUFFS - 1)))

		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "UP"
		self.Debuffs.showType = true
		self.Debuffs.size = SIZE
		self.Debuffs["spacing-x"] = GAP
		self.Debuffs["spacing-y"] = GAP * 2
		self.Debuffs.initialAnchor = "BOTTOMLEFT"
		self.Debuffs.num = NUM_DEBUFFS * 3

		self.Debuffs.CustomFilter   = ns.CustomAuraFilters.target
		self.Debuffs.PostCreateIcon = ns.Auras_PostCreateIcon
		self.Debuffs.PostUpdateIcon = ns.Auras_PostUpdateIcon

		self.Debuffs.parent = self

	elseif unit == "pet" then
		debug("Creating", unit, "Auras")
		local GAP = 6

		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 24)
		self.Buffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 24)
		self.Buffs:SetHeight(FRAME_HEIGHT)

		self.Buffs["growth-x"] = "LEFT"
		self.Buffs["growth-y"] = "UP"
		self.Buffs["initialAnchor"] = "BOTTOMRIGHT"
		self.Buffs["num"] = floor((FRAME_WIDTH + GAP) / (FRAME_HEIGHT + GAP))
		self.Buffs["size"] = FRAME_HEIGHT
		self.Buffs["spacing-x"] = GAP
		self.Buffs["spacing-y"] = GAP

		self.Buffs.CustomFilter   = ns.CustomAuraFilters.pet
		self.Buffs.PostCreateIcon = ns.Auras_PostCreateIcon
		self.Buffs.PostUpdateIcon = ns.Auras_PostUpdateIcon

		self.Buffs.parent = self
	elseif unit == "target" then
		debug("Creating", unit, "Auras")
		local GAP = 6
		local SIZE = FRAME_HEIGHT
		local MAX_ICONS = floor((FRAME_WIDTH + GAP) / (SIZE + GAP))
		local NUM_DEBUFFS = MAX_ICONS - 2
		local NUM_BUFFS = 2
		local HEIGHT = (SIZE * 3) + (GAP * 4)

		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs:SetHeight(HEIGHT)
		self.Debuffs.parent = self

		self.Debuffs["growth-y"] = "UP"
		self.Debuffs["showType"] = true
		self.Debuffs["size"] = SIZE
		self.Debuffs["spacing-x"] = GAP
		self.Debuffs["spacing-y"] = GAP * 2

		self.Debuffs.CustomFilter   = ns.CustomAuraFilters.target
		self.Debuffs.PostCreateIcon = ns.Auras_PostCreateIcon
		self.Debuffs.PostUpdateIcon = ns.Auras_PostUpdateIcon
		self.Debuffs.PostUpdate     = ns.Auras_PostUpdate -- required to detect Dead => Ghost

		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs:SetHeight(HEIGHT)
		self.Buffs.parent = self

		self.Buffs["growth-y"] = "UP"
		self.Buffs["showType"] = false
		self.Buffs["size"] = SIZE
		self.Buffs["spacing-x"] = GAP
		self.Buffs["spacing-y"] = GAP * 2

		self.Buffs.CustomFilter   = ns.CustomAuraFilters.target
		self.Buffs.PostCreateIcon = ns.Auras_PostCreateIcon
		self.Buffs.PostUpdateIcon = ns.Auras_PostUpdateIcon

		local function UpdateAurasForRole(self, role, initial)
			--print("Updating auras for new role:", role)

			local a, b
			if role == "HEALER" then
				a, b = self.Buffs, self.Debuffs
			else
				a, b = self.Debuffs, self.Buffs
			end

			a:ClearAllPoints()
			a:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 24)
			a:SetWidth((SIZE * NUM_DEBUFFS) + (GAP * (NUM_DEBUFFS - 1)))
			a["growth-x"] = "RIGHT"
			a["initialAnchor"] = "BOTTOMLEFT"
			a["num"] = NUM_DEBUFFS * 3

			b:ClearAllPoints()
			b:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 24)
			b:SetWidth((SIZE * NUM_BUFFS) + (GAP * (NUM_BUFFS - 1)))
			b["growth-x"] = "LEFT"
			b["initialAnchor"] = "BOTTOMRIGHT"
			b["num"] = NUM_BUFFS * 3

			if not initial then
				a:ForceUpdate()
				b:ForceUpdate()
			end
		end

		self:RegisterForRoleChange(UpdateAurasForRole)
		UpdateAurasForRole(self, ns.GetPlayerRole(), true) -- default is DAMAGER
	elseif unit == "targettarget" then
		debug("Creating", unit, "Auras")

		local GAP = 6

		local auras = CreateFrame("Frame", nil, self)
		auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 24)
		auras:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 24)
		auras:SetHeight(FRAME_HEIGHT)
		auras.parent = self

		auras["growth-x"] = "RIGHT"
		auras["growth-y"] = "UP"
		auras["initialAnchor"] = "BOTTOMLEFT"
		auras["num"] = floor((FRAME_WIDTH + GAP) / (FRAME_HEIGHT + GAP))
		auras["size"] = FRAME_HEIGHT
		auras["spacing-x"] = GAP
		auras["spacing-y"] = GAP

		auras.CustomFilter   = ns.CustomAuraFilters.targettarget
		auras.PostCreateIcon = ns.Auras_PostCreateIcon
		auras.PostUpdateIcon = ns.Auras_PostUpdateIcon

		auras:SetScript("OnUpdate", function(self, elapsed)
			self.sinceLastUpdate = (self.sinceLastUpdate or 0) + elapsed;
			if self.sinceLastUpdate >= 1.0 then -- in seconds
				self:ForceUpdate()
				self.sinceLastUpdate = 0.0;
			end
		end)

		self.Auras = auras

	end

	------------------------------
	-- Cast bar, icon, and text --
	------------------------------
	if uconfig.castbar then
		self.Castbar = ns.AddCastbar(self, unit, config.castBG)
	end


	--------------------
	-- Cooldown icons --
	--------------------

	if unit == "player" and not playeronly then
		debug("Creating", unit, "Cooldowns")

		local GAP = 6

		local cd = CreateFrame("Frame", nil, self)
		if uconfig.castbar then
			cd:SetPoint("TOPLEFT", self.Castbar, "BOTTOMLEFT", 0, -12)
			cd:SetPoint("TOPRIGHT", self.Castbar, "BOTTOMRIGHT", 0, -12)
		else
			cd:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -12)
			cd:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -12)
		end

		cd:SetHeight(FRAME_HEIGHT)
		cd.parent = self

		cd["growth-x"] = "LEFT"
		cd["growth-y"] = "DOWN"
		cd["initialAnchor"] = "TOPRIGHT"
		cd["num"] = floor((FRAME_WIDTH + GAP) / (FRAME_HEIGHT + GAP))
		cd["size"] = FRAME_HEIGHT
		cd["spacing-x"] = GAP
		cd["spacing-y"] = GAP

		cd.PostCreateIcon = ns.CD_PostCreateIcon

		self.Cooldowns = cd
	end

	------------
	-- Threat --
	------------
	self.Threat = {
		Hide = noop,
		IsObjectType = noop,
		Override = ns.Threat_Override,
	}

	-------------------------------------
	-- Range || Plugin: oUF_SpellRange --
	-------------------------------------
--[=[
	local ranger
	if IsAddOnLoaded("oUF_SpellRange") then
		ranger = "SpellRange"
	elseif unit == "pet" then
		ranger = "Range"
	end
	if ranger then
		self[ranger] = { insideAlpha = 1, outsideAlpha = 0.5 }
	end
]=]

	--------------------------
	-- Element: Combat text --
	--------------------------
	if uconfig.combatText and not strmatch(unit, ".target$") then
		self.CombatText = ns.CreateFontString(self.overlay, 18, "CENTER")
		if unit == "pet" then
			self.CombatText:SetPoint("LEFT", 2, -1)
		else
			self.CombatText:SetPoint("CENTER", 0, -1)
		end
	end

	-------------------------------
	-- Element: Dispel highlight --
	-------------------------------
	self.DispelHighlight = {
		Override = ns.DispelHighlight_Override,
		filter = true,
	}

	---------------------------
	-- Element: ResInfo text --
	---------------------------
	if not strmatch(unit, ".target$") then
		self.ResInfo = ns.CreateFontString(self.overlay, 16, "CENTER")
		self.ResInfo:SetPoint("CENTER", 0, 1)
	end

	------------------------
	-- Plugin: oUF_Smooth --
	------------------------
	if config.smooth then
		self.Health.Smooth = true
		if self.Power then
			self.Power.Smooth = true
		end
	end

	-----------
	-- Done! --
	-----------
	local maxLevel
	for k, v in pairs(self) do
		if k ~= "overlay" and type(v) == "table" and v.GetFrameLevel then
			maxLevel = max(v:GetFrameLevel(), maxLevel or 0)
		end
	end
	self.overlay:SetFrameLevel(maxLevel + 1)



end

-- Magic Time!

function ns.Factory(dUF)
	local config = ns.config
	local uconfig = ns.uconfig

	-- DO NOT hide Blizzard frames
	local DisableBlizzard = dUF.DisableBlizzard
	function dUF:DisableBlizzard(unit) end

	dUF:RegisterStyle(ns.toc.style, Spawn)
	dUF:SetActiveStyle(ns.toc.style)

	local initialConfigFunction = [[
		self:SetAttribute("initial-width", %d)
		self:SetAttribute("initial-height", %d)
		self:SetWidth(%d)
		self:SetHeight(%d)
	]]

	for unit, udata in pairs(uconfig) do
		if not udata.disable then
			local name = "VisiHUD" .. unit:gsub("%a", strupper, 1):gsub("target", "Target"):gsub("pet", "Pet")
			if udata.point then
				if udata.attributes then
					--debug("Creating Header", name)
					local w = config.width  * (udata.width  or 1)
					local h = config.height * (udata.height or 1)
					ns.headers[unit] = dUF:SpawnHeader(name, nil, udata.visible,
						"dUF-initialConfigFunction", format(initialConfigFunction, w, h, w, h),
						unpack(udata.attributes))
				else
					debug("Creating Frame", name)
					if unit == 'playeridle' then unit = 'draknalar' end
					local frame = dUF:Spawn(unit, name)
					if unit == 'draknalar' then
						debug("Reparenting to IdleViewFrame...")
						frame:SetParent(VisiHUD_IdleViewFrame)
					else
						debug("Reparenting to FullViewFrame...")
						frame:SetParent(VisiHUD_FullViewFrame)
					end
					ns.frames[unit] = frame
				end
			end
		end
	end

	dUF.DisableBlizzard = DisableBlizzard

	for unit, object in pairs(ns.frames) do
		local udata = uconfig[unit]
		if unit == 'draknalar' then udata = uconfig['playeridle'] end
		local p1, parent, p2, x, y = string.split(" ", udata.point)
		object:ClearAllPoints()
		object:SetPoint(p1, ns.headers[parent] or ns.frames[parent] or _G[parent] or UIParent, p2, tonumber(x) or 0, tonumber(y) or 0)
	end
	for unit, object in pairs(ns.headers) do
		local udata = uconfig[unit]
		local p1, parent, p2, x, y = string.split(" ", udata.point)
		object:ClearAllPoints()
		object:SetPoint(p1, ns.headers[parent] or ns.frames[parent] or _G[parent] or UIParent, p2, tonumber(x) or 0, tonumber(y) or 0)
	end

	local FONT_FILE = LibStub("LibSharedMedia-3.0"):Fetch("font", config.font) or STANDARD_TEXT_FONT
	local BAR_TEXTURE = LibStub("LibSharedMedia-3.0"):Fetch("statusbar", config.statusbar) or "Interface\\TargetingFrame\\UI-StatusBar"

	-- Fix default mirror timers to match
	for i = 1, 3 do
		local barname = "MirrorTimer" .. i
		local bar = _G[barname]

		for _, region in pairs({ bar:GetRegions() }) do
			if region.GetTexture and region:GetTexture() == "SolidTexture" then
				region:Hide()
			end
		end

		bar:SetParent(UIParent)
		bar:SetWidth(225)
		bar:SetHeight(config.height * (1 - config.powerHeight))

		bar.bar = bar:GetChildren()
		bar.bg, bar.text, bar.border = bar:GetRegions()

		bar.bar:SetAllPoints(bar)
		bar.bar:SetStatusBarTexture(BAR_TEXTURE)

		bar.bg:ClearAllPoints()
		bar.bg:SetAllPoints(bar)
		bar.bg:SetTexture(BAR_TEXTURE)
		bar.bg:SetVertexColor(0.2, 0.2, 0.2, 1)

		bar.text:ClearAllPoints()
		bar.text:SetPoint("LEFT", bar, 4, 0)
		bar.text:SetFont(FONT_FILE, 16, config.fontOutline)

		bar.border:Hide()

		ns.CreateBorder(bar, nil, nil, bar.bar, "OVERLAY")
	end

end
