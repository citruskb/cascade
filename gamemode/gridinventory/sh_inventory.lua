if not inventoryLoaded then
	GM.screenBindPoints = {}
	GM.screenBindPointsByID = {}
	inventoryLoaded = true
end

-- WARNING. This WILL badly break things if you mess with it. Be prepared.
GM_SCREENGRIDX = 22
GM_SCREENGRIDY = 12

-- 9 x 7 = 63
GM.BackpackGridX = 9
GM.BackpackGridY = 7


function GM:GridInventoryCoordsToCellID(x, y)
	return
		((y - 1) * self.BackpackGridX) +
		(x - 1) % self.BackpackGridX +
		1
end

function GM:GridInventoryCellIDToCoords(id)
	id = ToNumber(id)

	local x, y
	x = ((id - 1) % self.BackpackGridX) + 1
	y = ((id - x) / self.BackpackGridX) + 1

	return x, y
end

function GM:GetInventoryGridSize()
	local gridCountWide, gridCountHigh = GM_SCREENGRIDX, GM_SCREENGRIDY
	local w, h = ScrW(), ScrH()
	local colWide = math.Floor(w / gridCountWide)
	local rowHigh = math.Floor(h / gridCountHigh)

	return colWide, colWide
end

--[[
local function GetGridIDX(x, y) return ToString(x) .. "x" .. ToString(y) end
local function HashPairID(objA, objB) return ToString(math.Min(objA.id, objB.id)) .. ":" .. ToString(math.Max(objA.id, objB.id)) end
function PhysObj2D:HashGridCollisions()
	local newGrid = {}

	local objects = {}
	for physbox, _ in pairs(self.physboxes) do
		if physbox.isPickedUp then continue end
		table.Insert(objects, physbox)
	end

	-- Get all our objects hashed into grids.
	local gridSize = PHYS2D_HASHGRID_SIZE
	for i = 1, #objects do
		local obj = objects[i]
		local aabb = obj:GetAABB()
		local minCellX = math.floor(aabb.min.x / gridSize)
		local minCellY = math.floor(aabb.min.y / gridSize)
		local maxCellX = math.floor(aabb.max.x / gridSize)
		local maxCellY = math.floor(aabb.max.y / gridSize)

		for x = minCellX, maxCellX do
			for y = minCellY, maxCellY do
				local idx = GetGridIDX(x, y)
				if not newGrid[idx] then newGrid[idx] = {} end
				table.Insert(newGrid[idx], obj)
			end
		end
	end

	-- Now go over all our grids and evaluate potential candidates
	local potentialSATCandidates = {}
	for idx, gridElements in pairs(newGrid) do
		if #gridElements == 1 then continue end
		for i = 1, #gridElements do
			for j = i + 1, #gridElements do
				potentialSATCandidates[HashPairID(gridElements[i], gridElements[j])] = {bodyA = gridElements[i], bodyB = gridElements[j]}
			end
		end
	end

	PhysObj2D.collisionCandidates = potentialSATCandidates
end
]]

if SERVER then return end

local function GetGridID(x, y) return ToString(x) .. "x" .. ToString(y) end
local function GetGridCoords(id)
	local tab = string.Explode("x", id)
	return ToNumber(tab[1]), ToNumber(tab[2])
end
local function InitScreenWideGrid()
	GAMEMODE.screenBindPoints = {}
	GAMEMODE.screenBindPointsByID = {}

	local siz = GAMEMODE:GetInventoryGridSize()
	local screenW, screenH = ScrW(), ScrH()

	local id = 1
	local x, y = siz * 0.5, siz * 0.5
	local countX, countY = 1, 1

	while y < screenH do
		x = siz * 0.5
		countX = 1

		while x < screenW do
			GAMEMODE.screenBindPoints[id] = Vector2(x, y)
			GAMEMODE.screenBindPointsByID[GetGridID(countX, countY)] = Vector2(x, y)

			id = id + 1
			x = x + siz
			countX = countX + 1
		end

		y = y + siz
		countY = countY + 1
	end
end

hook.Add("InitPostEntity", "InitPostEntity.ScreenWideGrid", InitScreenWideGrid)
hook.Add("ScreenScaleChanged", "ScreenScaleChanged.ScreenWideGrid", InitScreenWideGrid)

function GM:GetNearestScreenBindPointXY(vec2)
	local x, y = vec2:Unpack()
	local siz = self:GetInventoryGridSize()
	return math.Round((x + siz / 2) / siz, 0), math.Round((y + siz / 2) / siz, 0)
end

function GM:GetNearestScreenBindPoint(vec2)
	local gridX, gridY = self:GetNearestScreenBindPointXY(vec2)
	local id = GetGridID(gridX, gridY)
	return self.screenBindPointsByID[id]
end

function GM:GetNearestScreenBindPointIndex(vec2)
	return GetGridID(self:GetNearestScreenBindPointXY(vec2))
end

function GM:TranslateBindPointIndex(id, vec2)
	local x1, y1 = GetGridCoords(id)
	local x2, y2 = vec2:Unpack()
	return GetGridID(x1 + x2, y1 + y2)
end

function GM:BindPointIDXToVector2(bindPointIDX)
	local x, y = GetGridCoords(bindPointIDX)
	local siz = self:GetInventoryGridSize()
	return Vector2(x * siz + siz * 0.5, y * siz + siz * 0.5)
end
