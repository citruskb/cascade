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

local function GetNormal(pointstab, i)
	local vec1 = Rawget(pointstab, i)
	local vec2 = Rawget(pointstab, i == #pointstab and 1 or i + 1)
	return vec1:GetConnectingNormal(vec2)
end

-- We know that for any given normal, an array of points will always project the same way.
-- We can leverage this for caching.
local function GetProjRange(pointstab, normal)
	local nx, ny = normal:Unpack()

	local min, max
	for j = 1, #pointstab do
		local point = Rawget(pointstab, j)
		local x, y = point:Unpack()
		local proj = x * nx + y * ny

		if not min or (min and proj < min) then min = proj end
		if not max or (max and proj > max) then max = proj end
	end

	return {min = min, max = max}
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

function GM:VGUISAT(hbA, hbB)
	local pointsA, pointsB = hbA:GetHBScreenPointsObj(), hbB:GetHBScreenPointsObj()
	local pointsTabA, pointsTabB = pointsA:GetPoints(), pointsB:GetPoints()

	local smallestOverlap, mtv, relativeTo

	-- Assuming there's at least one new line for each point that exists...
	for i = 1, #pointsTabA do

		-- We get our normal for the given points.
		local normalA = GetNormal(pointsTabA, i)

		-- Next, we get the projection of hbA vs that normal.
		local projRangeA = GetProjRange(pointsTabA, normalA)

		-- We do the same for hbB.
		local projRangeB = GetProjRange(pointsTabB, normalA)

		-- Get our overlap!
		local overlap = GetRangeOverlap(projRangeA, projRangeB)

		-- No collision.
		if overlap <= 0 then return end

		-- Save information regarding our collision with the MTV if it's found.
		if smallestOverlap and overlap >= smallestOverlap - VGUI_EPSILON_OVERLAP then continue end

		smallestOverlap = overlap
		mtv = Vector2(normalA:Unpack()) -- A new Vector2 because we cache the normal above, but also manipulate this later on.
		relativeTo = hbA

	end

	-- Now we need to repeat the same process, but for hbB!
	for i = 1, #pointsTabB do

		local normalB = GetNormal(pointsTabB, i)
		local projRangeB = GetProjRange(pointsTabB, normalB)
		local projRangeA = GetProjRange(pointsTabA, normalB)
		local overlap = GetRangeOverlap(projRangeB, projRangeA)

		if overlap <= 0 then return end
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
	end

	-- Orient our MTV correctly so that it points from A -----> B
	mtv = OrientMTV(pointsA, pointsB, mtv)

	return {penetration = smallestOverlap, normal = mtv}
end