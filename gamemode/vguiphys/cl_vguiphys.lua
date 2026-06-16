--[[
	We use this awesome guy's implementation of simple 2d physics!
	https://github.com/majikayogames/physics-tutorial/blob/main/simple_phys.js
]]

-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	GM.VGUIPotentialCollisions = {}
	GM.VGUIPhysLastStepTime = 0
	GM.VGUIPhysAccuStepTime = 0
	vguiPhysLoaded = true
end

--	[[ New! ]]

-- Physics timestep length. 1 / x = called x times per second.
VGUIPHYS_DT = 1 / 240
VGUIPHYS_MAXSTEPS = 10
VGUIPHYS_CONSTRAINT_ITERATIONS = 10
VGUIPHYS_SLOP_LINEAR = 1.5	-- Allow some degree of overlap between objects without taking collision corrective action.
VGUIPHYS_SOFT_HERTZ = 30
VGUIPHYS_SOFT_DAMPINGRATIO = 10
VGUIPHYS_SOFT_CONTACTSPEED = 3

--	[[ End new ]]


-- How many loops do we make attempting to resolve collisions?
VGUIPHYS_PASSES = 8

-- A bit of leniency determining if a collision point is behind a face or not.
VGUIPHYS_SLOP_COL_POINT = 0.005

-- Make sure our new better overlap is smaller by at least this much.
VGUI_EPSILON_OVERLAP = 0.05

-- Amount to nudge velocity downwards every frame.
VGUIPHYS_GRAVITY = 240 --0.024
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)

VGUI_STATIC_FRICTION = 2
VGUI_DYNAMIC_FRICTION = 1.5

-- Checks delta in position and rotation for sleeping.
VGUIPHYS_POS_SLEEP_THRESHOLD = 1
VGUIPHYS_RAD_SLEEP_THRESHOLD = 0.01

-- Stop nudging velocity downards after reaching this velocity.
VGUIPHYS_TERMINAL_VELOCITY = 240 --1.4

-- How different can x-y values of persistent contact points be and still be considered persistent?
VGUIPHYS_WARMSTART_TOL = 0--0.01

-- How close to zero should our velocity be to stop our motion? Note this uses the sqr value.
VGUIPHYS_SLEEP_VEL = 2500 -- 50^2


local SPIN = 0.02



--	[[ NEW ]]
function GM:VGUIPhysicsStep2()
	local dt = VGUIPHYS_DT
	local iter = VGUIPHYS_CONSTRAINT_ITERATIONS

	local ct = CurTime()
	self.VGUIPhysAccuStepTime = self.VGUIPhysAccuStepTime + ct - self.VGUIPhysLastStepTime

	-- Clamp number of steps to prevent a runaway lag situation.
	self.VGUIPhysAccuStepTime = math.Min(self.VGUIPhysAccuStepTime, dt * VGUIPHYS_MAXSTEPS)

	while self.VGUIPhysAccuStepTime > dt do
		for physbox, _ in pairs(self.VGUIPhysboxes) do
			if IsValid(physbox.parent) then continue end
			physbox:Remove()
		end

		gamemode.Call("VGUIPhysicsPass", dt, iter)
		self.VGUIPhysAccuStepTime = self.VGUIPhysAccuStepTime - dt
	end

	self.VGUIPhysLastStepTime = CurTime()
end

function GM:VGUIPhysicsPass(dt, iter)
	gamemode.Call("VGUIPhysApplyGravity", dt)			-- Gravity.
	gamemode.Call("VGUIPhysDetectCollisions")			-- Detect collisions. Build & update collision constraints.
	gamemode.Call("VGUIPhysSolveConstraints", dt, iter)	-- Iteratively solve collision constraints.
	gamemode.Call("VGUIPhysStepPhysboxes", dt)			-- Update our physbox pos and rot based on velocities.
end

function GM:VGUIPhysApplyGravity(dt)
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		if physbox.isStatic then continue end

		local _, vy = physbox.velocity:Unpack()
		if vy >= VGUIPHYS_TERMINAL_VELOCITY then continue end

		physbox:AddVelocity(VGUIPHYS_GRAVITY_VEC2 * dt)
	end
end

function GM:VGUIPhysStepPhysboxes(dt)
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		if physbox.isStatic then continue end
		physbox:Step(dt)
	end
end

function GM:VGUIPhysSolveConstraints(dt, iter)
	local contactConstraints = GAMEMODE.VGUICollisionConstraints

	-- Update our constraint's info.
	-- Also apply warmstarting in persistent contacts!
	for fID, constr in pairs(contactConstraints) do
		constr:Update()
	end

	-- Solve, iteratively! With warmstarting for persistent contacts!
	for i = 1, iter do
		for fID, constr in pairs(contactConstraints) do
			constr:Solve(dt)
		end
	end

	-- Evaluate bounce.
	for fID, constr in pairs(contactConstraints) do
		constr:ApplyRestitution()
	end

end




--	[[ end new ]]

--[[
function GM:VGUIPhysicsStep1(tim, iterations)
	for i = 1, iterations do
		self.VGUIPotentialCollisions = {}
		gamemode.Call("VGUIStepPhysboxes", tim, iterations)		-- Step through time and apply physics.
		gamemode.Call("VGUIBroadPhase")							-- Use simple AABB to find potential collisions.
		gamemode.Call("VGUINarrowPhase")						-- Refine collisions with SAT, and resolve said collisions.
	end
end

function GM:VGUIStepPhysboxes(tim, iterations)
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		-- Remove invalid physboxes.
		local parent = physbox:GetParent()
		if not IsValid(parent) then
			physbox:Remove()
			continue
		end

		physbox:Step(tim, iterations)
		physbox:SetStable(false)
	end
end

function GM:VGUIBroadPhase()
	--local physboxes = self.VGUIPhysboxes
	local hitboxes = self.VGUIHitboxes
	local col = self.VGUIPotentialCollisions
	local cache = {}

	for hbA, _  in pairs(hitboxes) do
		cache[hbA] = cache[hbA] or {}

		for hbB, _ in pairs(hitboxes) do
			cache[hbB] = cache[hbB] or {}

			if hbA == hbB then continue end

			local pA = hbA:GetHBScreenPointsObj()
			local pB = hbB:GetHBScreenPointsObj()
			if not pA:IntersectAABB(pB) then continue end

			-- Check if we've already marked this pairing for collision evaluation.
			if cache[hbA][hbB] or cache[hbB][hbA] then continue end

			table.Insert(col, {hbA = hbA, hbB = hbB})
			cache[hbA][hbB] = true
			cache[hbB][hbA] = true
		end
	end
end

function GM:VGUINarrowPhase()
	local col = self.VGUIPotentialCollisions
	for i = 1, #col do
		local data = col[i]
		local hbA, hbB = Rawget(data, "hbA"), Rawget(data, "hbB")

		--benchmark.Start("VGUISAT")
		local collision = gamemode.Call("VGUISAT", hbA, hbB)
		--benchmark.End("VGUISAT")
		if not collision then continue end

		--benchmark.Start("SeparatePhysboxes")
		gamemode.Call("SeparatePhysboxes", collision)
		--benchmark.End("SeparatePhysboxes")

		--benchmark.Start("GetCollisionPoints")
		local contactPoints, refIDX, incIDX = gamemode.Call("GetCollisionPoints", collision)
		collision.contactPoints = contactPoints
		collision.refIDX = refIDX
		collision.incIDX = incIDX
		--benchmark.End("GetCollisionPoints")

		--benchmark.Start("ResolveCollision")
		gamemode.Call("ResolveCollision", collision)
		--benchmark.End("ResolveCollision")
	end
end
]]
