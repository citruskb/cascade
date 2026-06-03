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
		local p1 = Rawget(pointsA, i)
		local p2 = Rawget(points, i == #points and 1 or i + 1)
		local axisX, axisY = Rawget(p1, "y") - Rawget(p2, "y"), Rawget(p2, "x") - Rawget(p1, "x")

		local len = math.Sqrt(axisX ^ 2 + axisY ^ 2)
		normal = {x = axisX / len, y = axisY / len}
		SetCachedInfo(vphys, "normal" .. i, normal)
	end

	return normal
end

function GM:VGUISAT(vphysA, vphysB)
	local pointsA = vphysA:GetTranslatedAggregatePolyData()
	for i = 1, #pointsA do
		local normalA = GetOrCacheNormal(vphys, pointsA, i)
		local projA = GetOrCacheProj(vphys)
	end

	-- TODO
end