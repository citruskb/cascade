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

-- Make sure our new better overlap is smaller by at least this much.
VGUI_EPSILON_OVERLAP = 0.05

-- Amount to nudge velocity downwards every frame.
VGUIPHYS_GRAVITY = 0.024
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)

-- If our x or y velocity is under this much on collision it gets zero'd out.
--VGUI_EPSILON_VELOCITY = VGUIPHYS_GRAVITY * 2

-- Stop nudging velocity downards after reaching this velocity.
VGUIPHYS_TERMINAL_VELOCITY = 1.4

function GM:VGUIPhysicsThink()

	-- Handle gravity.
	for vphys, _ in pairs(self.VGUIPhysboxes) do
		-- Don't apply gravity to supported objects.
		if vphys.supported then continue end

		-- Add our gravity up to our terminal velocity.
		local vel = vphys:GetVel()
		if not vel then continue end

		local _, vy = vel:Unpack()
		if vy >= VGUIPHYS_TERMINAL_VELOCITY then continue end

		vphys:AddVel(VGUIPHYS_GRAVITY_VEC2)
	end

	-- Resolve our collisions.
	--gamemode.Call("ResolveAllVGUICollisions")

	-- Set objects resting if doing so makes sense.
end

function GM:VGUIPhysboxThink()
	for vphys, _ in pairs(self.VGUIPhysboxes) do vphys:DoPhysicsThink() end
end