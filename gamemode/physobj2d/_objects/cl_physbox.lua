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

function meta:GetSize() return self.w, self.h end

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

	self.isScreenScaled = parent.isScreenScaled
	self.isPickedUp = false

	self.isBeingPushed = false
	self.pushTo = Vector2()

	GAMEMODE.VGUIPhysboxes[self] = true
	self.isVGUIPhysbox = true

	self.checkStartSleep = 0
	self.isSleeping = false

	return self
end

function VGUIPhysbox:ToString()
	return "[VGUIPhysbox] #" .. self.id
end

function VGUIPhysbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.VGUIPhysbox then return false end
	return self.id == other.id
end

function meta:AddHitbox(points, noResize)
	local id = #self.hitboxes + 1
	self.hitboxes[id] = VGUIHitbox:Create(self, points, id)

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

		allpoints = allpoints + hitbox.pointsObj
	end

	return allpoints
end

function meta:GetAABB(raw)
	if raw and self.aabbRaw then return self.aabbRaw end
	if self.aabb then return self.aabb end

	local aabb = VGUIAABB:Create(Vector2(math.HUGE, math.HUGE), -Vector2(math.HUGE, math.HUGE))
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
	print(self.w, self.h)
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
	GAMEMODE.VGUIPhysboxes[self] = nil

	for _, hitbox in pairs(self.hitboxes) do hitbox:Remove() end

	table.Empty(self)
end

function meta:UpdateParentVars()
end

-- TODO may need to recode a bit
function meta:Step(dt)
	self.aabb = nil
	self.aabbRaw = nil

	self:StepPhysics(dt)
	self:StepPickup(dt)
	self:StepPush(dt)
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

		self:UpdateParentPosAndRot()
	end
end

function meta:StepPickup(dt)
	if not self.isPickedUp then return end

	local mousePos = GAMEMODE.CachedMousePos
	--local ft = FrameTime()
	--print(ft * 100)
	self.position = LerpVector2(0.7, self.position, mousePos)

	self:UpdateParentPosAndRot()
end

-- TODO: Cache. Refresh if we detect a screenscale change.
function meta:GetPushTo()
	local w, h = ScrW(), ScrH()
	return Vector2(w * 0.55, h * 0.5)
end

function meta:StepPush(dt)
	if not self.isBeingPushed then return end

	local pushMagdt = VGUIPHYS_PUSH_VELOCITY * dt
	self.position:DoAdd(self.pushDir * pushMagdt)
	--VGUIPHYS_PUSH_VELOCITY

	self:UpdateParentPosAndRot()

	-- Check if we've reached our destination.
	if self.position:DistanceSqr(self:GetPushTo()) >= pushMagdt * pushMagdt then return end
	self:EnablePhysics()
	self.isSleeping = false
	self.isBeingPushed = false
	self.velocity = self.pushDir * VGUIPHYS_PUSH_VELOCITY
end

function meta:UpdateParentPosAndRot()
	self.parent.position:Set(self.position)
	self.parent.rotation = self.rotation
end

function meta:ApplyImpulse(impulse, screenPoint)
	local r = screenPoint - self:GetCenterScreenPoint()
	local angularImpulse = r:Cross(impulse)

	self:AddVelocity(impulse / self.mass)
	self:AddAngularVelocity(angularImpulse / self.momentOfInertia)
end

function meta:MousePickup()
	self:DisablePhysics()
	self.isSleeping = false
	self.isPickedUp = true
end

function meta:RerollRandomAirborneRotation()
	self.randomAirborneRotation = math.Rand(-VGUIPHYS_RANDOM_AIRBORNE_ROTATION, VGUIPHYS_RANDOM_AIRBORNE_ROTATION)
end

function meta:MouseDrop()
	self.isPickedUp = false
	self.isCamOrthoLocked = true
	self:RerollRandomAirborneRotation()

	if self:IsInsideInventoryBounds() then
		self:EnablePhysics()

		-- Mitigate tossing the ortho view upwards.
		local _, y = self:GetAdjCamPosition():Unpack()
		self:AddVelocity(GAMEMODE.CachedMouseVelocity * (y < 0 and 0.1 or 1))
	else
		self.isBeingPushed = true
		self.pushDir = (self:GetPushTo() - self.position):GetNormalized()
	end
end

function meta:MouseCanGrab()
	return
		not self.isStatic and
		not self.isBeingPushed and
		not self.isCamOrthoLocked
end

function meta:GetAdjCamPosition()
	return self:GetCenterScreenPoint() + self.camXYOffset + self.parent.itemData.camXYOffsetAdj
end

function meta:IsInsideInventoryBounds()
	local x, y = self.position:Unpack()
	local floorAABB = GAMEMODE.InventoryFloor.physbox:GetAABB()
	local leftWallAABB = GAMEMODE.InventoryLeftWall.physbox:GetAABB()
	local rightWallAABB = GAMEMODE.InventoryRightWall.physbox:GetAABB()

	-- Remember, positive Y is down.
	local isInsideBounds =
		y < floorAABB.min.y and -- Our center point is above the floor.
		x > leftWallAABB.max.x and -- Our center point is right of the left wall.
		x < rightWallAABB.min.x	-- Our center point is left of the right wall.

	return isInsideBounds
end