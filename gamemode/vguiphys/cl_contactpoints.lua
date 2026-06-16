--Sutherland-Hodgeman line clipping algorithm

local meta = FindMetaTable("v2")
local V2_Normalize = meta.Normalize
local V2_Unpack = meta.Unpack
local V2_Dot = meta.Dot

local table_Insert = table.Insert

local function ClipSegmentToPlane(p1, p2, planeNormal, planeOffset)
	local points = {}

	local d1 = V2_Dot(planeNormal, p1 - planeOffset)
	local d2 = V2_Dot(planeNormal, p2 - planeOffset)

	if d1 <= 0 then table_Insert(points, p1) end
	if d2 <= 0 then table_Insert(points, p2) end

	if d1 * d2 < 0 then
		local t = d1 / (d1 - d2)
		local intersection = p1 + (p2 - p1) * t
		table_Insert(points, intersection)
	end

	return points
end

local function GetBestAlignment(pointsTab, alignTo)
	local bestP1, bestP2, bestIDX
	local bestAlignment
	for i = 1, #pointsTab do
		local p1 = Rawget(pointsTab, i)
		local p2 = Rawget(pointsTab,(i % #pointsTab) + 1)
		local checkAlign = Vector2(Rawget(p2, "y") - Rawget(p1, "y"), Rawget(p1, "x") - Rawget(p2, "x"))
		local alignment = checkAlign:Dot(alignTo)

		if bestAlignment and alignment >= bestAlignment then continue end
		bestAlignment = alignment
		bestP1 = p1
		bestP2 = p2
		bestIDX = i
	end

	return Points({bestP1, bestP2}), bestIDX
end


-- Returns either 1 or 2 points of contact.
function GM:VGUIGetContactPoints(bodyA, bodyB, hbA, hbB, normal)

	local pointsTabA = hbA:GetHBScreenPointsObj():GetPoints()
	local pointsTabB = hbB:GetHBScreenPointsObj():GetPoints()
	local referenceLine, refIDX = GetBestAlignment(pointsTabA, -normal)
	local incidentLine, incIDX = GetBestAlignment(pointsTabB, normal)

	local collisionPoints = {}
	collisionPoints.points = {}
	collisionPoints.fIDs = {}

	--Step 1: Get the reference line and incident line. This was done and passed to us in GM:VGUISAT().
	local refPoints, incPoints = Rawget(referenceLine, "_points"), Rawget(incidentLine, "_points")
	r1, r2 = Rawget(refPoints, 1), Rawget(refPoints, 2)
	i1, i2 = Rawget(incPoints, 1), Rawget(incPoints, 2)

	-- Step 2: We need the reference edge direction.
	local refDir = r2 - r1
	V2_Normalize(refDir)

	-- Step 3: Get info on plane 1
	local plane1Normal = -refDir
	local plane1Offset = r1

	-- Step 4: Clip the incident against plane 1
	local p1, p2 = Vector2(V2_Unpack(i1)), Vector2(V2_Unpack(i2))
	local clippedPoints = ClipSegmentToPlane(p1, p2, plane1Normal, plane1Offset)

	if #clippedPoints == 0 then return collisionPoints end

	-- Step 5: Get info on plane 2
	local plane2Normal = refDir
	local plane2Offset = r2

	-- Step 6: Clip the new points against plane 2
	clippedPoints = ClipSegmentToPlane(Rawget(clippedPoints, 1), Rawget(clippedPoints, 2), plane2Normal, plane2Offset)

	-- Same deal as above.
	if #clippedPoints == 0 then return collisionPoints end

	-- Step 7: Keep only the points behind the reference face, plus some slop.
	for i = 1, #clippedPoints do
		local point = clippedPoints[i]
		if V2_Dot(normal, point - r1) > VGUIPHYS_SLOP_COL_POINT then continue end
		table_Insert(collisionPoints.points, point)
		table_Insert(collisionPoints.fIDs, gamemode.Call("GetFeatureID", hbA, hbB, refIDX, incIDX, i))
	end

	return collisionPoints

end