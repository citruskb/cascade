--Sutherland-Hodgeman line clipping algorithm

local function ClipLineSegmentToLine(point1, point2, normal, offset)
	local clippedPoints = {}
	local dist1 = (point1 - offset):Dot(normal)
	local dist2 = (point2 - offset):Dot(normal)

	-- If the points are behind the plane, don't clip
	if dist1 <= 0 then table.Insert(clippedPoints, point1) end
	if dist2 <= 0 then table.Insert(clippedPoints, point2) end

	-- If one is in front of the plane, we have to clip it to the intersection point
	-- #clippedPoints < 2 for edge case where 1 point is exactly on the plane
	if math.Sign(dist1) ~= math.Sign(dist2) and #clippedPoints < 2 then
		local pctAcross = dist2 / (dist2 - dist1)
		local intersectionPt = point2 + (point1 - point2) * pctAcross
		table.Insert(clippedPoints, intersectionPt)
	end

	return clippedPoints
end

local function GetNormals(verts)
	local tab = {}
	for k, point in ipairs(verts) do
		local p1 = point
		local p2 = verts[k % #verts + 1]
		tab[k] = (p1 - p2):GetRotate90CW():GetNormalized()

	end
	return tab
end

function GM:ClipPolyToPoly(refBody, refHitbox, incObj, incHitbox, collision)
	local refVerts = refHitbox:GetHBScreenPointsObj():GetPoints()
	local incVerts = incHitbox:GetHBScreenPointsObj():GetPoints()
	local refNormals = GetNormals(refVerts)
	local incNormals = GetNormals(incVerts)
	local n = collision.normal


	-- ref edge selection: edge with normal points most towards n
	local largestDot = -math.HUGE
	local refIdx = 1
	for i = 1, #refNormals do
		local d = n:Dot(refNormals[i])
		if d < largestDot then continue end

		largestDot = d
		refIdx = i
	end

	local a1 = refVerts[refIdx]
	local a2 = refVerts[refIdx % #refVerts + 1]

	local data = {normal = n, referenceLine = Points({a1, a2})}
	table.insert(normals, data)

	-- incident edge selection: edge with normal pointing most opposite to n
	local lowestDot = math.HUGE
	local incIdx = 1
	for i = 1, #incNormals do
		local d = n:Dot(incNormals[i])
		if d > lowestDot then continue end

		lowestDot = d
		incIdx = i
	end

	local b2 = incVerts[incIdx]
	local b1 = incVerts[incIdx % #incVerts + 1]

	table.Insert(refLines, Points({a1, a2}))
	table.Insert(incLines, Points({b1, b2}))

	-- Clip to start and end faces. Tangents on ends of reference edge
	local refTangent = (a2 - a1):GetNormalized()
	local clippedPoints = ClipLineSegmentToLine(b1, b2, -refTangent, a1)
	if #clippedPoints == 0 then return {points = {}, fIDs = {}} end
	clippedPoints = ClipLineSegmentToLine(clippedPoints[1], clippedPoints[2], refTangent, a2)

	-- Keep points that are behind the reference face, plus speculative slop
	local finalPoints = {points = {}, fIDs = {}}
	for i = 1, #clippedPoints do
		local point = clippedPoints[i]
		if n:Dot(point - a1) > VGUIPHYS_SLOP_LINEAR then continue end
		table.Insert(finalPoints.points, point)
		table.Insert(finalPoints.fIDs, gamemode.Call("GetFeatureID", refHitbox, incHitbox, refIdx, incIdx, i))
	end

	return finalPoints
end




--[[
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

	table.Insert(refLines, referenceLine)
	table.Insert(incLines, incidentLine)

	local data = {bodyA = bodyA, normal = normal, referenceLine = referenceLine}
	table.insert(normals, data)

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
]]