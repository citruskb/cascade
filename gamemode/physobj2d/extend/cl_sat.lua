local math_Max = math.Max
local math_Min = math.Min

--	SAT - Separating Axis Theorem

local function GetNormal(pointstab, i)
	local vec1 = Rawget(pointstab, i)
	local vec2 = Rawget(pointstab, i == #pointstab and 1 or i + 1)
	local normal = vec1:GetConnectingNormal(vec2)

	return normal
end

local function ProjectVerts(verts, axis)
	local min, max = math.HUGE, -math.HUGE

	for k, point in pairs(verts) do
		local p = point:Dot(axis)
		min = math.Min(min, p)
		max = math.Max(max, p)
	end

	return {min = min, max = max}
end

local function GetRangeOverlap(rangeA, rangeB)
	return math_Min(Rawget(rangeA, "max"), Rawget(rangeB, "max")) - math_Max(Rawget(rangeA, "min"), Rawget(rangeB, "min"))
end

local function OrientFinalNormal(hbA, hbB, normal)
	local centerA, centerB = hbA.physbox:GetCenterScreenPoint(), hbB.physbox:GetCenterScreenPoint()
	local centerDir = centerB - centerA

	-- If the dot product is negative, it means we need to flip our MTV. Otherwise, do nothing.
	return centerDir:Dot(normal) <= 0 and -normal or normal
end

function GM:VGUIPhysSAT(hbA, hbB)
	local pointsTabA, pointsTabB = hbA:GetHBScreenPointsObj():GetPoints(), hbB:GetHBScreenPointsObj():GetPoints()
	local smallestOverlap, finalNormal, relativeTo

	for i = 1, #pointsTabA do
		local normalA = GetNormal(pointsTabA, i)
		local projRangeA = ProjectVerts(pointsTabA, normalA)
		local projRangeB = ProjectVerts(pointsTabB, normalA)
		local overlap = GetRangeOverlap(projRangeA, projRangeB)

		if overlap <= 0 then return end -- No collision.
		if smallestOverlap and overlap >= smallestOverlap - PHYS2D_EPSILON_OVERLAP then continue end

		smallestOverlap = overlap
		finalNormal = Vector2(normalA:Unpack()) -- A new Vector2 because we cache the normal above, but also manipulate this later on.
		relativeTo = hbA
	end

	for i = 1, #pointsTabB do

		local normalB = GetNormal(pointsTabB, i)
		local projRangeB = ProjectVerts(pointsTabB, normalB)
		local projRangeA = ProjectVerts(pointsTabA, normalB)
		local overlap = GetRangeOverlap(projRangeB, projRangeA)

		if overlap <= 0 then return end
		if smallestOverlap and overlap >= smallestOverlap - PHYS2D_EPSILON_OVERLAP then continue end

		smallestOverlap = overlap
		finalNormal = Vector2(normalB:Unpack())
		relativeTo = hbB
	end

	-- Orient our MTV correctly so that it points from A -----> B
	finalNormal = OrientFinalNormal(
		relativeTo == hbB and hbB or hbA,
		relativeTo == hbB and hbA or hbB,
		finalNormal
	)

	return {
		hbA = relativeTo == hbB and hbB or hbA,
		hbB = relativeTo == hbB and hbA or hbB,
		penetration = smallestOverlap,
		normal = finalNormal
	}
end