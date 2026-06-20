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

function meta:AddPosition(vec2)
	if not self.isPhysicsEnabled then return end
	self.position:DoAdd(vec2)
end

function meta:AddRotation(num)
	if not self.isPhysicsEnabled then return end
	self.rotation = self.rotation + num
end

function VGUIPhysbox:__Create(parent)
	-- Makes sure we have a unique ID for contact persistence.
	VGUIPhysboxCount = VGUIPhysboxCount + 1
	self.id = VGUIPhysboxCount
	print("new physbox!", self.id)

	self.parent = parent

	-- Init a bunch of dummy values.
	-- To be set up a better way later?
	self.hitboxes = {}
	self.isStatic = false
	self.density = 1
	self.mass = 10
	self.momentOfInertia = 1
	self.friction = 0.6
	self.restitution = 0.05

	-- Offsets our hitbox point origin to center ourselves inside the item panel.
	self.originCenterOffset = Vector2()

	-- Initializes physics values.
	self.position = parent.position
	self.rotation = parent.rotation
	self:DisablePhysics()

	GAMEMODE.VGUIPhysboxes[self] = true
	self.isVGUIPhysbox = true

	self.checkStartSleep = 0
	self.isSleeping = false

	return self
end

function VGUIPhysbox:ToString()
	print("my id:", self.id)
	return "[VGUIPhysbox] #" --.. self.id
end

function VGUIPhysbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.VGUIPhysbox then return false end
	return self.id == other.id
end

function meta:AddHitbox(points, noResize)
	local id = #self.hitboxes + 1
	self.hitboxes[id] = VGUIHitbox:Create(self, points, id)

	print("added hitbox!", #self.hitboxes)

	self:RecalculateMassAndInertia()

	--[[
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
	]]

	-- The center of our hitbox points must align with the center of our item.
	-- If we make the assumption that the top left of all our points grids is 0,0 ...
	-- our grid origin is the center minus half the max x and half the max y.
	--PrintTable(self.hitboxes)
	local allpoints = self:GetAllHitboxPoints()
	self.originCenterOffset = Vector2(-allpoints:GetMaxX() * 0.5, -allpoints:GetMaxY() * 0.5)
end

function meta:GetAllHitboxPoints()
	local allpoints
	for _, hitbox in pairs(self.hitboxes) do
		if not allpoints then
			allpoints = hitbox.pointsObj
			continue
		end

		allpoints = allpoints + hitbox.pointsObj
	end

	return allpoints
end

function meta:GetAABB(raw)
	local aabb = VGUIAABB:Create(Vector2(math.HUGE, math.HUGE), -Vector2(math.HUGE, math.HUGE))
	for _, hitbox in pairs(self.hitboxes) do
		aabb:Expand(raw and hitbox.pointsObj or hitbox:GetHBScreenPointsObj())
	end
	return aabb
end

-- TODO better estimates.
-- Possibly calculate these for all hitboxes then add together?
function meta:RecalculateMassAndInertia()
	local w, h = 1, 1--self.parent:GetSize()
	self.mass = self.isStatic and math.HUGE or self.density * w / 100 * h / 100
	self.momentOfInertia = self.isStatic and math.HUGE or (self.mass * (w * w + h * h)) / 12
end

-- The center of our physbox, relative to screenspace.
function meta:GetCenterScreenPoint()
	local w, h
	if self.parent.isItem then
		w, h = self.parent:GetSize()
	else
		local aabb = self:GetAABB(true)
		local min, max = aabb.min, aabb.max
		w, h = max.x - min.x, max.y - min.y
	end

	return self.position + Vector2(w * 0.5, h * 0.5)
end

-- (0,0) of the grid the hitbox's points draw on.
function meta:GetScreenHitboxPointsOrigin()
	if self.parent.isItem then
		return self:GetCenterScreenPoint() + self.originCenterOffset
	else
		return self.position
	end
end

-- For now, we need to handle what happens if our parent panel gets removed.
function meta:Remove()
	print("do remove?")
	GAMEMODE.VGUIPhysboxes[self] = nil

	for _, hitbox in pairs(self.hitboxes) do hitbox:Remove() end

	table.Empty(self)
end

function meta:UpdateParentVars()
end

-- TODO may need to recode a bit
function meta:Step(dt)
	if not self.isPhysicsEnabled then return end

	if self.isSleeping then
		self.velocity:Zero()
		self.angularVelocity = 0
	else
		-- Move & rotate
		self:AddPosition(self.velocity * dt)
		self:AddRotation(self.angularVelocity * dt)

		-- Update our parent's position based on our's
		self.parent:SetPos(self.position:Unpack())
	end

	-- Rotate our parent's model to match us.
	if IsValid(self.parent.ModPan) then
		self.parent.ModPan.rotation = -self.rotation
	end
end

function meta:ApplyImpulse(impulse, screenPoint)
	local r = screenPoint - self:GetCenterScreenPoint()
	local angularImpulse = r:Cross(impulse)

	self:AddVelocity(impulse / self.mass)
	self:AddAngularVelocity(angularImpulse / self.momentOfInertia)
end