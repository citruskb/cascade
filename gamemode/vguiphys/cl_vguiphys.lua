-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.PhysicsItems = {}
	GM.VGUIColEvents = {}
	vguiPhysLoaded = true
end

ITEM_GRAVITY = 0.008
ITEM_TERMINAL_VELOCITY = 1.4

local function GetProjectedRange(points, normal)
	local min, max
	for j = 1, #points do
		local x, y = points[j].x, points[j].y
		local nx, ny = normal.x, normal.y
		local proj = x * nx + y * ny

		if not min or (min and proj < min) then min = proj end
		if not max or (max and proj > max) then max = proj end
	end

	return min, max
end

local function GetRangeOverlap(minA, maxA, minB, maxB)
	return math.Min(maxA, maxB) - math.Max(minA, minB)
end

local normals = {}
local collisions = {}
local colHandled = {}
local noCol = {}
local allPolyData = {}

function GM:ItemPhysicsThink()
	normals = {}
	collisions = {}
	colHandled = {}
	noCol = {}
	allPolyData = {}

	for i = 1, #self.PhysicsItems do

		-- Gravity
		local item = self.PhysicsItems[i]
		local _, vy = item:GetVel()
		if vy < ITEM_TERMINAL_VELOCITY then
			item:AddVel(0, ITEM_GRAVITY)
		end

		-- SAT collisions

		-- Step through the points of each phys item
		-- Get the normal to each side
		local nv = {}

		local points = allPolyData[i]
		if not points then
			allPolyData[i] = item:GetPhysbox():AggregatePolyData()
			points = allPolyData[i]
		end

		for j = 1, #points do
			local p1 = points[j]
			local p2 = points[j == #points and 1 or j + 1]
			nv[j] = {x = p1.y - p2.y, y = p2.x - p1.x}
		end

		normals[i] = nv
	end

	-- Now that we have all the normals, we need the projection of each edge vs that normal.
	for i = 1, #normals do
		local nv = normals[i]
		for j = 1, #nv do
			local normal = nv[j]

			-- First get the range for the shape we are focusing on...
			local minA, maxA = GetProjectedRange(allPolyData[i], normal)

			-- Now we need the range for the shape we are considering..
			-- For every shape..

			for o = 1, #self.PhysicsItems do
				if i == o then continue end -- Skip our current item.

				-- Aready checked and determined no collision!
				if noCol[i] and noCol[i][o] then continue end
				if noCol[o] and noCol[o][i] then continue end

				local minB, maxB = GetProjectedRange(allPolyData[o], normal)
				local overlap = GetRangeOverlap(minA, maxA, minB, maxB)

				-- No collision!!
				if overlap < 0  then
					noCol[i] = noCol[i] or {}
					noCol[i][o] = true
					if collisions[i] and collisions[i][o] then collisions[i][o] = nil end

					noCol[o] = noCol[o] or {}
					noCol[o][i] = true
					if collisions[o] and collisions[o][i] then collisions[o][i] = nil end

					continue
				end

				-- Select existing collision data, if it exists.
				local colData = collisions[i] and collisions[i][o]
				if not colData then
					colData = collisions[o] and collisions[o][i]
				end

				-- We do this so we know whether to save to tab[o][i] vs tab[i][o]
				local alt
				if colData then alt = true end

				-- Parse new data.
				local newData = {overlap = overlap, normal = normal}

				if not colData then
					-- No collision data exists! Write it.
					colData[i] = colData[i] or {}
					colData[i][o] = newData
				elseif colData and colData.overlap > overlap then
					-- Collision data exists. Override it if our overlap is smaller.
					if alt then
						colData[o][i] = {overlap = overlap, normal = normal}
					else
						colData[i][o] = {overlap = overlap, normal = normal}
					end
				end
			end
		end
	end

	-- We have all our collision data now. Apply it.
	--[[
	for i = 1, collisions do
		local objA = self.PhysicsItems[i]
		for j = 1, collisions[i] do
			local objB = self.PhysicsItems[j]
			local data = collisions[i][j]
			local overlap, normal = data.overlap, data.normal

			-- TODO

		end
	end
	]]

	--[[
	for i = 1, #GM.PhysicsItems do
		local min1, max1 = GetProjectedRange(polydata[i], normals[i])

		for j = 1, #GM.PhysicsItems do
			if i == j then continue end

			local min2, max2 = GetProjectedRange(polydata[j], normals[i])
			local overlapping = max1 > min2 and max2 > min1
			if not overlapping then
				-- No collision!
				continue
			else
				-- Maybe collision.
			end
		end
	end
	]]
end