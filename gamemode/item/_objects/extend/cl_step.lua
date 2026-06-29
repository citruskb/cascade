local meta = FindMetaTable("ItemObj")

function meta:StepItem()
	if self:IsPhysicsEnabled() then self:SyncWithPhysbox() end
end

function meta:SyncWithPhysbox()
	self.position:Set(self.physbox.position)
	self.rotation = self.physbox.rotation
end