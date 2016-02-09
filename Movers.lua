-- Custom Frame Positions
local _name, ns = ...
local debug = ns.debug

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

		return { point = point, relative = 'UIParent', rpoint = point, x = x, y = y }

	else

		local point, relative, rpoint, x, y = anchor:GetPoint()
		return { point = point, relative = relative, rpoint = rpoint, x = x, y = y }
	
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
	obj:ClearAllPoints()

	obj:_SetPoint(pos.point, pos.relative, pos.rpoint, pos.x, pos.y)
	
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
	ns.uconfig[unit].position.custom = ns.getPosition(obj, anchor)
	
end

--[=[
function ns.saveUnitPosition(unit, point, x, y, scale)
	debug("saveUnitPosition", unit, point, x, y, scale)
	if not ns.uconfig[unit] then ns.uconfig[unit] = {} end
	if not ns.uconfig[unit].position then ns.uconfig[unit].position = {} end	
	ns.uconfig[unit].position.custom = {
		point = point,
		relative = 'UIParent',
		x = x,
		y = y
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

	local unit = obj.unit
	if not unit then return end

	if not obj:GetCenter() then return end
	if ns.moverPool[unit] then return ns.moverPool[unit] end

	local mover = CreateFrame("Frame")
	mover:SetParent(UIParent)
	mover:Hide()

	mover:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"})
	mover:SetFrameStrata('TOOLTIP')
	mover:SetAllPoints(obj)

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

	mover:SetBackdropBorderColor(0, .9, 0)
	mover:SetBackdropColor(0, .9, 0)

	mover.baseWidth, mover.baseHeight = obj:GetSize()

	mover:SetScript("OnShow", function(self)
		return self.name:SetText(ns.smartName(self.obj))
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

		self.obj:ClearAllPoints()
		self.obj:SetAllPoints(self)
	end)
	
	mover:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		ns.savePosition(self.obj, self)

		-- Restore the initial anchoring, so the anchor follows the frame when we
		-- edit positions through the UI.
		ns.restorePosition(self.obj)
		self:ClearAllPoints()
		self:SetAllPoints(self.obj)
	end)
	
	ns.moverPool[unit] = mover

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
		for unit, mover in pairs(ns.moverPool) do
			mover:Hide()
		end
		ns.anchor = nil
	end
	
end
