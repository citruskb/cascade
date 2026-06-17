--[[
	We use this awesome guy's implementation of simple 2d physics!
	https://github.com/majikayogames/physics-tutorial/blob/main/simple_phys.js
]]

-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIHitboxes = {}
	GM.VGUICollisionConstraints = {}
	GM.VGUIPhysLastStepTime = 0
	GM.VGUIPhysAccuStepTime = 0
	vguiPhysLoaded = true
end

-- Physics timestep length. 1 / x = called x times per second.
VGUIPHYS_DT = 1 / 100
VGUIPHYS_MAXSTEPS = 10
VGUIPHYS_CONSTRAINT_ITERATIONS = 3--10
VGUI_EPSILON_OVERLAP = 0.05 -- Make sure our new better overlap is smaller by at least this much.
VGUIPHYS_SLOP_LINEAR = 0.002 -- Allow some degree of overlap between objects without taking collision corrective action.
VGUIPHYS_SOFT_HERTZ = 50
VGUIPHYS_SOFT_DAMPINGRATIO = 3
VGUIPHYS_SOFT_CONTACTSPEED = 150

VGUIPHYS_GRAVITY = 240
VGUIPHYS_GRAVITY_VEC2 = Vector2(0, VGUIPHYS_GRAVITY)
VGUIPHYS_TERMINAL_VELOCITY = 240 -- Stop applying gravity after reaching this velocity.


function GM:VGUIPhysicsStep()
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

		physbox:AddRotation(dt)

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
