-- TODO: Add serverside implementation eventually, for verification of valid builds and server authoritative networking of combat stuff.

if not ItemObj then
	ItemObj = Class:Create(nil, "ItemObj")
	countItemObj = 0
	GM.itemObjects = {}
end

local meta = FindMetaTable("ItemObj")

function ItemObj:__Create(itemDataID, owner, position, rotation)
	-- We don't use the size of the table because these objects can be removed.
	countItemObj = countItemObj + 1
	self.id = countItemObj

	self.itemDataID = itemDataID
	self.owner = owner
	self.position = position
	self.rotation = rotation

	self:InitPhysbox()

	self.isItemObj = true

	GAMEMODE.itemObjects[self] = true
end

function ItemObj:ToString() return "[ItemObj] " .. self.itemDataID end
function ItemObj:Eq(other)
	if not IsTable(other) then return false end
	if not other.isItemObj then return false end
	return self.id == other.id
end

function meta:InitPhysbox()
	self.physbox = Physbox2:Create(self)

	for i = 1, #self.itemData.hitboxPoints do
		local pointObj = self.itemData.hitboxPoints[i]
		self.physbox:AddHitbox(pointObj * GAMEMODE.UncappedScreenScale)
	end
end

function meta:Remove()
	GAMEMODE.itemObjects[self] = nil
	table.Empty(self)
end