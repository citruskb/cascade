--[[
	We use this awesome guy's implementation of simple 2d physics!
	https://github.com/majikayogames/physics-tutorial/blob/main/simple_phys.js
]]

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

-- TODO: These velocities probably ought to go through a screenscale check.
VGUIPHYS_GRAVITY = 240
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)
VGUIPHYS_TERMINAL_VELOCITY = 500 -- Stop applying gravity after reaching this velocity.
VGUIPHYS_RANDOM_AIRBORNE_ROTATION = 1

VGUIPHYS_PUSH_VELOCITY = 700 -- Flat velocity applied to objects dropped outside of bounds, as they move back into bounds.

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

		local _, y = physbox.position:Unpack()
		if y < 0 then
			physbox:AddRotation(physbox.randomAirborneRotation * dt)
		end

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
		if physbox.isPickedUp then continue end
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