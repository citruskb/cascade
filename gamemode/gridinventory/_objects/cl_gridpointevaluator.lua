if not GridPointEvaluator then
	GridPointEvaluator = Class:Create(nil, "GridPointEvaluator")
end

local meta = FindMetaTable("GridPointEvaluator")

function GridPointEvaluator:__Create(gridPointsTable, gridPointsOffsets, itemType)
	self.gridPointsTable = gridPointsTable
	self.gridPointsOffsets = gridPointsOffsets
	self.itemType = itemType

	self.bindPoints = {}
	self.backpackBindPoints = {}
	self.boundCells = {}
	self.bindPointsCellIDX = {}
	self.cleared = true

	return self
end
function GridPointEvaluator:ToString() return "[GridPointEvaluator]" end

function meta:Clear()
	self.bindPoints = {}
	self.backpackBindPoints = {}
	self.boundCells = {}
	self.bindPointsCellIDX = {}
	self.cleared = true
end

function meta:EvaluateBindPoints(origin, rotation)
	if not self.gridPointsTable then Error("[PhysObj2D] Unbound gridpoints") end

	local ang = math.Ang(rotation)
	local idx = math.Round(ang, 0) % 360

	if not self.gridPointsTable[idx] then Error("[PhysObj2D] No gridpoints for angle: " .. idx) end

	-- Calculate our bindpoints.
	self.bindPoints = {}
	local pointsTab = self.gridPointsTable[idx]:GetPoints()
	local siz = gamemode.Call("GetInventoryGridSize")
	origin = origin + Vector2(siz * 0.5, siz * 0.5)

	for i = 1, #pointsTab do
		self.bindPoints[i] = origin + self.gridPointsOffsets[idx] + pointsTab[i] * siz
	end

	self.cleared = false
end

function meta:EvaluateBackpackBindPoints()
	-- Find the associated bindpoints if they were in the backpack.
	self.backpackBindPoints = {}
	for i = 1, #self.bindPoints do
		self.backpackBindPoints[i] = gamemode.Call("GetNearestScreenBindPointIndex", self.bindPoints[i])
	end
end

function meta:EvaluateDrawnBackpackGrid(item)
	if not GAMEMODE.HeldItem then return end
	if GAMEMODE.HeldItem ~= item then return end

	local backpack = GAMEMODE.backpack
	local _, placeableList, notPlaceableList = backpack:GetIsPlaceableOnBinds(item, self.backpackBindPoints)

	for i = 1, #self.bindPoints do
		local id = self.backpackBindPoints[i]
		local cell = backpack.cellsScreenIDX[id]
		if not cell then continue end

		cell.canPlaceDraw = placeableList[i]
		cell.cannotPlaceDraw = notPlaceableList[i]
	end
end

-- TODO this really belongs in the inventory obj. probably.
function meta:BindItem(item)
	local isPlaceable, _, _ = GAMEMODE.backpack:GetIsPlaceableOnBinds(item, self.backpackBindPoints)
	if not isPlaceable then return end

	-- Bind!
	self:RemoveFromInventoryCells()

	local indexes = self.backpackBindPoints
	local backpack = GAMEMODE.backpack
	for i = 1, #indexes do
		local cell = backpack.cellsScreenIDX[indexes[i]]
		self.boundCells[indexes[i]] = cell
		self.bindPointsCellIDX[i] = indexes[i]

		if self.itemType == ITEM_TYPE_CONTAINER then
			cell.heldContainer = item
		elseif self.itemType == ITEM_TYPE_NORMAL then
			cell.heldItem = item
		end
	end

	return true
end

function meta:RemoveFromInventoryCells()
	if table.Count(self.boundCells) <= 0 then return end

	for idx, cell in pairs(self.boundCells) do
		-- If we are a container, what we were holding needs to pop out.
		if self.itemType == ITEM_TYPE_CONTAINER then
			if cell.heldItem then cell.heldItem:Pop() end
			cell.heldContainer = nil
		elseif self.itemType == ITEM_TYPE_NORMAL then
			cell.heldItem = nil
		end
	end

	table.Empty(self.boundCells)
	table.Empty(self.bindPointsCellIDX)
end