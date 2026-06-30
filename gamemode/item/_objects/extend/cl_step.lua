local meta = FindMetaTable("ItemObj")

function meta:StepItem()
	if self:IsPhysicsEnabled() then self:SyncWithPhysbox() end
	if self.isPickedUp then self:StepPickedUp() end
	if self.isBeingPopped then self:StepPop() end
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
		self.rotation = Lerp(0.2, self.rotation, self.desiredRotation or 0)
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