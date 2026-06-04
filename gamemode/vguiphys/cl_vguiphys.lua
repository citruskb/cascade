-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	vguiPhysLoaded = true
end

-- How many loops do we make attempting to resolve collisions?
VGUIPHYS_PASSES = 6

-- Allow some degree of overlap between objects without taking collision corrective action.
VGUIPHYS_SLOP = 1

-- Amount to nudge velocity downwards every frame.
VGUIPHYS_GRAVITY = 0.024

-- Stop nudging velocity downards after reaching this velocity.
VGUIPHYS_TERMINAL_VELOCITY = 1.4

function GM:VGUIPhysThink()

	-- Handle gravity.
	for vphys, _ in pairs(self.VGUIPhysboxes) do
		if not IsValid(vphys) then continue end
		if vphys.resting then continue end

		-- Add our gravity up to our terminal velocity.
		local _, vy = vphys:GetVel()
		if vy and vy < VGUIPHYS_TERMINAL_VELOCITY then
			vphys:AddVel(0, VGUIPHYS_GRAVITY)
		end
	end

	-- Resolve our collisions.
	gamemode.Call("ResolveAllVGUICollisions")

	-- Set objects resting if doing so makes sense.
end