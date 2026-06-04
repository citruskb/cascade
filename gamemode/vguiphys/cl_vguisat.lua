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

local function GetOrCacheNormal(hb, points, i)
	local normal = GetCachedInfo(hb, "normal" .. i)

	if not normal then
		local vec1 = Rawget(points, i)
		local vec2 = Rawget(points, i == #points and 1 or i + 1)
		normal = Vector2(Rawget(vec1, "y") - Rawget(vec2, "y"), Rawget(vec2, "x") - Rawget(vec1, "x"))
		normal:Normalize()

		SetCachedInfo(hb, "normal" .. i, normal)
	end

	return normal
end


-- We know that for any given normal, an array of points will always project the same way.
-- We can leverage this for caching.
local function GetOrCacheProjRange(hb, points, normal)
	local projRangeData = GetCachedInfo(hb, "projRange")
	local projRange
	local nx, ny = normal:Unpack()

	if projRangeData and Rawget(projRangeData, nx) and Rawget(Rawget(projRangeData, nx), ny) then
		projRange = Rawget(Rawget(projRangeData, nx), ny)
	end

	if not projRange then
		local min, max
		for j = 1, #points do
			local point = Rawget(points, j)
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
	local collisions = GetCachedInfo(hbA, "collisions")
	if not collisions then return end

	return Rawget(collisions, hbB)
end

local function SetCachedCollision(hbA, hbB)
	if GetCachedCollision(hbA, hbB) then Error("[VGUIPHYS] - Doubled up collision event!") end
	SetCachedInfo(hbA, "collisions", {[hbB] = true})
	SetCachedInfo(hbB, "collisions", {[hbA] = true})
end

local function GetRangeOverlap(rangeA, rangeB)
	return math_Min(Rawget(rangeA, "max"), Rawget(rangeB, "max")) - math_Max(Rawget(rangeA, "min"), Rawget(rangeB, "min"))
end

local function OrientMTV(hbA, hbB, normalA)
	local centerA, centerB = hbA:GetAggregateCenter(), hbB:GetAggregateCenter()

	-- Find the direction pointing from the center of hbB towards the center of hbA.
	local centerDir = centerB - centerA

	-- If the dot product is negative, it means we need to flip our MTV. Otherwise, the normal is the MTV.
	return centerDir:Dot(normalA) < 0 and -normalA or normalA
end




function GM:VGUISAT(hbA, hbB)
	-- A hitbox can't collide with itself.
	if hbA == hbB then return end

	-- A hitbox part of the same object can't collide with itself either.
	if hbA:GetParent() == hbB:GetParent() then return end

	-- Check if we have checked say.. hbB vs hbA already?
	local collision = GetCachedCollision(hbA, hbB)
	if collision then return end

	local pointsA = hbA:GetTranslatedAggregateVectorData()
	local pointsB = hbB:GetTranslatedAggregateVectorData()

	local smallestOverlap, mtv, relativeTo

	-- Assuming there's at least one new line for each point that exists...
	-- TODO: this is a bad assumption for how we are aggregating our poly data above.
	-- Will deal with when it comes to it. Only affects items with 1 or more hitbox.
	for i = 1, #pointsA do

		-- We get our normal for the given points.
		local normalA = GetOrCacheNormal(hbA, pointsA, i)

		-- Next, we get the projection of hbA vs that normal.
		local projRangeA = GetOrCacheProjRange(hbA, pointsA, normalA)

		-- We do the same for hbB.
		local projRangeB = GetOrCacheProjRange(hbB, pointsB, normalA)

		-- Get our overlap!
		local overlap = GetRangeOverlap(projRangeA, projRangeB)

		-- Save information regarding our collision with the MTV if it's found.
		if smallestOverlap and overlap > smallestOverlap then continue end
		smallestOverlap = overlap
		mtv = normalA
		relativeTo = hbA

	end

	-- Now we need to repeat the same process, but for hbB!
	for i = 1, #pointsB do

		local normalB = GetOrCacheNormal(hbB, pointsB, i)
		local projRangeB = GetOrCacheProjRange(hbB, pointsB, normalB)
		local projRangeA = GetOrCacheProjRange(hbB, pointsA, normalB)
		local overlap = GetRangeOverlap(projRangeB, projRangeA)

		if smallestOverlap and overlap > smallestOverlap then continue end
		smallestOverlap = overlap
		mtv = normalB
		relativeTo = hbB

	end

	-- If we've made it this far, we know for sure a collision has happened!!
	-- But we need to make sure we are pointing our MTV the correct direction.
	-- And relative to the right object.

	-- If our mtv is relative to hbA instead of hbB then simply swap the two.
	if relativeTo == hbB then
		local ref_hbA, ref_hbB = hbA, hbB
		hbA, hbB = ref_hbB, ref_hbA
		ref_hbA, ref_hbB = nil, nil
	end

	-- Orient our MTV correctly.
	mtv = OrientMTV(hbA, hbB, mtv)

	-- Finally build and cache our collision information, and return it.
	collision = {hbA = hbA, hbB = hbB, vphysA = hbA:GetParent(), vphysB = hbB:GetParent(), overlap = smallestOverlap, mtv = mtv}
	SetCachedCollision(hbA, hbB, collision)

	return collision
end