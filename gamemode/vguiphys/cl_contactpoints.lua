--Sutherland-Hodgeman line clipping algorithm

local function ClipSegmentToPlane(p1, p2, planeNormal, planeOffset)
	local points = {}

	local d1 = planeNormal:Dot(p1) - planeOffset
	local d2 = planeNormal:Dot(p2) - planeOffset

	--[[
	print("p1, p2")
	print(p1, p2)
	print("planeNormal, planeOffset")
	print(planeNormal, planeOffset)
	print("d1, d2")
	print(d1, d2)
	]]

	if d1 <= 0 then table.Insert(points, p1) end
	if d2 <= 0 then table.Insert(points, p2) end

	if d1 * d2 < 0 then
		local t = d1 / (d1 - d2)
		local intersection = p1 + (p2 - p1) * t
		table.Insert(points, intersection)
	end

	return points
end

-- Returns either 1 or 2 points of contact.
function GM:VGUIGetContactPoints(referenceLine, incidentLine)

	--Step 1: Get the reference line and incident line. This was done and passed to us in GM:VGUISAT().
	local refPoints, incPoints = referenceLine:GetPoints(), incidentLine:GetPoints()
	r1, r2 = refPoints[1], refPoints[2]
	i1, i2 = incPoints[1], incPoints[2]

	--[[
	print("r1, r2")
	print(r1, r2)
	print("i1, i2")
	print(i1, i2)
	]]

	-- Step 2: We need the reference edge direction.
	local refDir = r2 - r1
	refDir:Normalize()

	-- Step 3: Get info on plane 1
	local plane1Normal = -refDir
	local plane1Offset = plane1Normal:Dot(r1)

	-- Step 4: Clip the incident against plane 1
	local p1, p2 = Vector2(i1:Unpack()), Vector2(i2:Unpack())
	local clippedPoints = ClipSegmentToPlane(p1, p2, plane1Normal, plane1Offset)

	-- if we have no clipped points then something went wrong with SAT.
	if #clippedPoints == 0 then Error("No collision point found.") end

	-- If we have only one clipped point we've found our singular contact point.
	if #clippedPoints == 1 then return clippedPoints end

	-- Step 5: Get info on plane 2
	local plane2Normal = refDir
	local plane2Offset = plane2Normal:Dot(r2)

	-- Step 6: Clip the new points against plane 2
	p1, p2 = clippedPoints[1], clippedPoints[2]
	clippedPoints = ClipSegmentToPlane(p1, p2, plane2Normal, plane2Offset)

	-- Same deal as above.
	if #clippedPoints == 0 then Error("No collision point found.") end

	return clippedPoints

end