--[[
SAT - Separating Axis Theorem
"If one can find a line (axis) where shadows of two polygons don't overlap, then the polygons aren't colliding."

Is hbA colliding with hbB?
vphys = potentially a collection of hb's that represent a single colideable gameobject

Step 1: Check if projections of hbA and hbB overlap for every perpendicular normal of hbA
We want to save how much each overlap is along with the normal, since the smallest overlap ..
represents the MTV, or minimum translation vector--the direction of smallest distance to separate the two objects.
The normal provides the directions we need to separate the two objects.

Step 2: If any projections don't overlap, abort early. No collision.

Step 3: If all projections overlap, potential collision.

Step 4: Repeat Step 1 but checking hbA and hbB vs every perpendicular normal of hbB

Step 5: If any projections don't overlap, abort early. No collision.

Step 6: If all projections overlap, there is a collision!

Step 7: between all overlaps in step 1 and 4, return the overlap and normal.
Note we need to make sure the normal is pointing a consistent direction (say, A ----> B) for proper collisions handling.

We can probably make this go way faster by caching calculations and looking up calculations that have already been done..
when looping through all vphys elements checking for collisions.

WARNING. Need to make sure this area is highly optimized. It could pontentially be running many thousands of times per second!
]]--

local gamemode_Call = gamemode.Call

local math_Max = math.Max
local math_Min = math.Min

local cache = {}
local function ResetCache() cache = {} end
hook.Add("VGUIPhysPassComplete", "VGUIPhysPassComplete.ResetVGUISATCache", ResetCache)

local function GetCachedInfo(obj, id)
	local data = Rawget(cache, obj)
	if not data then return end

	return Rawget(data, id)
end

local function SetCachedInfo(obj, id, val)
	local data = Rawget(cache, obj)
	if not data then
		data = {}
		Rawset(cache, obj, data)
	end

	Rawset(data, id, val)
end

local function GetOrCacheNormal(hb, pointstab, i)
	local normal = GetCachedInfo(hb, "normal" .. i)

	if not normal then
		local vec1 = Rawget(pointstab, i)
		local vec2 = Rawget(pointstab, i == #pointstab and 1 or i + 1)
		normal = Vector2(Rawget(vec2, "y") - Rawget(vec1, "y"), Rawget(vec1, "x") - Rawget(vec2, "x"))
		normal:Normalize()

		SetCachedInfo(hb, "normal" .. i, normal)
	end

	return normal
end


-- We know that for any given normal, an array of points will always project the same way.
-- We can leverage this for caching.
local function GetOrCacheProjRange(hb, pointstab, normal)
	local projRangeData = GetCachedInfo(hb, "projRange")
	local projRange
	local nx, ny = normal:Unpack()

	if projRangeData and Rawget(projRangeData, nx) and Rawget(Rawget(projRangeData, nx), ny) then
		projRange = Rawget(Rawget(projRangeData, nx), ny)
	end

	if not projRange then
		local min, max
		for j = 1, #pointstab do
			local point = Rawget(pointstab, j)
			local x, y = point:Unpack()
			local proj = x * nx + y * ny

			if not min or (min and proj < min) then min = proj end
			if not max or (max and proj > max) then max = proj end
		end

		projRange = {min = min, max = max}

		if projRangeData and Rawget(projRangeData, nx) then
			Rawset(Rawget(projRangeData, nx), ny, projRange)
		else
			local dataToCache = {}
			Rawset(dataToCache, nx, {})
			Rawset(Rawget(dataToCache, nx), ny, projRange)
			SetCachedInfo(hb, "projRange", dataToCache)
		end
	end

	return projRange
end

local function GetCachedCollision(hbA, hbB)
	local hbACache = Rawget(cache, hbA)
	if not hbACache then return end

	local collisionsA = Rawget(hbACache, "collisions")
	if not collisionsA then return end

	return Rawget(collisionsA, hbB)
end

local function SetCachedCollision(hbA, hbB)
	if GetCachedCollision(hbA, hbB) then Error("[VGUIPHYS] - Doubled up collision event!") end

	local hbACache = Rawget(cache, hbA)
	if not hbACache then
		hbACache = {}
		Rawset(cache, hbA, hbACache)
	end

	local collisionsA = Rawget(hbACache, "collisions")
	if not collisionsA then
		collisionsA = {}
		Rawset(hbACache, "collisions", collisionsA)
	end

	local hbBCache = Rawget(cache, hbB)
	if not hbBCache then
		hbBCache = {}
		Rawset(cache, hbB, hbBCache)
	end

	local collisionsB = Rawget(hbBCache, "collisions")
	if not collisionsB then
		collisionsB = {}
		Rawset(hbBCache, "collisions", collisionsB)
	end

	Rawset(collisionsA, hbB, true)
	Rawset(collisionsB, hbA, true)
end

local function GetRangeOverlap(rangeA, rangeB)
	return math_Min(Rawget(rangeA, "max"), Rawget(rangeB, "max")) - math_Max(Rawget(rangeA, "min"), Rawget(rangeB, "min"))
end

local function OrientMTV(pointsA, pointsB, mtv)
	local centerA, centerB = pointsA:GetCenter(), pointsB:GetCenter()

	-- Find the direction pointing from the center of hbB towards the center of hbA.
	local centerDir = centerB - centerA

	-- If the dot product is negative, it means we need to flip our MTV. Otherwise, do nothing.
	return centerDir:Dot(mtv) < 0 and -mtv or mtv
end



local function GetBestAlignment(hb, pointsTab, alignTo)
	local bestP1, bestP2
	local bestAlignment
	for i = 1, #pointsTab do
		local p1 = pointsTab[i]
		local p2 = pointsTab[(i % #pointsTab) + 1]
		local normal = GetOrCacheNormal(hb, pointsTab, i)
		local alignment = normal:Dot(alignTo)

		if bestAlignment and alignment >= bestAlignment then continue end
		bestAlignment = alignment
		bestP1 = p1
		bestP2 = p2
	end
	return Points({bestP1, bestP2})
end

function GM:VGUISAT(hbA, hbB)
	-- A hitbox can't collide with itself.
	if hbA == hbB then return end

	-- A hitbox part of the same object can't collide with itself either.
	-- This shouldn't ever happen unless laziness with making hitboxes. 
	local physboxA, physboxB = Rawget(hbA, "_physbox"), Rawget(hbB, "_physbox")
	if physboxA == physboxB then return end

	-- Check if we have checked say.. hbB vs hbA already?
	if GetCachedCollision(hbA, hbB) then return end

	local pointsA, pointsB = hbA:GetPhysicsPassScreenPoints(), hbB:GetPhysicsPassScreenPoints()
	local pointsTabA, pointsTabB = pointsA:GetPoints(), pointsB:GetPoints()

	local smallestOverlap, mtv, relativeTo

	-- Assuming there's at least one new line for each point that exists...
	for i = 1, #pointsTabA do

		-- We get our normal for the given points.
		local normalA = GetOrCacheNormal(hbA, pointsTabA, i)

		-- Next, we get the projection of hbA vs that normal.
		local projRangeA = GetOrCacheProjRange(hbA, pointsTabA, normalA)

		-- We do the same for hbB.
		local projRangeB = GetOrCacheProjRange(hbB, pointsTabB, normalA)

		-- Get our overlap!
		local overlap = GetRangeOverlap(projRangeA, projRangeB)

		--[[
		if GAMEMODE.Debug and GAMEMODE.VGUIPhysPassCount == VGUIPHYS_PASSES - 1 then
			local tab = {p1 = pointsTabA[i], p2 = pointsTabA[(i % #pointsTabA) + 1], normal = normalA}
			table.Insert(mtvsA, tab)
		end
		]]

		-- No collision.
		if overlap <= 0 then
			SetCachedCollision(hbA, hbB)
			return
		end

		-- Save information regarding our collision with the MTV if it's found.
		if smallestOverlap and overlap >= smallestOverlap - VGUI_EPSILON_OVERLAP then continue end

		smallestOverlap = overlap
		mtv = Vector2(normalA:Unpack()) -- A new Vector2 because we cache the normal above, but also manipulate this later on.
		relativeTo = hbA

	end

	-- Now we need to repeat the same process, but for hbB!
	for i = 1, #pointsTabB do

		local normalB = GetOrCacheNormal(hbB, pointsTabB, i)
		local projRangeB = GetOrCacheProjRange(hbB, pointsTabB, normalB)
		local projRangeA = GetOrCacheProjRange(hbA, pointsTabA, normalB)
		local overlap = GetRangeOverlap(projRangeB, projRangeA)

		--[[
		if GAMEMODE.Debug and GAMEMODE.VGUIPhysPassCount == VGUIPHYS_PASSES - 1 then
			local tab = {p1 = pointsTabB[i], p2 = pointsTabB[(i % #pointsTabB) + 1], normal = normalB}
			table.Insert(mtvsB, tab)
		end
		]]

		if overlap <= 0 then
			SetCachedCollision(hbA, hbB)
			return
		end

		if smallestOverlap and overlap >= smallestOverlap - VGUI_EPSILON_OVERLAP then continue end

		smallestOverlap = overlap
		mtv = Vector2(normalB:Unpack())
		relativeTo = hbB

	end

	-- If we've made it this far, we know for sure a collision has happened!!
	-- But we need to make sure we are pointing our MTV the correct direction.
	-- And relative to the right object.

	-- If our mtv is relative to hbB instead of hbA then simply swap the two.
	if relativeTo == hbB then
		local ref_pointsA, ref_pointsB = pointsA, pointsB
		pointsA, pointsB = ref_pointsB, ref_pointsA
		ref_pointsA, ref_pointsB = nil, nil

		local ref_physboxA, ref_physboxB = physboxA, physboxB
		physboxA, physboxB = ref_physboxB, ref_physboxA
		ref_physboxA, ref_physboxB = nil, nil

		local ref_pointsTabA, ref_pointsTabB = pointsTabA, pointsTabB
		pointsTabA, pointsTabB = ref_pointsTabB, ref_pointsTabA
		ref_pointsTabA, ref_pointsTabB = nil, nil

		local ref_hbA, ref_hbB = hbA, hbB
		hbA, hbB = ref_hbB, ref_hbA
		ref_hbA, ref_hbB = nil, nil
	end

	-- Orient our MTV correctly so that it points from A -----> B
	mtv = OrientMTV(pointsA, pointsB, mtv)

	-- A little messy. But we do this here since we have our normals cached in this file.
	local referenceLine = GetBestAlignment(hbA, pointsTabA, -mtv)
	local incidentLine = GetBestAlignment(hbB, pointsTabB, mtv)
	local contactPoints = gamemode_Call("VGUIGetContactPoints", referenceLine, incidentLine, mtv)

	-- Finally cache that we checked our collision and return our collision information.
	SetCachedCollision(hbA, hbB)

	return {hbA = hbA, hbB = hbB, physboxA = physboxA, physboxB = physboxB, overlap = smallestOverlap, mtv = mtv, contactPoints = contactPoints}
end