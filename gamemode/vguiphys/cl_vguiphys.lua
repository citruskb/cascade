-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	vguiPhysLoaded = true
end

VGUIPHYS_PASSES = 6
VGUIPHYS_SLOP = 1

VGUIPHYS_GRAVITY = 0.008
VGUIPHYS_TERMINAL_VELOCITY = 1.4

function GM:VGUIPhysThink()
	-- Handle gravity.
	for vphys, _ in pairs(self.VGUIPhysboxes) do
		if not IsValid(vphys) then continue end

		-- Add our gravity up to our terminal velocity.
		local _, vy = vphys:GetVel()
		if vy then print("vel", vphys:GetVel()) end
		if vy and vy < VGUIPHYS_TERMINAL_VELOCITY then
			vphys:AddVel(0, VGUIPHYS_GRAVITY)
		end
	end

	gamemode.Call("ResolveAllVGUICollisions")
end