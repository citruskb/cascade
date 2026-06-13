-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	GM.VGUIPotentialCollisions = {}
	vguiPhysLoaded = true
end

-- How many loops do we make attempting to resolve collisions?
VGUIPHYS_PASSES = 12

-- Allow some degree of overlap between objects without taking collision corrective action.
VGUIPHYS_SLOP = 1.5

-- A bit of leniency determining if a collision point is behind a face or not.
VGUIPHYS_SLOP_COL_POINT = 0.01 --VGUIPHYS_SLOP

-- Make sure our new better overlap is smaller by at least this much.
VGUI_EPSILON_OVERLAP = 0.05

-- Amount to nudge velocity downwards every frame.
VGUIPHYS_GRAVITY = 240 --0.024
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)

-- If our x or y velocity is under this much on collision it gets zero'd out.
--VGUI_EPSILON_VELOCITY = VGUIPHYS_GRAVITY * 2

-- Stop nudging velocity downards after reaching this velocity.
VGUIPHYS_TERMINAL_VELOCITY = 240 --1.4

local SPIN = 0.02

function GM:VGUIUpdateParentVars()
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		physbox:UpdateParentVars()
	end
end

function GM:VGUIPhysicsStep(tim, iterations)
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
	end
end

function GM:VGUIBroadPhase()
	--local physboxes = self.VGUIPhysboxes
	local hitboxes = self.VGUIHitboxes
	local col = self.VGUIPotentialCollisions

	for hbA, _  in pairs(hitboxes) do
		for hbB, _ in pairs(hitboxes) do
			if hbA == hbB then continue end

			local pA = hbA:GetPhysicsPassScreenPoints()
			local pB = hbB:GetPhysicsPassScreenPoints()
			if not pA:IntersectAABB(pB) then continue end

			--[[
			local collision = gamemode_Call("VGUISAT", hbA, hbB)
			if not collision then continue end
			]]

			table.Insert(col, {hbA = hbA, hbB = hbB})
		end
	end
end

function GM:VGUINarrowPhase()
	local col = self.VGUIPotentialCollisions
	for i = 1, #col do
		local data = col[i]
		local hbA, hbB = Rawget(data, "hbA"), Rawget(data, "hbB")

		local collision = gamemode.Call("VGUISAT", hbA, hbB)
		if not collision then continue end

		gamemode.Call("SeparatePhysboxes", collision)
		collision.contactPoints = gamemode.Call("GetCollisionPoints", collision)
		gamemode.Call("ResolveCollision", collision)
	end
end

