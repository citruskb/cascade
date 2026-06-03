--[[
SAT - Separating Axis Theorem
"If one can find a line (axis) where shadows of two polygons don't overlap, then the polygons aren't colliding."

Is vphysA colliding with vphysB?
vphys = potentially a collection of polygons that represent a single colideable gameobject

Step 1: Check if projections of vphysA and vphysB overlap for every perpendicular normal of vphysA
We want to save how much each overlap is along with the normal, since the smallest overlap ..
represents the MTV, or minimum translation vector--the direction of smallest distance to separate the two objects.
The normal provides the directions we need to separate the two objects.

Step 2: If any projections don't overlap, abort early. No collision.

Step 3: If all projections overlap, potential collision.

Step 4: Repeat Step 1 but checking vphysA and vphysB vs every perpendicular normal of vphysB

Step 5: If any projections don't overlap, abort early. No collision.

Step 6: If all projections overlap, there is a collision!

Step 7: between all overlaps in step 1 and 4, return the overlap and normal.
Note we need to make sure the normal is pointing a consistent direction (say, A ----> B) for proper collisions handling.

I can probably make this go way faster by caching calculations and looking up calculations that have already been done..
when looping through all vphys elements checking for collisions.

WARNING. Need to make sure this area is highly optimized. It could pontentially be running many thousands of times per second!
]]--

local math_Max = math.Max
local math_Min = math.Min

local cache = {}
local function ResetCache() cache = {} end
hook.Add("VGUIPhysPass", "VGUIPhysPass.ResetVGUISATCache", ResetCache)

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

local function GetOrCacheNormal(vphys, points, i)
	local normal = GetCachedInfo(vphys, "normal" .. i)

	if not normal then
		local p1 = Rawget(points, i)
		local p2 = Rawget(points, i == #points and 1 or i + 1)
		local axisX, axisY = Rawget(p1, "y") - Rawget(p2, "y"), Rawget(p2, "x") - Rawget(p1, "x")

		local len = math.Sqrt(axisX ^ 2 + axisY ^ 2)
		normal = {x = axisX / len, y = axisY / len}
		SetCachedInfo(vphys, "normal" .. i, normal)
	end

	return normal
end


-- We know that for any given normal, an array of points will always project the same way.
-- We can leverage this for caching.
local function GetOrCacheProjRange(vphys, points, normal)
	local projRangeData = GetCachedInfo(vphys, "projRange")
	local projRange
	local nx, ny = Rawget(normal, "x"), Rawget(normal, "y")

	if projRangeData and Rawget(projRangeData, nx) and Rawget(Rawget(projRangeData, nx), ny) then
		projRange = Rawget(Rawget(projRangeData, nx), ny)
	end

	if not projRange then
		local min, max
		for j = 1, #points do
			local x, y = Rawget(Rawget(points, j), x), Rawget(Rawget(points, j), y)
			local proj = x * nx + y * ny

			if not min or (min and proj < min) then min = proj end
			if not max or (max and proj > max) then max = proj end
		end

		projRange = {min = min, max = max}
		local dataToCache = {}

		if Rawget(projRangeData, nx) then
			Rawset(Rawget(dataToCache, nx), ny, projRange)
		else
			Rawset(dataToCache, nx, {})
			Rawset(Rawget(dataToCache, nx), ny, projRange)
		end

		SetCachedInfo(vphys, "projRange", dataToCache)
	end

	return projRange
end

local function GetCachedCollision(vphysA, vphysB)
	return GetCachedInfo("collisions", ToString(vphsA) .. ToString(vphysB))
end

local function SetCachedCollision(vphysA, vphysB, data)
	if GetCachedCollision(vphysA, vphysB) then Error("[VGUIPHYS] - Doubled up collision event!") end

	local sa, sb = ToString(vphysA), ToString(vphysB)
	SetCachedInfo("collisions", sa .. sb, data)
	SetCachedInfo("collisions", sb .. sa, data)
end

local function GetRangeOverlap(rangeA, rangeB)
	return math_Min(Rawget(rangeA, "max"), Rawget(rangeB, "max")) - math_Max(Rawget(rangeA, "min"), Rawget(rangeB, "min"))
end

local function OrientMTV(vphysA, vphysB, normalA)
	local centerA, centerB = vphysA:GetAggregateCenter(), vphysB:GetAggregateCenter()

	-- Find the direction pointing from the center of vphysB towards the center of vphysA.
	local cax, cay = Rawget(centerA, "x"), Rawget(centerA, "y")
	local cbx, cby = RawGet(centerB, "x"), Rawget(centerB, "y")
	local centerDir = {x = cbx - cax, y = cby - cay}

	-- Find the dot product of the center dir with the normal calculated from vphysA.
	local nax, nay = Rawget(normalA, "x"), Rawget(normalA, "y")
	local cdx, cdy = Rawget(centerDir, "x"), Rawget(centerDir, "y")
	local dot = nax * cdx + nay * cdy

	-- If this dot product is negative, it means we need to flip our MTV. Otherwise, the normal is the MTV.
	return dot < 0 and {x = -nax, y = -nay} or normalA
end




function GM:VGUISAT(vphysA, vphysB)
	-- Check if we have checked say.. vphysB vs vphysA already?
	local collision = GetCachedCollision(vphysA, vphysB)
	if collision then return end

	local pointsA = vphysA:GetTranslatedAggregatePolyData()
	local pointsB = vphysB:GetTranslatedAggregatePolyData()

	local smallestOverlap, mtv, relativeTo

	-- Assuming there's at least one new line for each point that exists...
	-- TODO: this is a bad assumption for how we are aggregating our poly data above.
	-- Will deal with when it comes to it. Only affects items with 1 or more hitbox.
	for i = 1, #pointsA do

		-- We get our normal for the given points.
		local normalA = GetOrCacheNormal(vphysA, pointsA, i)

		-- Next, we get the projection of vphysA vs that normal.
		local projRangeA = GetOrCacheProjRange(vphysA, pointsA, normalA)

		-- We do the same for vphysB.
		local projRangeB = GetOrCacheProjRange(vphysB, pointsB, normalA)

		-- Get our overlap!
		local overlap = GetRangeOverlap(projRangeA, projRangeB)

		-- If overlap is too small.. hard stop. No collision.
		if overlap <= VGUIPHYS_SLOP then return end

		-- Save information regarding our collision with the MTV if it's found.
		if smallestOverlap and overlap > smallestOverlap then continue end
		smallestOverlap = overlap
		mtv = normalA
		relativeTo = vphysA

	end

	-- Now we need to repeat the same process, but for vphysB!
	for i = 1, #pointsB do

		local normalB = GetOrCacheNormal(vphysB, pointsB, i)
		local projRangeB = GetOrCacheProjRange(vphysB, pointsB, normalB)
		local projRangeA = GetOrCacheProjRange(vphysA, pointsA, normalB)
		local overlap = GetRangeOverlap(projRangeB, projRangeA)

		if overlap <= VGUIPHYS_SLOP then return end

		if smallestOverlap and overlap > smallestOverlap then continue end
		smallestOverlap = overlap
		mtv = normalB
		relativeTo = vphysB

	end

	-- If we've made it this far, we know for sure a collision has happened!!
	-- But we need to make sure we are pointing our MTV the correct direction.
	-- And relative to the right object.

	-- If our mtv is relative to vphysB instead of vphysA then simply swap the two.
	if relativeTo == vphysB then
		local copy_vphysA, copy_vphysB = vphysA, vphysB
		vphysA, vphysB = copy_vphysB, copy_vphysA
		copy_vphysA, copy_vphysB = nil, nil
	end

	-- Orient our MTV correctly.
	mtv = OrientMTV(vphysA, vphysB, mtv)

	-- Finally build and cache our collision information, and return it.
	collision = {vphysA = vphysA, vphysB = vphysB, overlap = overlap, mtv = mtv}
	SetCachedCollision(vphysA, vphysB, collision)

	return collision
end