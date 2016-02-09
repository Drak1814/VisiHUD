-- Custom Frame Positions
local _name, ns = ...

ns.moverPool = {}

function ns.getPosition(obj, anchor)

	debug("getPosition", obj.unit)
	
	if not anchor then
		local UIx, UIy = UIParent:GetCenter()
		local Ox, Oy = obj:GetCenter()

		-- Frame doesn't really have a positon yet.
		if not Ox then return end

		local UIWidth, UIHeight = UIParent:GetRight(), UIParent:GetTop()

		local LEFT = UIWidth / 3
		local RIGHT = UIWidth * 2 / 3

		local point, x, y
		if(Ox >= RIGHT) then
			point = 'RIGHT'
			x = obj:GetRight() - UIWidth
		elseif(Ox <= LEFT) then
			point = 'LEFT'
			x = obj:GetLeft()
		else
			x = Ox - UIx
		end

		local BOTTOM = UIHeight / 3
		local TOP = UIHeight * 2 / 3

		if(Oy >= TOP) then
			point = 'TOP' .. (point or '')
			y = obj:GetTop() - UIHeight
		elseif(Oy <= BOTTOM) then
			point = 'BOTTOM' .. (point or '')
			y = obj:GetBottom()
		else
			if(not point) then point = 'CENTER' end
			y = Oy - UIy
		end

		return { point = point, parent = 'UIParent', x = x, y = y }

	else

		local point, parent, _, x, y = anchor:GetPoint()
		return { point = point, parent = 'UIParent', x = x, y = y }
	
	end
	
end

function ns.restorePosition(obj)

	if InCombatLockdown() then return end
	local unit = obj.unit
	if not unit then return end
	
	debug("restorePosition", unit)
	
	-- We've not saved any custom position for this style.
	if not ns.uconfig[unit] 
		or	not ns.uconfig[unit].position 
		or not ns.uconfig[unit].position.custom 
		then return end

	local pos = ns.uconfig[unit].position.custom
	
	if not obj._SetPoint then
		obj._SetPoint = obj.SetPoint
		obj.SetPoint = ns.restorePosition
	end
	target:ClearAllPoints()

	target:_SetPoint(pos.point, pos.parent, pos.point, pos.x, pos.y)
	
end
 
function ns.saveDefaultPosition(obj)

	local unit = obj.unit
	if not unit then return end
	
	debug("saveDefaultPosition", unit)
	
	if not ns.uconfig[unit] then ns.uconfig[unit] = {} end
	if not ns.uconfig[unit].position then ns.uconfig[unit].position = {} end
	if not ns.uconfig[unit].position.default then
		ns.uconfig[unit].position.default = ns.getPosition(obj)
	end
	
end

function ns.savePosition(obj, anchor)

	local unit = obj.unit
	if not unit then return end
	
	debug("savePosition", unit)
	
	if not ns.uconfig[unit] then ns.uconfig[unit] = {} end
	if not ns.uconfig[unit].position then ns.uconfig[unit].position = {} end
	ns.uconfig[unit].position.custom = ns.getPosition(isHeader or obj, anchor)
	
end

--[=[
function ns.saveUnitPosition(unit, point, x, y, scale)
	debug("saveUnitPosition", unit, point, x, y, scale)
	if not ns.uconfig[unit] then ns.uconfig[unit] = {} end
	if not ns.uconfig[unit].position then ns.uconfig[unit].position = {} end	
	ns.uconfig[unit].position.custom = {
		point = point,
		parent = 'UIParent',
		x = x,
		y = y,
		scale = scale
	}
end
]=]

-- Attempt to figure out a sane name to display
function ns.smartName(obj, header)

	if type(obj) == 'string' then
		return obj
	else		
		if obj.unit then return obj.unit end
		return obj:GetName()
	end

end

function ns.getMover(obj)

	if not obj:GetCenter() then return end
	if ns.moverPool[target] then return ns.moverPool[target] end

	local mover = CreateFrame("Frame")
	mover:SetParent(UIParent)
	mover:Hide()

	mover:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	mover:SetFrameStrata('TOOLTIP')
	mover:SetAllPoints(target)

	mover:EnableMouse(true)
	mover:SetMovable(true)
	mover:SetResizable(true)
	mover:RegisterForDrag("LeftButton")

	local name = mover:CreateFontString(nil, 'OVERLAY', "GameFontNormal")
	name:SetPoint('CENTER')
	name:SetJustifyH('CENTER')
	name:SetFont(GameFontNormal:GetFont(), 12)
	name:SetTextColor(1, 1, 1)

	mover.name = name
	mover.obj = obj
	mover.header = isHeader
	mover.target = target

	mover:SetBackdropBorderColor(0, .9, 0)
	mover:SetBackdropColor(0, .9, 0)

	mover.baseWidth, mover.baseHeight = obj:GetSize()

	mover:SetScript("OnShow", function(self)
		return self.name:SetText(ns.smartName(self.obj, self.header))
	end)
	
	mover:SetScript("OnHide",  function(self)
		if self.dirtyMinHeight then
			self:SetAttribute('minHeight', nil)
		end

		if self.dirtyMinWidth then
			self:SetAttribute('minWidth', nil)
		end
	end)
	
	mover:SetScript("OnDragStart", function(self)
		ns.saveDefaultPosition(self.obj)
		self:StartMoving()

		local frame = self.header or self.obj
		frame:ClearAllPoints()
		frame:SetAllPoints(self)
	end)
	
	mover:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		ns.savePosition(self.obj, self)

		-- Restore the initial anchoring, so the anchor follows the frame when we
		-- edit positions through the UI.
		ns.restorePosition(self.obj)
		self:ClearAllPoints()
		self:SetAllPoints(self.header or self.obj)
	end)
	
	ns.moverPool[target] = mover

	return mover
	
end

function ns.ToggleMovers()

	if InCombatLockdown() then
		print("Movers cannot be toggled while in combat")
		return
	end
	
	debug("ToggleMovers")
	
	if not ns.anchor then
		for k, obj in next, dUF.objects do
			local unit = obj.unit
			if unit then
				local mover = ns.getMover(obj)
				if mover then mover:Show() end
			end
		end
		ns.anchor = true
	else
		for _, mover in pairs(ns.moverPool) do
			mover:Hide()
		end
		ns.anchor = nil
	end
	
end
