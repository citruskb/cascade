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
		local pctAcross = dist1 / (dist1 - dist2)
		local intersectionPt = point1 + (point2 - point1) * pctAcross
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

	-- incident edge selection: edge with normal pointing most opposite to n
	local lowestDot = math.HUGE
	local incIdx = 1
	for i = 1, #incNormals do
		local d = n:Dot(incNormals[i])
		if d > lowestDot then continue end

		lowestDot = d
		incIdx = i
	end

	local b1 = incVerts[incIdx]
	local b2 = incVerts[incIdx % #incVerts + 1]

	--table.Insert(refLines, Points({a1, a2}))
	--table.Insert(incLines, Points({b1, b2}))

	-- Clip to start and end faces. Tangents on ends of reference edge
	local refTangent = (a2 - a1):GetNormalized()

	--local data = {normal = refTangent, referenceLine = Points({a1, a2})}
	--table.insert(normals, data)

	local clippedPoints = ClipLineSegmentToLine(b1, b2, -refTangent, a1)
	if #clippedPoints == 0 then return {points = {}, fIDs = {}} end
	clippedPoints = ClipLineSegmentToLine(clippedPoints[1], clippedPoints[2], refTangent, a2)

	-- Keep points that are behind the reference face, plus speculative slop
	local finalPoints = {points = {}, fIDs = {}}
	for i = 1, #clippedPoints do
		local point = clippedPoints[i]
		if n:Dot(point - a1) > VGUIPHYS_SLOP_COL then continue end
		table.Insert(finalPoints.points, point)
		table.Insert(finalPoints.fIDs, gamemode.Call("GetFeatureID", refHitbox, incHitbox, refIdx, incIdx, i))
	end

	return finalPoints
end