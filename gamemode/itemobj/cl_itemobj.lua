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

	--print("try set id:", self.id, countItemObj)

	self.itemDataID = itemDataID

	print(self.id, self.itemDataID)
	--print(self)
	self.itemData = GAMEMODE.BackpackItems[itemDataID]
	--print("Check2:", self, self.id)
	self.isContainer = self.itemData.type == ITEM_TYPE_CONTAINER
	--print("Check3:", self, self.id)
	self.isNormalItem = self.itemData.type == ITEM_TYPE_NORMAL
	--print("Check4:", self, self.id)
	self.isAugment = self.itemData.type == ITEM_TYPE_AUGMENT
	--print("Check5:", self, self.id)

	--print("try set id2:", self.id, countItemObj)

	self.position = position or Vector2(0, 0)
	self.rotation = rotation or 0
	self.owner = owner
	--print("Check6:", self, self.id)

	--print("Lovely creation!", self, self.id)

	self:InitPhysbox()

	--print("Physbox init.")

	self.isItemObj = true

	GAMEMODE.itemObjs[self] = true

	return self
end

function ItemObj:ToString()
	return "[ItemObj] #" .. self.id .. " | " .. self.itemDataID.id
end
function ItemObj:Eq(other)
	if not IsTable(other) then return false end
	if not other.isItemObj then return false end
	return self.id == other.id
end

function meta:InitPhysbox()
	print("passing self: ", self, self.id)
	self.physbox = Physbox2:Create(self)

	for i = 1, #self.itemData.hitboxPoints do
		local pointObj = self.itemData.hitboxPoints[i]
		self.physbox:AddHitbox(pointObj * GAMEMODE.UncappedScreenScale)
	end
end

function meta:EnablePhysics() self.physbox:EnablePhysics() end
function meta:DisablePhysics() self.physbox:DisablePhysics() end

function meta:Remove()
	print("I AM BEING REMOVED HELP")
	GAMEMODE.itemObjs[self] = nil
	table.Empty(self)
end

function GM:NewItemObj(itemDataID, position, rotation, owner)
	return ItemObj:Create(itemDataID, position, rotation, owner)
end