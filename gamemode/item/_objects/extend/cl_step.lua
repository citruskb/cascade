local meta = FindMetaTable("ItemObj")

function meta:StepItem()

	-- Sync up with physics if we should be applying physics.
	if self:IsPhysicsEnabled() then self:SyncWithPhysbox() end

	-- Pull the object's position around while it's being held.
	if self.isPickedUp then self:StepPickedUp() end

	-- Object is being thrown back to a location it needs to be inside.
	-- Could be back to the inventory, or back to the shop if you can't afford purchase, etc.
	if self.isBeingPopped then self:StepPop() end

	-- We applied rotation to the object. Make sure it rotates to completion.
	-- But only if it's being held, being popped, or in the inventory.
	if self.isPickedUp or self.isBeingPopped and
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
	if self.position:DistanceSqr(gamemode.Call("GetPopTo")) >= popMagdt * popMagdt then return end

	self.isBeingPopped = false

	self:EnablePhysics()
	self.physbox.isSleeping = false
	self.physbox.velocity = self.popDir * PHYS2D_POP_VELOCITY
end

function meta:StepDesiredRotation()
	self.rotation = Lerp(0.12, self.rotation, self.desiredRotation or 0)
end