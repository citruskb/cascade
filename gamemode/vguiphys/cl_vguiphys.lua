-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	GM.VGUIPotentialCollisions = {}
	vguiPhysLoaded = true
end

-- How many loops do we make attempting to resolve collisions?
VGUIPHYS_PASSES = 8

-- Allow some degree of overlap between objects without taking collision corrective action.
VGUIPHYS_SLOP = 1.5

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

function GM:VGUIUpdateParentVars()
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		physbox:UpdateParentVars()
	end
end

function GM:VGUIPhysicsStep(tim, iterations)
	for i = 1, iterations do
		self.VGUIPotentialCollisions = {}
		--benchmark.Start("StepPhysboxes")
		gamemode.Call("VGUIStepPhysboxes", tim, iterations)		-- Step through time and apply physics.
		--benchmark.End("StepPhysboxes")

		--benchmark.Start("BroadPhase")
		gamemode.Call("VGUIBroadPhase")							-- Use simple AABB to find potential collisions.
		--benchmark.End("BroadPhase")

		--benchmark.Start("VGUINarrowPhase")
		gamemode.Call("VGUINarrowPhase")						-- Refine collisions with SAT, and resolve said collisions.
		--benchmark.End("VGUINarrowPhase")
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

			local pA = hbA:GetPhysicsPassScreenPoints()
			local pB = hbB:GetPhysicsPassScreenPoints()
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

