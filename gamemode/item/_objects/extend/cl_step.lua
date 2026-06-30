local meta = FindMetaTable("ItemObj")

function meta:StepItem()
	if self:IsPhysicsEnabled() then self:SyncWithPhysbox() end
	if self.isPickedUp then self:StepPickedUp() end
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