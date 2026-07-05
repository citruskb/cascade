local meta = FindMetaTable("GridInventory")

-- Accepts a starting vector, then a points object of vectors relative to that starting vector.
-- Returns the cells contained in the backpack along that config vector.
function meta:GetCellsAlongConfiguration(originIDX, config)
	local cells = {}
	local configPoints = config:GetPoints()

	for i = 1, #configPoints do
		local idx = gamemode.Call("TranslateBindPointIndex", originIDX, configPoints[i])
		table.Insert(cells, self.cellsScreenIDX[idx])
	end

	return cells
end

-- Accepts an itemid, origin backpack gridIDX, and orientation enumerable
-- Returns if it's placeable, valid cells, and invalid cells.
function meta:IsValidPlaceableAt(itemOrID, originIDX, orientation)
	local id, item
	if IsString(itemOrID) then
		id = itemOrID
	else
		item = itemOrID
	end

	local data = item and item.itemData or GAMEMODE.BackpackItems[id]
	local gridPointsObj = data.gridPoints[orientation]
	local cells = self:GetCellsAlongConfiguration(originIDX, gridPointsObj)

	local placeableTab, notPlaceableTab = {}, {}

	-- If we find a bindpoint thats entirely outside the inventory, no dice.
	local isAnyPartOutside = #cells ~= gridPointsObj:Count()
	local canPlace = not isAnyPartOutside

	-- We still want to find cells for relevant tables due to drawing preview.
	local itemData = id and GAMEMODE.BackpackItems[id] or item.itemData
	for i = 1, #cells do
		local cell = cells[i]

		-- What if one cell is inside and the rest are out? We want to highlight that one part inside as invalid.
		if isAnyPartOutside then
			notPlaceableTab[cell] = true
			placeableTab[cell] = nil
			continue
		end

		-- Containers can only be placed on spots that are entirely empty.
		if itemData.type == ITEM_TYPE_CONTAINER then
			if cell:IsCompletelyEmpty() then
				placeableTab[cell] = true
				notPlaceableTab[cell] = nil
				continue
			end

			if cell.heldContainer and ((item and cell.heldContainer ~= item) or not item) then
				notPlaceableTab[cell] = true
				placeableTab[cell] = nil
				canPlace = false
			end
		end

		-- In contrast, normal items can only be placed on containers not holding anything else.
		if itemData.type == ITEM_TYPE_NORMAL or itemData.type == ITEM_TYPE_AUGMENT then
			if cell:IsContainerButEmpty() then
				placeableTab[cell] = true
				notPlaceableTab[cell] = nil
				continue
			end
			if not cell.heldContainer then
				notPlaceableTab[cell] = true
				placeableTab[cell] = nil
				canPlace = false
			end

			-- Handle case for if we are pickup and already placed item.
			if cell.heldItem and (item and cell.heldItem ~= item or not item) then
				notPlaceableTab[cell] = true
				placeableTab[cell] = nil
				canPlace = false
			end
		end

		-- if we haven't determined it isn't placeable, then it's placeable.
		if notPlaceableTab[cell] ~= nil or not canPlace then continue end
		placeableTab[cell] = true
	end

	-- TODO augments
	return canPlace, table.ToKeyValues(placeableTab), table.ToKeyValues(notPlaceableTab)
end

--TODO: Adjust this to take
-- 1. item id
-- 2. insertion point
-- 3. object orientation
-- to determine if it'll fit.
function meta:GetHeldIsPlaceableOnBinds(item, indexes)
	local placeableTab, notPlaceableTab = {}, {}

	-- If we find a bindpoint thats entirely outside the inventory, no dice.
	local canPlace = true
	local isOutside = false
	for i = 1, #indexes do
		if self.cellsScreenIDX[indexes[i]] then continue end

		canPlace = false
		isOutside = true
		break
	end

	-- Whether we can place an item depends on what kind of item it is.
	for i = 1, #indexes do
		-- If any part of us is outside the play grid, mark our entirety as not placeable.
		if isOutside then
			notPlaceableTab[i] = true
			placeableTab[i] = nil
			canPlace = false
			continue
		end

		local cell = self.cellsScreenIDX[indexes[i]]
		if not cell then continue end

		-- Containers can only be placed on spots that are entirely empty.
		if item.isContainer then
			if cell:IsCompletelyEmpty() then
				placeableTab[i] = true
				notPlaceableTab[i] = nil
				continue
			end
			if cell.heldContainer and cell.heldContainer ~= item then
				notPlaceableTab[i] = true
				placeableTab[i] = nil
				canPlace = false
			end
		end

		-- In contrast, normal items can only be placed on containers not holding anything else.
		if item.isNormalItem then
			if cell:IsContainerButEmpty() then
				placeableTab[i] = true
				notPlaceableTab[i] = nil
				continue
			end
			if not cell.heldContainer then
				notPlaceableTab[i] = true
				placeableTab[i] = nil
				canPlace = false
			end
			if cell.heldItem and cell.heldItem ~= item then
				notPlaceableTab[i] = true
				placeableTab[i] = nil
				canPlace = false
			end
		end

		placeableTab[i] = not notPlaceableTab[i]
	end

	-- TODO augments
	return canPlace, placeableTab, notPlaceableTab
end

function meta:UnbindItem(itemObj)
	for i = 1, #self.cells do
		local cell = self.cells[i]
		if itemObj.isContainer and cell.heldContainer == itemObj then
			cell.heldContainer = nil
		elseif (itemObj.isNormalItem or itemObj.isAugment) and cell.heldItem == itemObj then
			cell.heldItem = nil
		end
	end

	itemObj.boundTo = nil
	itemObj.bindOriginIDX = nil
end

function meta:BindItemObj(itemObj, originIDX, rotIDX)
	-- Are we placeable in this new spot & orientation?
	local isPlaceable, placeableTab, _ = self:IsValidPlaceableAt(itemObj, originIDX, rotIDX)
	if not isPlaceable then return end

	-- First, make sure if we already contain this item that we remove its old location.
	self:UnbindItem(itemObj)

	-- Next, add it to relevant cells.
	for i = 1, #placeableTab do
		local cell = placeableTab[i]
		if itemObj.isContainer then
			cell.heldContainer = itemObj
		elseif itemObj.isNormalItem or itemObj.isAugment then
			cell.heldItem = itemObj
		end
	end

	if not itemObj.desiredRotation then
		itemObj.rotation = ITEM_ORIENTATION_TO_ANGLE[rotIDX]
	else
		itemObj:SnapToNearest90() -- This assumes the nearest 90 degrees corresponds to the input rotIDX if our item wasn't created this frame.
	end

	itemObj:OnBackpackBind(self, originIDX)
end

-- Make a new item. Insert it using BindItem.
function meta:BindNewItemObj(itemID, originIDX, rotIDX)
	local item = ItemObj:Create(itemID, gamemode.Call("BindPointIDXToVector2", originIDX), math.Rad(ITEM_ORIENTATION_TO_ANGLE[rotIDX]))
	self:BindItemObj(item, originIDX, rotIDX)
end