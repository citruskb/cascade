local meta = FindMetaTable("ItemObj")

function meta:StepItem()

	-- Sync up with physics if we should be applying physics.
	if self:IsPhysicsEnabled() then
		self:SyncWithPhysbox() end

	-- Pull the object's position around while it's being held.
	if self.isPickedUp then
		self:StepPickedUp() end

	-- Object is being thrown back to a location it needs to be inside.
	-- Could be back to the inventory, or back to the shop if you can't afford purchase, etc.
	if self.isBeingPopped then
		self:StepPop() end

	-- If we are placed in the grid inventory, ease the object into alignment with the grid.
	if self.isInGridInventory then
		self:StepGridInventory() end

	-- Evaluate our bind points if necessary!
	if self.isPickedUp or self.isInGridInventory then
		self:StepBindPoints()
	elseif not self.gridPointEvaluator.cleared then -- Clear them if not being used anymore.
		self.gridPointEvaluator.bindPoints = {}
		self.gridPointEvaluator.cleared = true
	end

	-- We applied rotation to the object. Make sure it rotates to completion.
	-- But only if it's being held, being popped, or in the inventory.
	if self.isPickedUp or self.isBeingPopped or self.isInGridInventory and
		not math.IsNearlyEqual(self.rotation, self.desiredRotation or 0) then
			self:StepDesiredRotation() end

end

function meta:SyncWithPhysbox()
	self.position:Set(self.physbox.position)
	self.rotation = self.physbox.rotation
end

function meta:StepPickedUp()
	if self.isPickedUp then
		local mousePos = GAMEMODE.CachedMousePressedPos
		self.position = LerpVector2(0.7, self.position, mousePos)
	end

	if not math.IsNearlyEqual(self.rotation, self.desiredRotation or 0) then
		self.rotation = Lerp(0.12, self.rotation, self.desiredRotation or 0)
	end
end

function meta:StepPop()
	local popMagdt = PHYS2D_POP_VELOCITY * PHYS2D_DT
	self.position:DoAdd(self.popDir * popMagdt)

	-- Check if we've reached our destination.
	if self.position:DistanceSqr(self.popTo) >= popMagdt * popMagdt then return end

	self.isBeingPopped = false
	self.popTo:SetUnpacked(0, 0)

	self:EnablePhysics()
	self.physbox.isSleeping = false
	self.physbox.velocity = self.popDir * PHYS2D_POP_VELOCITY
end

function meta:StepGridInventory()
	local bindPoint = self.gridPointEvaluator.bindPoints[1]
	local idx = self.gridPointEvaluator.bindPointsCellIDX[1]
	local target = self.gridPointEvaluator.boundCells[idx]:GetAssocScreenBindPoint()
	local delta = target - bindPoint

	if delta:IsEqualTol(VECTOR2_ZERO, 1E-4) then return end

	self.position = LerpVector2(0.1, self.position, self.position + delta)
end

function meta:StepBindPoints()
	self.gridPointEvaluator:EvaluateBindPoints(self:GetPhysboxPointsOrigin(), self.desiredRotation)
	self.gridPointEvaluator:EvaluateBackpackBindPoints()
	self.gridPointEvaluator:EvaluateDrawnBackpackGrid(self)
end

function meta:StepDesiredRotation()
	self.rotation = Lerp(0.12, self.rotation, self.desiredRotation or 0)
end