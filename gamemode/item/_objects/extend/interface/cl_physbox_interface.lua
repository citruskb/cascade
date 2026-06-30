local meta = FindMetaTable("ItemObj")

function meta:InitPhysbox()
	self.physbox = Physbox2:Create(self)

	for i = 1, #self.itemData.hitboxPoints do
		local pointObj = self.itemData.hitboxPoints[i]
		self.physbox:AddHitbox(pointObj * GAMEMODE.UncappedScreenScale)
	end
end

function meta:EnablePhysics()
	self.desiredRotation = nil

	self.physbox.position:Set(self.position)
	self.physbox.rotation = self.rotation

	self.physbox:EnablePhysics()
end
function meta:DisablePhysics() self.physbox:DisablePhysics() end
function meta:IsPhysicsEnabled() return self.physbox.isPhysicsEnabled end

function meta:GetPhysboxPointsOrigin()
	local w, h = self.physbox:GetSize()
	return self.position - Vector2(w * 0.5, h * 0.5)
end