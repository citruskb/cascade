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
	self:InitGridPointEvaluator()

	self.isPickedUp = false

	self.isBeingPopped = false
	self.popTo = Vector2()
	self.poppedDir = Vector2()

	self.isInGridInventory = false

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

function meta:MousePickup()
	self.isPickedUp = true

	self:DisablePhysics()
	self:SnapToNearest90()

	self.physbox.isSleeping = false
	self.isInGridInventory = false
end

function meta:MouseDrop()
	self.isPickedUp = false

	self.physbox.isCamOrthoLocked = true
	self.physbox:RerollRandomAirborneRotation()

	if self:IsInsideInventoryBounds() then
		self.gridPointEvaluator:RemoveFromInventoryCells()
		self:EnablePhysics()

		-- Mitigate tossing the ortho view upwards.
		local _, y = self:GetAdjCamPosition():Unpack()
		self.physbox:AddVelocity(GAMEMODE.CachedMouseVelocity * (y < 0 and 0.1 or 1))
	else
		self:Pop()
	end
end

function meta:MouseCanGrab()
	return
		self.physbox and
		not self.physbox.isStatic and
		not self.isBeingPopped and
		not self.physbox.isCamOrthoLocked
end

function meta:IsInsideInventoryBounds()
	local x, y = self.position:Unpack()
	local floorAABB = GAMEMODE.InventoryFloor.physbox:GetAABB()
	local leftWallAABB = GAMEMODE.InventoryLeftWall.physbox:GetAABB()
	local rightWallAABB = GAMEMODE.InventoryRightWall.physbox:GetAABB()

	-- Remember, positive Y is down.
	local isInsideBounds =
		y < floorAABB.min.y and -- Our center point is above the floor.
		x > leftWallAABB.max.x and -- Our center point is right of the left wall.
		x < rightWallAABB.min.x	-- Our center point is left of the right wall.

	return isInsideBounds
end

function meta:Remove()
	GAMEMODE.itemObjs[self] = nil

	self.gridPointEvaluator:RemoveFromInventoryCells()

	table.Empty(self)
end

function GM:NewItemObj(itemDataID, position, rotation, owner)
	return ItemObj:Create(itemDataID, position, rotation, owner)
end