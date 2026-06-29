if not PhysObjWall then
	countPhysObjWall = 0
	GM.physObjWalls = {}
	PhysObjWall = Class:Create(nil, "PhysObjWall")
end

local meta = FindMetaTable("PhysObjWall")

function PhysObjWall:__Create(position, pointsObj)
	-- We don't use the size of the table because these objects can be removed.
	countPhysObjWall = countPhysObjWall + 1
	self.id = countPhysObjWall

	self.position = position
	self.rotation = 0

	self.physbox = Physbox2:Create(self)
	self.physbox:AddHitbox(pointsObj)
	self.physbox.isStatic = true

	self.isPhysObjWall = true

	GAMEMODE.physObjWalls[self] = true

	return self
end

function PhysObjWall:ToString() return "[PhysObjWall] #" .. self.id end
function PhysObjWall:Eq(other)
	if not IsTable(other) then return false end
	if not other.isPhysObjWall then return false end
	return self.id == other.id
end

function meta:Remove()
	GAMEMODE.physObjWalls[self] = nil
	table.Empty(self)
end

function GM:NewPhysObjWall(position, pointsObj)
	return PhysObjWall:Create(position, pointsObj)
end