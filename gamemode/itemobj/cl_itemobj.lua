-- TODO: Add serverside implementation eventually, for verification of valid builds and server authoritative networking of combat stuff.

if not ItemObj then
	countItemObj = 0
	GM.itemObjs = {}
	ItemObj = Class:Create(nil, "ItemObj")
end

local meta = FindMetaTable("ItemObj")

function ItemObj:__Create(itemDataID, position, rotation, owner)
	-- We don't use the size of the table because these objects can be removed.
	countItemObj = countItemObj + 1
	self.id = countItemObj

	self.itemDataID = itemDataID

	self.itemData = GAMEMODE.BackpackItems[itemDataID]
	self.isContainer = self.itemData.type == ITEM_TYPE_CONTAINER
	self.isNormalItem = self.itemData.type == ITEM_TYPE_NORMAL
	self.isAugment = self.itemData.type == ITEM_TYPE_AUGMENT

	self.position = position or Vector2(0, 0)
	self.rotation = rotation or 0
	self.owner = owner

	self:InitPhysbox()

	self.isItemObj = true

	GAMEMODE.itemObjs[self] = true

	return self
end

function ItemObj:ToString()
	return "[ItemObj] #" .. ToString(self.id) .. " | " .. ToString(self.itemDataID)
end
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

function meta:EnablePhysics() self.physbox:EnablePhysics() end
function meta:DisablePhysics() self.physbox:DisablePhysics() end

function meta:Remove()
	GAMEMODE.itemObjs[self] = nil
	table.Empty(self)
end

function GM:NewItemObj(itemDataID, position, rotation, owner)
	return ItemObj:Create(itemDataID, position, rotation, owner)
end