--[[ Element: Tracker

 Handles creation and updating of tracker icons.

 Widget

 Tracker   - A Frame to hold icons representing active cooldowns.

 Options

 .disableCooldown    - Disables the cooldown spiral. Defaults to false.
 .size					- Icon size. Defaults to 16.
 .spacing				- Spacing between each icon. Defaults to 0.
 .['spacing-x']		- Horizontal spacing between each icon. Takes priority over
                       `spacing`.
 .['spacing-y']		- Vertical spacing between each icon. Takes priority over
                       `spacing`.
 .['growth-x']    	- Horizontal growth direction. Defaults to RIGHT.
 .['growth-y']    	- Vertical growth direction. Defaults to UP.
 .initialAnchor   	- Anchor point for the icons. Defaults to BOTTOMLEFT.
 .slots					- spells/items/macros to track
 .num 					- The maximum number of trackers to display. Defaults to 12.


 Examples

   -- Position and size
   local frame = CreateFrame("Frame", nil, self)
   frame:SetPoint("RIGHT", self, "LEFT")
   frame:SetSize(16 * 2, 16 * 16)

   -- Register with oUF
   self.Tracker = frame

 Hooks and Callbacks

]]

local parent, ns = ...
local oUF = dUF or ns.dUF

local VISIBLE = 1
local HIDDEN = 0

local slots = {}
local

function GetTrackerSlot(index)
	return slots[index]
end

function GetTrackerSlotInfo(index)
	if slots[index] then
		local slot = slots[index]
		local name, texture, isUsable, noEnergy, inRange, charges, start, duration, timeLeft =
			nil, nil, true, false, true, nil, 0, 0, 0
		if slot.type == 'spell' then
			name, _, texture = GetSpellInfo(slot.id)
			isUsable, noEnergy = IsUsableSpell(slot.id)
			start, duration = GetSpellCooldown(slot.id)
		elseif slot.type == 'item' then
			name, _, _, _, _, _, _, _, _, texture = GetItemInfo(slot.id)
			isUsable, noEnergy = IsUsableItem(slot.id)
			start, duration = GetItemCooldown(slot.id)
		end
		if start > 0 and duration > 0 then timeLeft = start + duration - GetTime() end
		return name, texture, isUsable, noEnergy, inRange, charges, start, duration, timeLeft
	end
end

local function LinkToItem(link)
	local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name =
	  string.find(itemLink,
	    "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	return Name, Id
end

local function UpdateTooltip(self)
	local slot = GetTrackerSlot(self:GetID())
	if slot and slot.id then
		if slot.type == 'macro' then
			local _, _, id = GetMacroSpell(slot.id)
			if id then
				slot.type = 'spell'
				slot.id = id
			else
				local _, link = GetMacroItem(slot.id)
				if link then
					slot.type = 'item'
					_, slot.id = LinkToitem(link)
				end
			end
		end
		if slot.type == 'spell' and slot.id then
			GameTooltip:SetSpellByID(id)
		elseif slot.type == 'item' and slot.id then
			GameTooltip:SetItemByID(id)
		end
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

local function createTrackerIcon(icons, index)
	local button = CreateFrame("Button", nil, icons)

	-- Cooldown Overlay
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

	 Callback which is called after a new tracker icon button has been created.

	 Arguments

	 button - The newly created spell icon button.
	 ]]
	if(icons.PostCreateIcon) then icons:PostCreateIcon(button) end

	return button
end

local function updateIcon(icons, index, offset, filter, visible)
	local name, texture, isUsable, noEnergy, inRange, charges, start, duration, timeLeft = GetTrackerSlotInfo(index)
	if(name) then
		local n = visible + offset + 1
		local icon = icons[n]
		if(not icon) then
			--[[ :CreateIcon(index)

			 A function which creates the tracker icon for a given index.

			 Arguments

			 index - The offset the icon should be created at.

			 Returns

			 A button used to represent tracker icons.
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

local function UpdateSlots(self)
	local t = self.Tracker
	if(t) then
		if(t.PreUpdate) then t:PreUpdate() end
		ScanSlots(t)
		if(t.PostUpdate) then t:PostUpdate() end
	end
end

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	UpdateSlots(self)

	-- Assume no event means someone wants to re-anchor things. This is usually
	-- done by UpdateAllElements and :ForceUpdate.
	if(event == 'ForceUpdate' or not event) then
		local t = self.Tracker
		if(t) then
			(t.SetPosition or SetPosition) (t, 1, t.createdIcons)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	if(self.Tracker) then
		--ns.debug("Tracker Enabled")

		-- update slots (scan)
		local tick = 0
		self:SetScript("OnUpdate", function(self, elapsed)
			tick = tick + elapsed
			if tick >= 1 then
				tick = 0
				UpdateSlots(self)
			end
		end)

		local t = self.Tracker
		if(t) then
			t.__owner = self
			t.ForceUpdate = ForceUpdate
			t.createdIcons = 0
			t.anchoredIcons = 0
		end

		return true
	end
end

local Disable = function(self)
	if(self.Cooldowns) then
		self:SetScript("OnUpdate", nil)
	end
end

oUF:AddElement('Tracker', Update, Enable, Disable)
