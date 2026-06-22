if not PhysObj2 then
	countPhysObj2 = 0
	GM.PhysicsObjects2D = {}
	PhysObj2 = Class:Create(nil, "PhysObj2")
end

local meta = FindMetaTable("PhysObj2")

function PhysObj2:__Create(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
	-- We don't use the size of the table because these objects can be removed.
	countPhysObj2 = countPhysObj2 + 1
	self.id = countPhysObj2

	self.isScreenScaled = not isStatic

	self.position = position
	self.rotation = rotation or 0

	if itemDataID.isPointsObj then
		self.hitboxPoints = itemDataID
	else
		self.itemData = GAMEMODE.BackpackItems[itemDataID]
	end

	self:InitPhysbox(velocity, angularVelocity, isStatic)

	GAMEMODE.PhysicsObjects2D[self.id] = self

	self.isPhysObj2 = true

	return self
end

function PhysObj2:ToString() return "[PhysObj2] #" .. self.id end
function PhysObj2:Eq(other)
	if not IsTable(other) then return false end
	if not other.isPhysObj2 then return false end
	return self.id == other.id
end

function meta:InitPhysbox(velocity, angularVelocity, isStatic)
	self.physbox = Physbox2:Create(self)

	self.physbox.isStatic = isStatic or self.physbox.isStatic
	if not self.physbox.isStatic then
		self.physbox.velocity = velocity or self.physbox.velocity
		self.physbox.angularVelocity = angularVelocity or self.physbox.angularVelocity
	end

	self:AddHitboxesToPhysbox()
end

function meta:AddHitboxesToPhysbox()
	-- We assume we need to scale based on screenscale if it's an item, and that we've already scaled based on screenscale if this is a static wall.

	local hitboxPoints = self.hitboxPoints and {self.hitboxPoints} or self.itemData.hitboxPoints
	for i = 1, #hitboxPoints do
		local pointsTab = hitboxPoints[i]:GetPoints() -- TODO maybe add a shortcut for this in the points obj.
		local scaledPointsTab = {}
		for j = 1, #pointsTab do
			scaledPointsTab[j] = pointsTab[j] * (self.isScreenScaled and GAMEMODE.UncappedScreenScale or 1)
		end

		self.physbox:AddHitbox(Points(scaledPointsTab))
	end
end

function meta:EnablePhysics() self.physbox:EnablePhysics() end
function meta:DisablePhysics() self.physbox:DisablePhysics() end

function meta:Remove()
	GAMEMODE.PhysicsObjects2D[self.id] = nil
	table.Empty(self)
end

function GM:NewPhysObj2(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
	return PhysObj2:Create(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
end