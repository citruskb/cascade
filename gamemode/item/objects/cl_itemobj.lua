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

	-- Add hitboxes to the physbox.
	-- Maybe this would fit better in the physbox object itself?
	for i = 1, #self.itemData.hitboxPoints do
		local pointsTab = self.itemData.hitboxPoints[i]:GetPoints() -- TODO maybe add a shortcut for this in the points obj.
		local scaledPointsTab = {}
		for j = 1, #pointsTab do
			scaledPointsTab[j] = pointsTab[j] * GAMEMODE.UncappedScreenScale
		end

		self.physbox:AddHitbox(Points(scaledPointsTab))
	end
end

function meta:Remove()
	GAMEMODE.itemObjects[self] = nil
	table.Empty(self)
end