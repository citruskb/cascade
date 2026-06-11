-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
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
VGUIPHYS_GRAVITY = 0.024
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)

-- If our x or y velocity is under this much on collision it gets zero'd out.
--VGUI_EPSILON_VELOCITY = VGUIPHYS_GRAVITY * 2

-- Stop nudging velocity downards after reaching this velocity.
VGUIPHYS_TERMINAL_VELOCITY = 1.4

local SPIN = 0.02


function GM:VGUIPhysicsThink()

	-- Handle gravity. Remove physboxes with an invalid parent.
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		local parent = physbox:GetParent()
		if not IsValid(parent) then
			physbox:Remove()
			continue
		else
			if parent.IsItem then
				--physbox:AddRad(SPIN)
			end
		end

		-- Don't apply gravity to supported objects.
		if physbox:IsSupported() then continue end

		-- Add our gravity up to our terminal velocity.
		local vel = physbox:GetVel()
		if not vel then continue end

		local _, vy = vel:Unpack()
		if vy >= VGUIPHYS_TERMINAL_VELOCITY then continue end

		physbox:AddVel(VGUIPHYS_GRAVITY_VEC2)
	end

	-- Resolve our collisions.
	gamemode.Call("ResolveAllVGUICollisions")

end

function GM:VGUIPhysboxThink()
	for vphys, _ in pairs(self.VGUIPhysboxes) do vphys:DoPhysicsThink() end
end
function GM:VGUIPhysboxPhysPassThink()
	for vphys, _ in pairs(self.VGUIPhysboxes) do vphys:DoPhysicsPassThink() end
end