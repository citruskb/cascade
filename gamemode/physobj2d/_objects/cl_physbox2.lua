if not Physbox2 then
	Physbox2Count = 0
	GM.DebugObjects = {}
	Physbox2 = Class:Create(nil, "Physbox2")
end

local meta = FindMetaTable("Physbox2")

function meta:EnablePhysics() self.isPhysicsEnabled = true end
function meta:DisablePhysics()
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

function meta:AddPosition(vec2)
	if not self.isPhysicsEnabled then return end
	self.position:DoAdd(vec2)
end

function meta:AddRotation(num)
	if not self.isPhysicsEnabled then return end
	self.rotation = self.rotation + num
end

function meta:GetSize() return self.w, self.h end

function Physbox2:__Create(parent)
	-- Makes sure we have a unique ID for contact persistence.
	Physbox2Count = Physbox2Count + 1
	self.id = Physbox2Count

	self.parent = parent

	-- Init a bunch of dummy values.
	-- To be set up a better way later?
	self.hitboxes = {}
	self.isStatic = false
	self.density = 1
	self.mass = 1
	self.momentOfInertia = 1
	self.w = 0
	self.h = 0
	self.friction = 0.6
	self.restitution = 0.05

	self.fDist = 0
	self.camXYOffset = Vector2()
	self.isCamOrthoLocked = false

	-- Offsets our hitbox point origin to center ourselves inside the item panel.
	self.originCenterOffset = Vector2()

	-- Initializes physics values.
	self.position = parent.position
	self.rotation = parent.rotation
	self:RerollRandomAirborneRotation()
	self:DisablePhysics()

	self.boundCells = {}
	self.bindPoints = {}
	self.backpackBindPoints = {}
	self.bindPointsCellIDX = {}

	self.isScreenScaled = parent.isScreenScaled
	self.isInGridInventory = false

	PhysObj2D.physboxes[self] = true
	self.isPhysbox2 = true

	self.checkStartSleep = 0
	self.isSleeping = false

	return self
end

function Physbox2:ToString()
	return "[Physbox2] #" .. self.id
end

function Physbox2:Eq(other)
	if not IsTable(other) then return false end
	if not other.isPhysbox2 then return false end
	return self.id == other.id
end

function meta:AddHitbox(points, noResize)
	local id = #self.hitboxes + 1
	self.hitboxes[id] = Hitbox2:Create(self, points, id)

	-- We need to find the furthest point from all our hitbox centers.
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
	self.fDist = (fDist * 2) + 2
	self.camXYOffset = -Vector2(self.fDist * 0.5, self.fDist * 0.5)

	self:RecalculateSize()
	self:RecalculateMassAndInertia()

	local w, h = self:GetSize()
	self.originCenterOffset = -Vector2(w * 0.5, h * 0.5)
end

function meta:GetAllHitboxPoints()
	local allpoints
	for _, hitbox in pairs(self.hitboxes) do
		if not allpoints then
			allpoints = hitbox.pointsObj
			continue
		end

		allpoints = allpoints:CombineWith(hitbox.pointsObj)
	end

	return allpoints
end

function meta:GetAABB(raw)
	if raw and self.aabbRaw then return self.aabbRaw end
	if self.aabb then return self.aabb end

	local aabb = AABB2:Create(Vector2(math.HUGE, math.HUGE), -Vector2(math.HUGE, math.HUGE))
	for _, hitbox in pairs(self.hitboxes) do
		aabb:Expand(raw and hitbox.pointsObj or hitbox:GetHBScreenPointsObj())
	end

	if raw then
		self.aabbRaw = aabb
	else
		self.aabb = aabb
	end

	return aabb
end

function meta:RecalculateSize()
	self.aabb = nil
	self.aabbRaw = nil

	local aabb = self:GetAABB(true)
	local min, max = aabb.min, aabb.max
	self.w = max.x - min.x
	self.h = max.y - min.y
end

-- TODO better estimates.
-- Possibly calculate these for all hitboxes then add together?
function meta:RecalculateMassAndInertia()
	local w, h = self:GetSize()
	self.mass = self.isStatic and math.HUGE or self.density * w / 100 * h / 100
	self.momentOfInertia = self.isStatic and math.HUGE or (self.mass * (w * w + h * h)) / 12
end

-- The center of our physbox, relative to screenspace.
function meta:GetCenterScreenPoint()
	return self.position
end

-- (0,0) of the grid the hitbox's points draw on.
function meta:GetScreenHitboxPointsOrigin()
	local w, h = self:GetSize()
	return self.position - Vector2(w * 0.5, h * 0.5)
end

-- For now, we need to handle what happens if our parent panel gets removed.
function meta:Remove()
	PhysObj2D.physboxes[self] = nil

	for _, hitbox in pairs(self.hitboxes) do hitbox:Remove() end

	table.Empty(self)
end

-- TODO may need to recode a bit
function meta:Step(dt)
	self.aabb = nil
	self.aabbRaw = nil

	self:StepPhysics(dt)
end

function meta:StepPhysics(dt)
	if not self.isPhysicsEnabled then return end

	if self.isSleeping then
		self.velocity:Zero()
		self.angularVelocity = 0
	else
		-- Move & rotate
		self:AddPosition(self.velocity * dt)
		self:AddRotation(self.angularVelocity * dt)
	end
end

function meta:ApplyImpulse(impulse, screenPoint)
	local r = screenPoint - self:GetCenterScreenPoint()
	local angularImpulse = r:Cross(impulse)

	self:AddVelocity(impulse / self.mass)
	self:AddAngularVelocity(angularImpulse / self.momentOfInertia)
end

function meta:RerollRandomAirborneRotation()
	self.randomAirborneRotation = math.Rand(-PHYS2D_RANDOM_AIRBORNE_ROTATION, PHYS2D_RANDOM_AIRBORNE_ROTATION)
end
