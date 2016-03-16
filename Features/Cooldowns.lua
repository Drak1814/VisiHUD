--[[ Element: Cooldowns

 Handles creation and updating of cooldown icons.

 Widget

 Cooldowns   - A Frame to hold icons representing active cooldowns.

 Options

 .disableCooldown    - Disables the cooldown spiral. Defaults to false.
 .size               - Icon size. Defaults to 16.
 .spacing            - Spacing between each icon. Defaults to 0.
 .['spacing-x']      - Horizontal spacing between each icon. Takes priority over
                       `spacing`.
 .['spacing-y']      - Vertical spacing between each icon. Takes priority over
                       `spacing`.
 .['growth-x']       - Horizontal growth direction. Defaults to RIGHT.
 .['growth-y']       - Vertical growth direction. Defaults to UP.
 .initialAnchor      - Anchor point for the icons. Defaults to BOTTOMLEFT.
 .filter             - Custom filter list for cooldowns to display.
 .num - The maximum number of cooldowns to display. Defaults to 12.


 Examples

   -- Position and size
   local CDs = CreateFrame("Frame", nil, self)
   CDs:SetPoint("RIGHT", self, "LEFT")
   CDs:SetSize(16 * 2, 16 * 16)

   -- Register with oUF
   self.Cooldowns = CDs

 Hooks and Callbacks

]]

local parent, ns = ...
local oUF = dUF or ns.dUF

local VISIBLE = 1
local HIDDEN = 0

local playerCD = {}

function AddPlayerCooldown(id, isItem, name, texture, start, duration, timeLeft)
	table.insert(playerCD, {id, isItem, name, texture, start, duration, timeLeft})
	--ns.debug("AddPlayerCoooldown", #playerCD, id, isItem)
end

function RemovePlayerCooldown(index)
	if playerCD[index] then
		--ns.debug("RemovePlayerCoooldown", index, playerCD[index][1], playerCD[index][2])
		table.remove(playerCD, index)
	end
end

function SetPlayerCooldown(index, id, isItem, name, texture, start, duration, timeLeft)
	if playerCD[index] then
		--ns.debug("SetPlayerCoooldown", index, id, isItem)
		playerCD[index] = {id, isItem, name, texture, start, duration, timeLeft}
	end
end

function GetPlayerCooldown(index)
	if playerCD[index] then
		--ns.debug("GetPlayerCoooldown", index, playerCD[index][1], playerCD[index][2])
		return unpack(playerCD[index])
	end
end

function FindPlayerCooldown(id, isItem)
	for i, v in ipairs(playerCD) do
		if v[1] == id and v[2] == isItem then
			return i
		end
	end
end

function AddPlayerSpellCooldown()
	-- check for spells on cooldown
	for i = 1, MAX_SPELLS do
		local start, duration, enable = GetSpellCooldown(i, BOOKTYPE_SPELL)
		if start and start > 0 and duration > 3 and enable then
			local timeLeft = (start + duration) - GetTime()
			local name, _, texture, _, _, _, id = GetSpellInfo(i, BOOKTYPE_SPELL)
			if not FindPlayerCooldown(id, false) then
				AddPlayerCooldown(id, false, name, texture, start, duration, timeLeft)
				ns.debug(string.format("CD on spell %d (%s) = %0.1f", id, name or 'Unknown', timeLeft))
				return true
			end
		end
	end
end

function AddPlayerItemCooldown()
	-- check for items on cooldown
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local start, duration, enable = GetInventoryItemCooldown('player', i)
		if start and start > 0 and duration > 3 and enable then
			local timeLeft = (start + duration) - GetTime()
			local id = GetInventoryItemID('player', i)
			if not FindPlayerCooldown(id, true) then
				local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
				AddPlayerCooldown(id, true, name, texture, start, duration, timeLeft)
				ns.debug(string.format("CD on item %d (%s) = %0.1f", id, name or 'Unknown', timeLeft))
				return true
			end
		end
	end
end

function UpdatePlayerCooldown()
	-- check for finished or reset cooldowns
	update = false
	for i = 1, #playerCD do
		local id, isItem, name, texture = GetPlayerCooldown(i)
		if id and isItem then
			local start, duration, enable = GetItemCooldown(id)
			if not start or start == 0 or duration == 0 then
				ns.debug(string.format("CD finished on item %d (%s)", id, name or 'Unknown'))
				RemovePlayerCooldown(i)
				update = true
			else
				local timeLeft = (start + duration) - GetTime()
				SetPlayerCooldown(i, id, isItem, name, texture, start, duration, timeLeft)
			end
		elseif id then
			local start, duration, enable = GetSpellCooldown(id)
			if not start or start == 0 or duration == 0 then
				ns.debug(string.format("CD finished on spell %d (%s)", id, name or 'Unknown'))
				RemovePlayerCooldown(i)
				update = true
			else
				local timeLeft = (start + duration) - GetTime()
				SetPlayerCooldown(i, id, isItem, name, texture, start, duration, timeLeft)
			end
		end
	end
	return update
end

local function UpdateTooltip(self)
	local id, isItem = GetPlayerCooldown(self:GetID())
	if id and isItem then
		GameTooltip:SetItemByID(id)
	elseif id then
		GameTooltip:SetSpellByID(id)
	end
end

local function OnEnter(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	self:UpdateTooltip()
end

local function OnLeave()
	GameTooltip:Hide()
end

local createSpellIcon = function(icons, index)
	local button = CreateFrame("Button", nil, icons)

	local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cd:SetAllPoints(button)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints(button)

	button.UpdateTooltip = UpdateTooltip
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", OnLeave)

	button.icon = icon
	button.count = count
	button.cd = cd

	--[[ :PostCreateIcon(button)

	 Callback which is called after a new spell icon button has been created.

	 Arguments

	 button - The newly created spell icon button.
	 ]]
	if(icons.PostCreateIcon) then icons:PostCreateIcon(button) end

	return button
end

local customFilter = function(icons, icon, id, isItem, name, texture, start, duration, timeLeft)
	if icons.filter then
		if isItem and icons.filter.items then
			for _, v in ipairs(icons.filter.items) do
				if id == v then return true end
			end
		elseif not isItem and icons.filter.spells then
			for _, v in ipairs(icons.filter.spells) do
				if id == v then return true end
			end
		end
		return false
	end
	return true
end

local updateIcon = function(icons, index, offset, filter, visible)
	local id, isItem, name, texture, start, duration, timeLeft = GetPlayerCooldown(index)
	if(id) then
		local n = visible + offset + 1
		local icon = icons[n]
		if(not icon) then
			--[[ :CreateIcon(index)

			 A function which creates the spell icon for a given index.

			 Arguments

			 index - The offset the icon should be created at.

			 Returns

			 A button used to represent spell icons.
			]]
			local prev = icons.createdIcons
			icon = (icons.CreateIcon or createSpellIcon) (icons, n)

			-- XXX: Update the counters if the layout doesn't.
			if(prev == icons.createdIcons) then
				table.insert(icons, icon)
				icons.createdIcons = icons.createdIcons + 1
			end
		end

		icon.filter = filter

		--[[ :CustomFilter(unit, icon, ...)

		 Defines a custom filter which controls if the spell icon should be shown
		 or not.

		 Arguments

		 self - The widget that holds the spell icon.
		 icon - The button displaying the spell.
		 ... - the return values of GetPlayerCooldown

		 Returns

		 A boolean value telling the aura element if it should be show the icon
		 or not.
		]]
		local show = (icons.CustomFilter or customFilter) (icons, icon, id, isItem, name, texture, start, duration, timeLeft)
		if show then
			-- We might want to consider delaying the creation of an actual cooldown
			-- object to this point, but I think that will just make things needlessly
			-- complicated.
			local cd = icon.cd
			if cd and not icons.disableCooldown then
				if duration and duration > 0 then
					--ns.debug("CD", timeLeft - duration, duration)
					cd:SetCooldown(start, duration)
					--cd:SetReverse()
					--cd:SetHideCountdownNumbers(false)
					cd:Show()
				else
					cd:Hide()
				end
			end

			icon.icon:SetTexture(texture)

			local size = icons.size or 16
			icon:SetSize(size, size)

			icon:EnableMouse(true)
			icon:SetID(index)
			icon:Show()

			--[[ :PostUpdateIcon(icon, index, offest)

			 Callback which is called after the spell icon was updated.

			 Arguments

			 self   - The widget that holds the spell icon.
			 icon   - The button that was updated.
			 index  - The index of the spell.
			 offset - The offset the button was created at.
			 ]]
			if(icons.PostUpdateIcon) then
				icons:PostUpdateIcon(icon, index, n)
			end

			return VISIBLE
		else
			return HIDDEN
		end
	end
end

--[[ :SetPosition(from, to)

 Function used to (re-)anchor spell icons. This function is only called when
 new spell icons have been created or if :PreSetPosition is defined.

 Arguments

 self - The widget that holds the spell icons.
 from - The aura icon before the new spell icon.
 to   - The current number of created icons.
]]
local SetPosition = function(icons, from, to)
	local sizex = (icons.size or 16) + (icons['spacing-x'] or icons.spacing or 0)
	local sizey = (icons.size or 16) + (icons['spacing-y'] or icons.spacing or 0)
	local anchor = icons.initialAnchor or "BOTTOMLEFT"
	local growthx = (icons["growth-x"] == "LEFT" and -1) or 1
	local growthy = (icons["growth-y"] == "DOWN" and -1) or 1
	local cols = math.floor(icons:GetWidth() / sizex + .5)

	for i = from, to do
		local button = icons[i]

		-- Bail out if the to range is out of scope.
		if(not button) then break end
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, icons, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

local filterIcons = function(icons, filter, limit, offset, dontHide)
	if(not offset) then offset = 0 end
	local index = 1
	local visible = 0
	local hidden = 0
	while(visible < limit) do
		local result = updateIcon(icons, index, offset, filter, visible)
		if(not result) then
			break
		elseif(result == VISIBLE) then
			visible = visible + 1
		elseif(result == HIDDEN) then
			hidden = hidden + 1
		end
		index = index + 1
	end

	if(not dontHide) then
		for i = visible + offset + 1, #icons do
			icons[i]:Hide()
		end
	end

	return visible, hidden
end

local UpdateSpells = function(self, event)
	local spells = self.Cooldowns
	if(spells) then

		if event == "SPELL_UPDATE_COOLDOWN" then
			AddPlayerSpellCooldown()
		elseif event == "BAG_UPDATE_COOLDOWN" then
			AddPlayerItemCooldown()
		end

		if(spells.PreUpdate) then spells:PreUpdate() end

		local num = spells.num or 12
		local visibleSpells, hiddenSpells = filterIcons(spells, spells.filter, num)
		spells.visibleSpells = visibleSpells

		local fromRange, toRange
		if(spells.PreSetPosition) then
			fromRange, toRange = spells:PreSetPosition(num)
		end

		if(fromRange or spells.createdIcons > spells.anchoredIcons) then
			(spells.SetPosition or SetPosition) (spells, fromRange or spells.anchoredIcons + 1, toRange or spells.createdIcons)
			spells.anchoredIcons = spells.createdIcons
		end

		if(spells.PostUpdate) then spells:PostUpdate() end
	end
end

local Update = function(self, event, unit)
	if(self.unit ~= unit) then return end

	UpdateSpells(self, event)

	-- Assume no event means someone wants to re-anchor things. This is usually
	-- done by UpdateAllElements and :ForceUpdate.
	if(event == 'ForceUpdate' or not event) then
		local spells = self.Cooldowns
		if(spells) then
			(spells.SetPosition or SetPosition) (spells, 1, spells.createdIcons)
		end
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	if(self.Cooldowns) then
		--ns.debug("Cooldowns Enabled")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN", UpdateSpells)
		self:RegisterEvent("BAG_UPDATE_COOLDOWN", UpdateSpells)

		-- update cooldowns (scan)
		local tick = 0
		self:SetScript("OnUpdate", function(self, elapsed)
			tick = tick + elapsed
			if tick >= 0.1 then
				tick = 0
				if UpdatePlayerCooldown() then
					ForceUpdate(self.Cooldowns)
				end
			end
		end)

		local spells = self.Cooldowns
		if(spells) then
			spells.__owner = self
			spells.ForceUpdate = ForceUpdate

			spells.createdIcons = 0
			spells.anchoredIcons = 0
		end

		return true
	end
end

local Disable = function(self)
	if(self.Cooldowns) then
		self:SetScript("OnUpdate", nil)
		self:UnregisterEvent("SPELL_UPDATE_COOLDOWN", UpdateSpells)
		self:UnregisterEvent("BAG_UPDATE_COOLDOWN", UpdateSpells)
	end
end

oUF:AddElement('Cooldowns', Update, Enable, Disable)
