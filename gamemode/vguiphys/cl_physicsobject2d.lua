if not PhysicsObject2D then
	countPhysicsObjects2D = 0
	GM.PhysicsObjects2D = {}
	PhysicsObject2D = Class:Create(nil, "PhysicsObject2D")
end

local meta = FindMetaTable("PhysicsObject2D")

function PhysicsObject2D:__Create(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
	-- We don't use the size of the table because these objects can be removed.
	countPhysicsObjects2D = countPhysicsObjects2D + 1
	self.id = countPhysicsObjects2D

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

	self.isPhysicsObject2D = true

	return self
end

function PhysicsObject2D:ToString() return "PhysicsObject2D #" .. self.id end
function PhysicsObject2D:Eq(other)
	if not IsTable(other) then return false end
	if not other.isPhysicsObject2D then return false end
	return self.id == other.id
end

function meta:InitPhysbox(velocity, angularVelocity, isStatic)
	self.physbox = VGUIPhysbox:Create(self)

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

function GM:NewPhysicsObject2D(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
	return PhysicsObject2D:Create(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
end