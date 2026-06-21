--[[
	We use this awesome guy's implementation of simple 2d physics!
	https://github.com/majikayogames/physics-tutorial/blob/main/simple_phys.js
]]

local math_Max = math.Max
local math_Min = math.Min

-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	GM.VGUICollisionConstraints = {}
	GM.VGUICollisionCandidates = {}
	GM.VGUIPhysLastStepTime = 0
	GM.VGUIPhysAccuStepTime = 0
	vguiPhysLoaded = true
end

-- Physics timestep length. 1 / x = called x times per second.
VGUIPHYS_DT = 1 / 80
VGUIPHYS_MAXSTEPS = 10
VGUIPHYS_CONSTRAINT_ITERATIONS = 3
VGUI_EPSILON_OVERLAP = 0.05 -- Make sure our new better overlap is smaller by at least this much.
VGUIPHYS_SLOP_LINEAR = 1.4 -- Allow some degree of overlap between objects without taking collision corrective action.
VGUIPHYS_SLOP_COL = 0.002 -- Allow some degree of leniency deciding collision points.
VGUIPHYS_SOFT_HERTZ = 30
VGUIPHYS_SOFT_DAMPINGRATIO = 10
VGUIPHYS_SOFT_CONTACTSPEED = 150

VGUIPHYS_HASHGRID_SIZE = 180	-- vgui position divided by this to determine grid position for VGUI collisions hashing.

VGUIPHYS_GRAVITY = 240
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)
VGUIPHYS_TERMINAL_VELOCITY = 500 -- Stop applying gravity after reaching this velocity.

VGUIPHYS_SLEEP_VEL_THRESHOLD = 3
VGUIPHYS_SLEEP_ANGVEL_THRESHOLD = 0.1

function GM:VGUIPhysicsStep()
	local dt = VGUIPHYS_DT
	local iter = VGUIPHYS_CONSTRAINT_ITERATIONS

	local ct = CurTime()
	self.VGUIPhysAccuStepTime = self.VGUIPhysAccuStepTime + ct - self.VGUIPhysLastStepTime

	-- Clamp number of steps to prevent a runaway lag situation.
	self.VGUIPhysAccuStepTime = math.Min(self.VGUIPhysAccuStepTime, dt * VGUIPHYS_MAXSTEPS)

	while self.VGUIPhysAccuStepTime > dt do
		for physbox, _ in pairs(self.VGUIPhysboxes) do
			if physbox.parent and physbox.parent.isPhysicsObject2D then continue end
			physbox:Remove()
		end

		gamemode.Call("VGUIPhysicsPass", dt, iter)
		self.VGUIPhysAccuStepTime = self.VGUIPhysAccuStepTime - dt
	end

	self.VGUIPhysLastStepTime = CurTime()
end

function GM:VGUIPhysicsPass(dt, iter)
	gamemode.Call("VGUIPhysApplyGravity", dt)			-- Gravity.
	gamemode.Call("VGUIPhysHashGridCollisions")			-- Broad phase. Drastic performance increase.
	gamemode.Call("VGUIPhysDetectCollisions")			-- Detect collisions. Build & update collision constraints.
	gamemode.Call("VGUIPhysSolveConstraints", dt, iter)	-- Iteratively solve collision constraints.
	gamemode.Call("VGUIPhysStepPhysboxes", dt)			-- Update our physbox pos and rot based on velocities.
end



--	[[ ApplyGravity ]]
function GM:VGUIPhysApplyGravity(dt)
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		if physbox.isStatic then continue end

		--physbox:AddRotation(dt)

		local _, vy = physbox.velocity:Unpack()
		if vy >= VGUIPHYS_TERMINAL_VELOCITY then continue end

		physbox:AddVelocity(VGUIPHYS_GRAVITY_VEC2 * dt)
	end
end
-- 	[[	]]



--	[[ Hash Collisions ]]
local function GetGridIDX(x, y) return ToString(x) .. "x" .. ToString(y) end
local function HashPairID(objA, objB) return ToString(math.Min(objA.id, objB.id)) .. ":" .. ToString(math.Max(objA.id, objB.id)) end
function GM:VGUIPhysHashGridCollisions()
	local newGrid = {}
	--self.VGUICollisionHashGrid = {}

	local objects = {}
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		table.Insert(objects, physbox)
	end

	-- Get all our objects hashed into grids.
	local gridSize = VGUIPHYS_HASHGRID_SIZE
	for i = 1, #objects do
		local obj = objects[i]
		local aabb = obj:GetAABB()
		local minCellX = math.floor(aabb.min.x / gridSize)
		local minCellY = math.floor(aabb.min.y / gridSize)
		local maxCellX = math.floor(aabb.max.x / gridSize)
		local maxCellY = math.floor(aabb.max.y / gridSize)

		for x = minCellX, maxCellX do
			for y = minCellY, maxCellY do
				local idx = GetGridIDX(x, y)
				if not newGrid[idx] then newGrid[idx] = {} end
				table.Insert(newGrid[idx], obj)
			end
		end
	end

	-- Now go over all our grids and evaluate potential candidates
	local potentialSATCandidates = {}
	for idx, gridElements in pairs(newGrid) do
		if #gridElements == 1 then continue end
		for i = 1, #gridElements do
			for j = i + 1, #gridElements do
				potentialSATCandidates[HashPairID(gridElements[i], gridElements[j])] = {bodyA = gridElements[i], bodyB = gridElements[j]}
			end
		end
	end

	self.VGUICollisionCandidates = potentialSATCandidates
end
--	[[	]]



--	[[ DetectCollisions ]]
local function CheckCollision(bodyA, bodyB)
	if bodyA.isStatic and bodyB.isStatic then return {} end

	-- This is effectively our broad phase, all in one line.
	--if not bodyA:GetAABB():Overlaps(bodyB:GetAABB()) then return {} end

	local constr = {}
	for idxA = 1, #bodyA.hitboxes do
		local hitboxA = bodyA.hitboxes[idxA]

		for idxB = 1, #bodyB.hitboxes do
			local hitboxB = bodyB.hitboxes[idxB]

			local collision = gamemode.Call("VGUIPhysSAT", hitboxA, hitboxB)
			if not collision then continue end

			local hbA = collision.hbA
			local hbB = collision.hbB
			local bA = hbA.physbox
			local bB = hbB.physbox

			local contactPoints = gamemode.Call("ClipPolyToPoly", bA, hbA, bB, hbB, collision)

			-- Create contact constraints
			for ptIdx = 1, #contactPoints.points do
				local screenP = contactPoints.points[ptIdx]
				local fID = contactPoints.fIDs[ptIdx]

				-- Try to re-use existing contact
				local existingContact = GAMEMODE.VGUICollisionConstraints[fID]
				if existingContact then
					existingContact.isReused = true
					existingContact:SetCollisionData(screenP, collision.normal, collision.penetration)
					constr[fID] = existingContact
				else
					-- But if not found, make a new one!
					local newC = VGUICollisionConstraint:Create(bA, bB, screenP, collision.normal, collision.penetration, fID)
					constr[ToString(fID)] = newC
				end
			end
		end
	end

	return constr
end

function GM:VGUIPhysDetectCollisions()
	for hitbox, _ in pairs(self.VGUIHitboxes) do
		hitbox.screenPointsObjDirty = true
	end

	local rebuildCollisionConstraints = {}
	for pairID, objects in pairs(self.VGUICollisionCandidates) do
		local tab = CheckCollision(objects.bodyA, objects.bodyB)
		for fID, const in pairs(tab) do
			rebuildCollisionConstraints[fID] = const
		end
	end

	self.VGUICollisionConstraints = rebuildCollisionConstraints
end
--	[[	]]



--	[[ StepPhysboxes ]]
function GM:VGUIPhysStepPhysboxes(dt)
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		if physbox.isStatic then continue end
		physbox:Step(dt)
	end
end
--	[[	]]



--	[[ SolveConstraints ]]
function GM:VGUIPhysSolveConstraints(dt, iter)
	local contactConstraints = GAMEMODE.VGUICollisionConstraints

	-- Update our constraint's info.
	-- Also apply warmstarting in persistent contacts!
	local count = 0
	for fID, constr in pairs(contactConstraints) do
		constr:Update()
		if constr:Asleep() then count = count + 1 end
	end

	-- Solve, iteratively! With warmstarting for persistent contacts!
	for i = 1, iter do
		for fID, constr in pairs(contactConstraints) do
			if constr:Asleep() then continue end
			constr:Solve(dt)

			if i ~= iter then continue end

			if math.IsNearlyEqual(constr.lastNormalLambda, 0, 0.5) then
				if constr.bodyA.velocity:LengthSqr() < VGUIPHYS_SLEEP_VEL_THRESHOLD and math.Abs(constr.bodyA.angularVelocity) < VGUIPHYS_SLEEP_ANGVEL_THRESHOLD and 
					constr.bodyB.velocity:LengthSqr() < VGUIPHYS_SLEEP_VEL_THRESHOLD and math.Abs(constr.bodyB.angularVelocity) < VGUIPHYS_SLEEP_ANGVEL_THRESHOLD then
						constr:SleepBodies()
				end
			else
				constr:WakeBodies()
			end
		end
	end

	-- Evaluate bounce.
	for fID, constr in pairs(contactConstraints) do
		if constr:Asleep() then continue end
		constr:ApplyRestitution()
	end

end
--	[[	]]



--	[[ SAT - Separating Axis Theorem ]]
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
		if smallestOverlap and overlap >= smallestOverlap - VGUI_EPSILON_OVERLAP then continue end

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
		if smallestOverlap and overlap >= smallestOverlap - VGUI_EPSILON_OVERLAP then continue end

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
--	[[	]]



--	[[ ClipPolyToPoly -- Sutherland-Hodgeman line clipping algorithm ]]
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

	-- Clip to start and end faces. Tangents on ends of reference edge
	local refTangent = (a2 - a1):GetNormalized()

	local clippedPoints = ClipLineSegmentToLine(b1, b2, -refTangent, a1)
	if #clippedPoints == 0 then return {points = {}, fIDs = {}} end
	clippedPoints = ClipLineSegmentToLine(clippedPoints[1], clippedPoints[2], refTangent, a2)

	-- Keep points that are behind the reference face, plus speculative slop
	local finalPoints = {points = {}, fIDs = {}}
	for i = 1, #clippedPoints do
		local point = clippedPoints[i]
		if n:Dot(point - a1) > VGUIPHYS_SLOP_COL then continue end
		table.Insert(finalPoints.points, point)
		table.Insert(finalPoints.fIDs, gamemode.Call("VGUIPhysGetFeatureID", refHitbox, incHitbox, refIdx, incIdx, i))
	end

	return finalPoints
end
--	[[	]]



--	[[ Feature ID - make sure that contact points are uniquely trackable frame-to-frame. ]]
function GM:VGUIPhysGetFeatureID(refHitbox, incHitbox, refIDX, incIDX, idx)
	local refPhysbox = refHitbox.physbox
	local incPhysbox = incHitbox.physbox

	local refPhysID = refPhysbox.id
	local incPhysID = incPhysbox.id
	local refHitID = refHitbox.id
	local incHitID = incHitbox.id

	local prefix =
		bit.Bor(
			bit.Lshift(bit.Band(refPhysID, 0xFF), 24),
			bit.Lshift(bit.Band(incPhysID, 0xFF), 16),
			bit.Lshift(bit.Band(refHitID, 0xF), 12),
			bit.Lshift(bit.Band(incHitID, 0xF), 8)
		)

	local refNumPoints = refHitbox.pointsObj:Count()
	local incNumPoints = incHitbox.pointsObj:Count()

	local i11 = refIDX							-- ref edge start vertex (a1)
	local i12 = (i11 + 1) % refNumPoints		-- ref edge end vertex (a2)
	local i21 = incIDX							-- incident edge start vertex (b1)
	local i22 = (i21 + 1) % incNumPoints		-- incident edge end vertex (b2)

	local suffix
	if idx == 1 then
		suffix =
			bit.Bor(
				bit.Lshift(bit.Band(i11, 0xF), 4),
				bit.Band(i22, 0xF)
			)
	else
		suffix =
			bit.Bor(
				bit.Lshift(bit.Band(i12, 0xF), 4),
				bit.Band(i21, 0xF)
			)
	end

	return ToString(bit.Bor(prefix, suffix))
end
--	[[	]]