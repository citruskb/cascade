local meta = FindMetaTable("GridInventory")

-- Accepts a starting vector, then a points object of vectors relative to that starting vector.
-- Returns the cells contained in the backpack along that config vector.
function meta:GetCellsAlongConfiguration(originIDX, config)
	local cells = {}
	local configPoints = config:GetPoints()

	for i = 1, #configPoints do
		local idx = gamemode.Call("TranslateBindPointIndex", originIDX, configPoints[i])
		table.Insert(cells, self.cells[idx])
	end

	return cells
end

-- Accepts an itemid, origin backpack gridIDX, and orientation enumerable
-- Returns if it's placeable, valid cells, and invalid cells.
function meta:IsValidPlaceableAt(itemOrID, originIDX, orientation)
	local data = GAMEMODE.BackpackItems[itemid]
	local gridPointsObj = data.gridPoints[orientation]
	local cells = self:GetCellsAlongConfiguration(originIDX, gridPointsObj)

	local placeableTab, notPlaceableTab = {}, {}

	-- If we find a bindpoint thats entirely outside the inventory, no dice.
	local isAnyPartOutside = #cells ~= gridPointsObj:Count()
	local canPlace = not isAnyPartOutside

	local id, item
	if IsString(itemOrID) then
		id = itemOrID
	else
		item = itemOrID
	end

	-- We still want to find cells for relevant tables due to drawing preview.
	local itemData = id and GAMEMODE.BackpackItems[id] or item.itemData
	for i = 1, #cells do
		local cell = cells[i]

		-- What if one cell is inside and the rest are out? We want to highlight that one part inside as invalid.
		if isAnyPartOutside then
			notPlaceableTab[cell] = true
			continue
		end

		-- Containers can only be placed on spots that are entirely empty.
		if itemData.isContainer then
			if cell:IsCompletelyEmpty() then
				placeableTab[cell] = true
				continue
			end

			-- Handle case for if we are picking up an already placed container.
			if item and cell.heldContainer and cell.heldContainer ~= item then
				notPlaceableTab[cell] = true
				canPlace = false
			end
		end

		-- In contrast, normal items can only be placed on containers not holding anything else.
		if itemData.isNormalItem then
			if cell:IsContainerButEmpty() then
				placeableTab[cell] = true
				continue
			end
			if not cell.heldContainer then
				notPlaceableTab[cell] = true
				canPlace = false
			end

			-- Handle case for if we are pickup and already placed item.
			if item and cell.heldItem and cell.heldItem ~= item then
				notPlaceableTab[cell] = true
				canPlace = false
			end
		end

		placeableTab[cell] = not notPlaceableTab[cell]
	end

	-- TODO augments
	return canPlace, placeableTab, notPlaceableTab
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