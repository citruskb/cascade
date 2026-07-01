if not GridInventory then
	GridInventory = Class:Create(nil, "GridInventory")
end

local meta = FindMetaTable("GridInventory")

function GridInventory:__Create(w, h)
	self.w = w or GAMEMODE.BackpackGridX
	self.h = h or GAMEMODE.BackpackGridY

	self.cells = {}
	self.cellsScreenIDX = {}
	self:SetupCells()

	return self
end

function meta:SetupCells()
	for row = 1, self.h do
		for col = 1, self.w do
			local cell = GridInventoryCell:Create(col, row)
			self.cells[cell.id] = cell
		end
	end
end

function meta:BindToPanel(pan)
	for i = 1, #pan.grid:GetItems() do
		self.cells[i].bindPointIndex = pan.bindPointIndexes[i]
		self.cellsScreenIDX[pan.bindPointIndexes[i]] = self.cells[i]
	end
end

function meta:GetItemAt(idx)
	if not self.cells[idx] then return end
	return self.cells[idx].heldItem
end

function meta:PopUncontainedItems()
	for i = 1, #self.cells do
		local cell = self.cells[i]
		if not cell:IsFilledButShouldntBe() then continue end

		cell.heldItem:Pop()
	end
end

function meta:ClearGridDraw()
	for i = 1, #self.cells do
		local cell = self.cells[i]
		cell.canPlaceDraw = nil
		cell.cannotPlaceDraw = nil
	end
end

function meta:IsPlaceableAt(itemid, origin, orientation)
end

--TODO: Adjust this to take
-- 1. item id
-- 2. insertion point
-- 3. object orientation
-- to determine if it'll fit.
function meta:GetIsPlaceableOnBinds(item, indexes)
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

--[[
hook.Add("PostRenderVGUI", "PostRenderVGUI.backpack", function()
	local backpack = GAMEMODE.backpack
	if not backpack then return end
	backpack:ClearGridDraw()
end)
]]
