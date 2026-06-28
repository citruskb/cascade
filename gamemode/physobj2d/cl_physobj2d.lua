--[[
	We use this awesome guy's implementation of simple 2d physics!
	https://github.com/majikayogames/physics-tutorial/blob/main/simple_phys.js
]]

-- Handle Lua refresh.
if not physObj2DLoaded then
	PhysObj2D = {}
	PhysObj2D.physboxes = {}
	PhysObj2D.hitboxes = {}
	PhysObj2D.collisionConstraints = {}
	PhysObj2D.collisionCandidates = {}
	PhysObj2D.lastStepTime = 0
	PhysObj2D.accuStepTime = 0

	physObj2DLoaded = true
end

-- Physics timestep length. 1 / x = called x times per second.
PHYS2D_DT = 1 / 80
PHYS2D_MAXSTEPS = 10
PHYS2D_CONSTRAINT_ITERATIONS = 3
PHYS2D_EPSILON_OVERLAP = 0.05 -- Make sure our new better overlap is smaller by at least this much.
PHYS2D_SLOP_LINEAR = 1.4 -- Allow some degree of overlap between objects without taking collision corrective action.
PHYS2D_SLOP_COL = 0.002 -- Allow some degree of leniency deciding collision points.
PHYS2D_SOFT_HERTZ = 30
PHYS2D_SOFT_DAMPINGRATIO = 10
PHYS2D_SOFT_CONTACTSPEED = 150

PHYS2D_HASHGRID_SIZE = 180	-- vgui position divided by this to determine grid position for collisions hashing.

-- TODO: These velocities probably ought to go through a screenscale check.
PHYS2D_GRAVITY = 240
PHYS2D_GRAVITY_VEC2 = Vector2(0, PHYS2D_GRAVITY)
PHYS2D_TERMINAL_VELOCITY = 500 -- Stop applying gravity after reaching this velocity.
PHYS2D_RANDOM_AIRBORNE_ROTATION = 1

PHYS2D_POP_VELOCITY = 700 -- Flat velocity applied to objects dropped outside of bounds, as they move back into bounds.

PHYS2D_SLEEP_VEL_THRESHOLD = 3
PHYS2D_SLEEP_ANGVEL_THRESHOLD = 0.1

function PhysObj2D:PhysicsStep()
	local dt = PHYS2D_DT
	local iter = PHYS2D_CONSTRAINT_ITERATIONS

	local ct = CurTime()
	self.accuStepTime = self.accuStepTime + ct - PhysObj2D.lastStepTime

	-- Clamp number of steps to prevent a runaway lag situation.
	self.accuStepTime = math.Min(self.accuStepTime, dt * PHYS2D_MAXSTEPS)

	while self.accuStepTime > dt do
		for physbox, _ in pairs(self.physboxes) do
			if physbox.parent and physbox.parent.isPhysObj2 then continue end
			physbox:Remove()
		end

		self:PhysicsPass(dt, iter)
		self.accuStepTime = self.accuStepTime - dt
	end

	PhysObj2D.lastStepTime = CurTime()

	--[[
	local backpack = GAMEMODE.backpack
	if not backpack then return end
	backpack:ClearGridDraw()
	]]
end

function PhysObj2D:PhysicsPass(dt, iter)
	self:ApplyGravity(dt)
	self:HashGridCollisions() 		-- Broad phase. Drastic performance increase.
	self:DetectCollisions()			-- Detect collisions. Build & update collision constraints.
	self:SolveConstraints(dt, iter)	-- Iteratively solve collision constraints.
	self:StepPhysboxes(dt)			-- Update our physbox pos and rot based on velocities.
end



--	[[ ApplyGravity ]]
function PhysObj2D:ApplyGravity(dt)
	for physbox, _ in pairs(self.physboxes) do
		if physbox.isStatic then continue end

		local _, y = physbox.position:Unpack()
		if y < 0 then
			physbox:AddRotation(physbox.randomAirborneRotation * dt)
		end

		local _, vy = physbox.velocity:Unpack()
		if vy >= PHYS2D_TERMINAL_VELOCITY then continue end

		physbox:AddVelocity(PHYS2D_GRAVITY_VEC2 * dt)
	end
end
-- 	[[	]]



--	[[ Hash Collisions ]]
local function GetGridIDX(x, y) return ToString(x) .. "x" .. ToString(y) end
local function HashPairID(objA, objB) return ToString(math.Min(objA.id, objB.id)) .. ":" .. ToString(math.Max(objA.id, objB.id)) end
function PhysObj2D:HashGridCollisions()
	local newGrid = {}

	local objects = {}
	for physbox, _ in pairs(self.physboxes) do
		if physbox.isPickedUp then continue end
		table.Insert(objects, physbox)
	end

	-- Get all our objects hashed into grids.
	local gridSize = PHYS2D_HASHGRID_SIZE
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

	PhysObj2D.collisionCandidates = potentialSATCandidates
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

			local collision = PhysObj2D:SAT(hitboxA, hitboxB)
			if not collision then continue end

			local hbA = collision.hbA
			local hbB = collision.hbB
			local bA = hbA.physbox
			local bB = hbB.physbox

			local contactPoints = PhysObj2D:Clip(bA, hbA, bB, hbB, collision)

			-- Create contact constraints
			for ptIdx = 1, #contactPoints.points do
				local screenP = contactPoints.points[ptIdx]
				local fID = contactPoints.fIDs[ptIdx]

				-- Try to re-use existing contact
				local existingContact = PhysObj2D.collisionConstraints[fID]
				if existingContact then
					existingContact.isReused = true
					existingContact:SetCollisionData(screenP, collision.normal, collision.penetration)
					constr[fID] = existingContact
				else
					-- But if not found, make a new one!
					local newC = CollisionConstraint:Create(bA, bB, screenP, collision.normal, collision.penetration, fID)
					constr[ToString(fID)] = newC
				end
			end
		end
	end

	return constr
end

function PhysObj2D:DetectCollisions()
	for hitbox, _ in pairs(self.hitboxes) do
		hitbox.screenPointsObjDirty = true
	end

	local rebuildCollisionConstraints = {}
	for pairID, objects in pairs(self.collisionCandidates) do
		local tab = CheckCollision(objects.bodyA, objects.bodyB)
		for fID, const in pairs(tab) do
			rebuildCollisionConstraints[fID] = const
		end
	end

	self.collisionConstraints = rebuildCollisionConstraints
end
--	[[	]]



--	[[ SolveConstraints ]]
function PhysObj2D:SolveConstraints(dt, iter)
	local contactConstraints = self.collisionConstraints

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
				if constr.bodyA.velocity:LengthSqr() < PHYS2D_SLEEP_VEL_THRESHOLD and math.Abs(constr.bodyA.angularVelocity) < PHYS2D_SLEEP_ANGVEL_THRESHOLD and 
					constr.bodyB.velocity:LengthSqr() < PHYS2D_SLEEP_VEL_THRESHOLD and math.Abs(constr.bodyB.angularVelocity) < PHYS2D_SLEEP_ANGVEL_THRESHOLD then
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



--	[[ StepPhysboxes ]]
function PhysObj2D:StepPhysboxes(dt)
	for physbox, _ in pairs(self.physboxes) do
		if physbox.isStatic then continue end
		physbox:Step(dt)
	end
end
--	[[	]]