
if not VGUIPhysbox then
	VGUIPhysboxCount = 0
	GM.VGUIPhysboxes = {}
	GM.DebugObjects = {}
	VGUIPhysbox = Class:Create(nil, "VGUIPhysbox")
end

local meta = FindMetaTable("VGUIPhysbox")

function meta:EnablePhysics() self.isPhysicsEnabled = true end
function meta:DisablePhysics()
	-- We update our position by updating our parent's position.
	-- We accumulate changes via. deltaPosition then apply the net change when needed.
	-- Done this way mainly because absolute VGUI Panel positions are always whole numbers, so fractional changes are lost.
	self.velocity = Vector2()
	self.angularVelocity = 0

	self.isPhysicsEnabled = false
end

function meta:AddVelocity(vec2)
	if not self.isPhysicsEnabled then return end
	self.velocity:DoAdd(vec2)
end

function meta:AddAngularVelocity(num)
	if not self.isPhysicsEnabled then return end
	self.angularVelocity = self.angularVelocity + num
end

function meta:AddDeltaPosition(vec2)
	if not self.isPhysicsEnabled then return end
	self.deltaPosition:DoAdd(vec2)
end

function VGUIPhysbox:__Create(parent)
	-- Makes sure we have a unique ID for contact persistence.
	VGUIPhysboxCount = VGUIPhysboxCount + 1
	self.id = VGUIPhysboxCount

	self.parent = parent

	-- Init a bunch of dummy values.
	-- To be set up a better way later?
	self.hitboxes = {}
	self.isStatic = false
	self.density = 1
	self.mass = 1
	self.momentOfInertia = 1
	self.friction = 0.6
	self.restitution = 0.05

	-- Offsets our hitbox point origin to center ourselves inside the item panel.
	self.originCenterOffset = Vector2()

	-- Initializes physics values.
	self.deltaPosition = Vector2()
	self.rotation = 0
	self:DisablePhysics()

	GAMEMODE.VGUIPhysboxes[self] = true
	self.isVGUIPhysbox = true

	return self
end

function VGUIPhysbox:ToString() return "[VGUIPhysbox] #" .. self.id end

function VGUIPhysbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.VGUIPhysbox then return false end
	return self.parent == other.parent
end

function meta:AddHitbox(points, noResize)
	local id = #self.hitboxes + 1
	self.hitboxes[id] = VGUIHitbox:Create(self, points, id)

	local parent = self.parent
	GAMEMODE.DebugObjects[parent] = true

	if noResize then return end

	-- Adjust the parent size to accomodate rotation of our hitboxes around their center point.
	-- But only if our parent is an item.
	if not parent.IsItem then return end

	-- First we find the furthest point from all our hitbox centers.
	local allpoints = self:GetAllHitboxPoints()
	local center = allpoints:GetCenter()
	local fDistsq, fPoint

	local pointsTab = allpoints:GetPoints()
	for i = 1, #pointsTab do
		local point = pointsTab[i]
		local distsq = center:DistanceSqr(point) -- DistanceSqr is faster.

		if fDistsq and distsq < fDistsq then continue end
		fDistsq = distsq
		fPoint = point
	end

	-- Now that we know the furthest dist, get the actual distance.
	local fDist = center:Distance(fPoint)

	-- Next, our size is twice this plus a small buffer
	-- Setting our parent size also sets our "size"
	local siz = (fDist * 2) + 2
	parent:SetSize(siz, siz)

	self:RecalculateMassAndInertia()

	-- The center of our hitbox points must align with the center of our item.
	-- If we make the assumption that the top left of all our points grids is 0,0 ...
	-- our grid origin is the center minus half the max x and half the max y.
	self.originCenterOffset = Vector2(-allpoints:GetMaxX() * 0.5, -allpoints:GetMaxY() * 0.5)
end

function meta:GetAllHitboxPoints()
	local allpoints
	for _, hitbox in pairs(self.hitboxes) do
		if not allpoints then
			allpoints = hitbox:GetPoints()
			continue
		end

		allpoints = allpoints + hitbox:GetPoints()
	end

	return allpoints
end

-- TODO better estimates.
-- Possibly calculate these for all hitboxes then add together?
function meta:RecalculateMassAndInertia()
	local w, h = self.parent:GetSize()
	self.mass = self.isStatic and math.HUGE or self.density * w * h
	self.momentOfInertia = self.isStatic and math.HUGE or (self.mass * (w * w + h * h)) / 12
end

-- The center of our physbox, relative to screenspace.
function meta:GetCenterScreenPoint() return self.parent.scpos end

-- (0,0) of the grid the hitbox's points draw on.
function meta:GetScreenHitboxPointsOrigin() return self.parent.scpos + self.originCenterOffset end

-- For now, we need to handle what happens if our parent panel gets removed.
function meta:Remove()
	GAMEMODE.VGUIPhysboxes[self] = nil

	for _, hitbox in pairs(self.hitboxes) do hitbox:Remove() end

	table.Empty(self)
end

function meta:UpdateParentVars()
	-- When the partial movements get high enough, move our parent panel.
	-- Done this way because we can't move panels fractional pixels.
	local dx, dy = self.deltaPosition:Unpack()
	local roundedDelta = Vector2(math.Round(dx, 0), math.Round(dy, 0))
	if roundedDelta:IsZero() then return end

	local parent = self.parent
	local x, y = parent:GetPos()
	dx, dy = roundedDelta:Unpack()
	parent:SetPos(x + dx, y + dy)

	-- The movement has been applied.
	-- Therefore, subtract our movement from our delta position.
	self.deltaPosition:DoSub(roundedDelta)
end

-- TODO may need to recode a bit
function meta:Step(tim, iterations)
	if not self.isPhysicsEnabled then return end
	self:MarkHitboxesDirty()

	tim = tim / iterations

	local vel = Rawget(self, "_vel")

	-- Move & rotate
	self:AddPartialPos(vel * tim)
	self:AddRad(Rawget(self, "_radvel") * tim)

	-- Gravity.
	-- We apply this after moving to allow our solver a chance to respond to it.
	--[[
	local _, vy = Rawget(self, "_vel"):Unpack()
	if vy < VGUIPHYS_TERMINAL_VELOCITY then
		self:AddVel(VGUIPHYS_GRAVITY_VEC2 * tim)
	end
	]]
end

function meta:MarkHitboxesDirty()
	for _, hb in pairs(self.hitboxes) do hb:SetCacheDirty(true) end
end
