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
	self.isPickedUp = false
	self.isInGridInventory = false

	self.isBeingPopped = false
	self.popTo = Vector2()

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

function meta:UpdateParentVars()
end

-- TODO may need to recode a bit
function meta:Step(dt)
	self.aabb = nil
	self.aabbRaw = nil

	self:StepPhysics(dt)
	self:StepPickup(dt)
	self:StepPop(dt)
	self:StepGridInventory(dt)
end

function meta:StepPhysics(dt)
	if (not self.isPhysicsEnabled) or self.isInGridInventory then return end

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
	if not self.isPickedUp and not self.isBeingPushed and not self.isInGridInventory then return end

	if self.isPickedUp then
		local mousePos = GAMEMODE.CachedMousePressedPos
		self.position = LerpVector2(0.7, self.position, mousePos)
	end

	if not math.IsNearlyEqual(self.rotation, self.desiredRotation or 0) then
		self.rotation = Lerp(0.2, self.rotation, self.desiredRotation or 0)
	end

	self:UpdateParentPosAndRot()
end

-- TODO: Cache. Refresh if we detect a screenscale change.
function meta:GetPopTo()
	local w, h = ScrW(), ScrH()
	return Vector2(w * 0.55, h * 0.5)
end

function meta:StepPop(dt)
	if not self.isBeingPopped then return end

	local popMagdt = PHYS2D_POP_VELOCITY * dt
	self.position:DoAdd(self.popDir * popMagdt)

	self:UpdateParentPosAndRot()

	-- Check if we've reached our destination.
	if self.position:DistanceSqr(self:GetPopTo()) >= popMagdt * popMagdt then return end
	self:EnablePhysics()
	self.isSleeping = false
	self.isBeingPopped = false
	self.velocity = self.popDir * PHYS2D_POP_VELOCITY
end

function meta:StepGridInventory(dt)
	if not self.isInGridInventory then return end
	local bindPoint = self.bindPoints[1]
	local idx = self.bindPointsCellIDX[1]
	local target = self.boundCells[idx]:GetAssocScreenBindPoint()
	local delta = target - bindPoint

	if delta:IsEqualTol(VECTOR2_ZERO, 1E-4) then return end

	self.position = LerpVector2(0.1, self.position, self.position + delta)
	self:UpdateParentPosAndRot()
end

function meta:UpdateParentPosAndRot()
	self.parent.position:Set(self.position)
	self.parent.rotation = self.rotation
	self:EvalBindPoints()
end

function meta:EvalBindPoints()
	local tab = self.parent.itemData.gridPoints
	if not tab then Error("[PhysObj2D] Unbound gridpoints") end

	local ang = self:GetNearest90() -- TODO cache somehow?
	ang = math.Ang(ang)
	local idx = math.Round(ang, 0) % 360

	local pointsObj = tab[idx]
	if not pointsObj then Error("[PhysObj2D] No gridpoints for angle: " .. idx) end

	-- Calculate our bindpoints.
	self.bindPoints = {}
	local pointsTab = pointsObj:GetPoints()
	local siz = gamemode.Call("GetInventoryGridSize")
	local origin = self:GetScreenHitboxPointsOrigin()
	origin = origin + Vector2(siz * 0.5, siz * 0.5)

	for i = 1, #pointsTab do
		local point = pointsTab[i]
		self.bindPoints[i] = origin + self.parent.itemData.gridPointsOffsets[idx] + point * siz
	end

	-- Find the associated bindpoints if they were in the backpack.
	self.backpackBindPoints = {}
	for i = 1, #self.bindPoints do
		self.backpackBindPoints[i] = gamemode.Call("GetNearestScreenBindPointIndex", self.bindPoints[i])
	end

	-- Calculate if we can be put in each bindpoint.
	-- We only need to do this if we're the held item.
	if not GAMEMODE.HeldItem then return end
	if GAMEMODE.HeldItem ~= self then return end

	local backpack = GAMEMODE.backpack

	local _, placeableList, notPlaceableList = self:GetIsPlaceableOnBinds()
	for i = 1, #self.bindPoints do
		local id = self.backpackBindPoints[i]
		local cell = backpack.cellsScreenIDX[id]
		if not cell then continue end

		cell.canPlaceDraw = placeableList[i]
		cell.cannotPlaceDraw = notPlaceableList[i]
	end
end

function meta:GetIsPlaceableOnBinds()
	local backpack = GAMEMODE.backpack
	local indexes = self.backpackBindPoints
	local placeableTab, notPlaceableTab = {}, {}

	-- If we find a bindpoint thats entirely outside the inventory, no dice.
	local canPlace = true
	local isOutside = false
	for i = 1, #indexes do
		if backpack.cellsScreenIDX[indexes[i]] then continue end

		canPlace = false
		isOutside = true
		break
	end

	-- Whether we can place an item depends on what kind of item it is.
	for i = 1, #indexes do
		-- If any part of us is outside the play grid, mark our entirety as not placeable.
		if isOutside then
			notPlaceableTab[i] = true
			placeableTab[i] = nil
			canPlace = false
			continue
		end

		local cell = backpack.cellsScreenIDX[indexes[i]]
		if not cell then continue end

		-- Containers can only be placed on spots that are entirely empty.
		if self.parent.isContainer then
			if cell:IsCompletelyEmpty() then
				placeableTab[i] = true
				notPlaceableTab[i] = nil
				continue
			end
			if cell.heldContainer and cell.heldContainer ~= self then
				notPlaceableTab[i] = true
				placeableTab[i] = nil
				canPlace = false
			end
		end

		-- In contrast, normal items can only be placed on containers not holding anything else.
		if self.parent.isNormalItem then
			if cell:IsContainerButEmpty() then
				placeableTab[i] = true
				notPlaceableTab[i] = nil
				continue
			end
			if not cell.heldContainer then
				notPlaceableTab[i] = true
				placeableTab[i] = nil
				canPlace = false
			end
			if cell.heldItem and cell.heldItem ~= self then
				notPlaceableTab[i] = true
				placeableTab[i] = nil
				canPlace = false
			end
		end

		placeableTab[i] = not notPlaceableTab[i]
	end

	-- TODO augments
	return canPlace, placeableTab, notPlaceableTab
end

function meta:ApplyImpulse(impulse, screenPoint)
	local r = screenPoint - self:GetCenterScreenPoint()
	local angularImpulse = r:Cross(impulse)

	self:AddVelocity(impulse / self.mass)
	self:AddAngularVelocity(angularImpulse / self.momentOfInertia)
end

function meta:MousePickup(isInsideInventoryBounds)
	self:DisablePhysics()
	self:SnapToNearest90()
	self.isSleeping = false
	self.isInGridInventory = false
	self.isPickedUp = true
end

function meta:RerollRandomAirborneRotation()
	self.randomAirborneRotation = math.Rand(-PHYS2D_RANDOM_AIRBORNE_ROTATION, PHYS2D_RANDOM_AIRBORNE_ROTATION)
end

function meta:MouseDrop(isInsideInventoryBounds)
	self.isPickedUp = false
	self.isCamOrthoLocked = true
	self:RerollRandomAirborneRotation()

	if isInsideInventoryBounds then
		self:RemoveFromInventoryCells()
		self:EnablePhysics()

		-- Mitigate tossing the ortho view upwards.
		local _, y = self:GetAdjCamPosition():Unpack()
		self:AddVelocity(GAMEMODE.CachedMouseVelocity * (y < 0 and 0.1 or 1))
	else
		self:Pop()
	end
end

function meta:MouseCanGrab()
	return
		not self.isStatic and
		not self.isBeingPopped and
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

function meta:RemoveFromInventoryCells()
	if table.Count(self.boundCells) <= 0 then return end

	for idx, cell in pairs(self.boundCells) do
		-- If we are a container, what we were holding needs to pop out.
		if self.parent.isContainer then
			--if cell.heldItem then cell.heldItem:Pop() end
			cell.heldContainer = nil
		elseif self.parent.isNormalItem then
			cell.heldItem = nil
		end
	end

	table.Empty(self.boundCells)
	table.Empty(self.bindPointsCellIDX)
end

-- Move from where it is back to inventory.
function meta:Pop()
	if self.isStatic then return end

	self:RemoveFromInventoryCells()
	self.isInGridInventory = false
	self.isBeingPopped = true
	self.popDir = (self:GetPopTo() - self.position):GetNormalized()

	gamemode.Call("PlaySnd", "pop")
end

local ROT_STEP = math.PI * 0.5 -- 90 degrees
function meta:GetNearest90()
	local rot = math.Abs(self.rotation)
	while rot > ROT_STEP do rot = rot - ROT_STEP end

	-- Are we closer to zero degrees or 90?
	local closerToZero = rot - ROT_STEP * 0.5 < 0

	local rotCloserToZero = rot
	local rotFurtherFromZero = ROT_STEP - rot

	-- Turn the opposite way if we are negative.
	if self.rotation > 0 then
		return self.rotation + (closerToZero and -rotCloserToZero or rotFurtherFromZero)
	else
		return self.rotation - (closerToZero and -rotCloserToZero or rotFurtherFromZero)
	end
end

function meta:SnapToNearest90()
	self.desiredRotation = self:GetNearest90()
end

function meta:Rotate90CW()
	self.desiredRotation = (self.desiredRotation or 0) + ROT_STEP
end

function meta:Rotate90CCW()
	self.desiredRotation = (self.desiredRotation or 0) - ROT_STEP
end

function meta:EvalGridInventoryPlacement()
	local isPlaceable, _, _ = self:GetIsPlaceableOnBinds()
	if not isPlaceable then return end

	-- Bind!
	self:RemoveFromInventoryCells()

	local indexes = self.backpackBindPoints
	local backpack = GAMEMODE.backpack
	for i = 1, #indexes do
		local cell = backpack.cellsScreenIDX[indexes[i]]
		self.boundCells[indexes[i]] = cell
		self.bindPointsCellIDX[i] = indexes[i]

		if self.parent.isContainer then
			cell.heldContainer = self
		elseif self.parent.isNormalItem then
			cell.heldItem = self
		end
	end

	self.isPickedUp = false
	self.isInGridInventory = true

	if self.parent.itemData.PlayPlaceSound then self.parent.itemData.PlayPlaceSound() end
end