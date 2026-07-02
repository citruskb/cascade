if not GridPointEvaluator then
	GridPointEvaluator = Class:Create(nil, "GridPointEvaluator")
end

local meta = FindMetaTable("GridPointEvaluator")

function GridPointEvaluator:__Create(gridPointsTable, gridPointsOffsets, synergyPointsTable, itemType)
	self.gridPointsTable = gridPointsTable
	self.gridPointsOffsets = gridPointsOffsets
	self.synergyPointsTable = synergyPointsTable
	self.itemType = itemType

	self.bindPoints = {}
	self.bindPointsOriginIDX = ""
	self.backpackBindPoints = {}
	self.backpackSynergyPoints = {}
	self.boundCells = {}
	self.bindPointsCellIDX = {}
	self.cleared = true

	return self
end
function GridPointEvaluator:ToString() return "[GridPointEvaluator]" end

function meta:Clear()
	self.bindPoints = {}
	self.bindPointsOriginIDX = ""
	self.backpackBindPoints = {}
	self.boundCells = {}
	self.bindPointsCellIDX = {}
	self.rotidx = nil
	self.cleared = true
end

function meta:EvaluateBindPoints(origin, rotation)
	if not self.gridPointsTable then Error("[PhysObj2D] Unbound gridpoints") end

	local ang = math.Ang(rotation)
	self.rotidx = ITEM_ANGLE_TO_ORIENTATION[math.Round(ang, 0) % 360]

	if not self.gridPointsTable[self.rotidx] then Error("[PhysObj2D] No gridpoints for angle: " .. self.rotidx) end

	-- Calculate our bindpoints.
	self.bindPoints = {}
	local pointsTab = self.gridPointsTable[self.rotidx]:GetPoints()
	local siz = gamemode.Call("GetInventoryGridSize")
	origin = origin + Vector2(siz * 0.5, siz * 0.5)

	for i = 1, #pointsTab do
		self.bindPoints[i] = origin + self.gridPointsOffsets[self.rotidx] + pointsTab[i] * siz
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

function meta:CalculateBackpackPointsOriginIDX()
	local gridPointsFirst = self.gridPointsTable[self.rotidx]:GetPoints()[1]
	self.bindPointsOriginIDX =
		gridPointsFirst:IsZero() and self.backpackBindPoints[1] or
		gamemode.Call("TranslateBindPointIndex", self.backpackBindPoints[1], -gridPointsFirst)
end

function meta:EvaluateBackpackSynergyPoints()
	self.backpackSynergyPoints = {}

	local data = self.synergyPointsTable[self.rotidx]
	if not data then return end

	for typ, pointsObj in pairs(data) do
		local pointsTab = pointsObj:GetPoints()
		local synergies = {}
		for i = 1, #pointsTab do
			synergies[gamemode.Call("TranslateBindPointIndex", self.bindPointsOriginIDX, pointsTab[i])] = true
		end

		self.backpackSynergyPoints[typ] = synergies
	end
end

function meta:EvaluateDrawnBackpackGrid(item)
	if not GAMEMODE.HeldItem then return end
	if GAMEMODE.HeldItem ~= item then return end

	local backpack = GAMEMODE.backpack
	local _, placeableList, notPlaceableList = backpack:IsValidPlaceableAt(item:GetBackpackInputVars())

	for i = 1, #placeableList do
		local cell = placeableList[i]
		cell.canPlaceDraw = true
	end
	for i = 1, #notPlaceableList do
		local cell = notPlaceableList[i]
		cell.cannotPlaceDraw = true
	end
end

-- TODO this really belongs in the inventory obj. probably.
--[[
function meta:BindItem(item)
	local isPlaceable, _, _ = GAMEMODE.backpack:GetHeldIsPlaceableOnBinds(item, self.backpackBindPoints)
	if not isPlaceable then return end

	-- Bind!
	self:RemoveFromInventoryCells()

	local indexes = self.backpackBindPoints
	local backpack = GAMEMODE.backpack
	for i = 1, #indexes do
		local cell = backpack.cellsScreenIDX[indexes[i]--]
		self.boundCells[indexes[i]--] = cell
		self.bindPointsCellIDX[i] = indexes[i]

		if self.itemType == ITEM_TYPE_CONTAINER then
			cell.heldContainer = item
		elseif self.itemType == ITEM_TYPE_NORMAL then
			cell.heldItem = item
		end
	end

	return true
end
]]

function meta:RemoveFromInventoryCells()
	if table.Count(self.boundCells) <= 0 then return end

	for idx, cell in pairs(self.boundCells) do
		if self.itemType == ITEM_TYPE_CONTAINER then
			cell.heldContainer = nil
		elseif self.itemType == ITEM_TYPE_NORMAL then
			cell.heldItem = nil
		end
	end

	table.Empty(self.boundCells)
	table.Empty(self.bindPointsCellIDX)
end