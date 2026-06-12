GM.VGUIPhysPassCount = 0
local gamemode_Call = gamemode.Call
local math_Abs = math.Abs

function GM:VGUIPhysPassComplete() end
function GM:VGUIPhysCollisionsResolved() return self.VGUIPhysPassCount == VGUIPHYS_PASSES end

function GM:ResolveAllVGUICollisions()
	local physboxes = GAMEMODE.VGUIPhysboxes
	local hitboxes = GAMEMODE.VGUIHitboxes
	for i = 1, VGUIPHYS_PASSES do
		-- Assume no support. Support toggled in collision resolution if appropriate.
		for physbox, _ in pairs(physboxes) do physbox:SetSupported(false) end

		local collisions = {}
		for hbA, _  in pairs(hitboxes) do
			for hbB, _ in pairs(hitboxes) do
				local collision = gamemode_Call("VGUISAT", hbA, hbB)
				if not collision then
					continue
				end

				table.Insert(collisions, collision)
			end
		end

		for k, collision in pairs(collisions) do
			gamemode_Call("ResolveVGUICollision", collision)
		end

		gamemode_Call("VGUIPhysPassComplete")
		gamemode_Call("VGUIPhysboxPhysPassThink")
		GAMEMODE.VGUIPhysPassCount = i
	end
end

local function ApplyTranslations(physboxA, physboxB, transA)
	physboxA:AddDesiredTrans(transA)
	physboxB:AddDesiredTrans(-transA)
end

local function OldResolveVelocity(physboxA, physboxB, mtv)
	local velA, velB = Rawget(physboxA, "_vel"), Rawget(physboxB, "_vel")
	if velA:IsZero() and velB:IsZero() then return end

	local rv = velB - velA
	local rnv = rv:Dot(mtv)
	if rnv > 0 then return end -- Objects already moving apart.

	local bounce = 0.2
	local massA, massB = physboxA.mass or 1, physboxB.mass or 1 -- TODO: implement mass properly.

	local j = rnv * -(1 + bounce)
	j = j / (massA + massB)

	local impulse = mtv * j

	--[[
	print("///")
	print("old linear impulse A", -impulse * massA)
	print("old linear impulse B", impulse * massB)
	]]
end

local function ResolveVelocity(physboxA, physboxB, mtv, contactPoint, div, pen)
	-- First, get our lever points.
	local centerA, centerB = physboxA:GetPhysicsPassPointsCenter(), physboxB:GetPhysicsPassPointsCenter()
	local rA = contactPoint - centerA
	local rB = contactPoint - centerB

	-- We need our velocity at these points.
	local vA = Rawget(physboxA, "_vel") + rA:CrossS(Rawget(physboxA, "_radvel"))
	local vB = Rawget(physboxB, "_vel") + rB:CrossS(Rawget(physboxB, "_radvel"))

	-- If velocities are zero, do nothing.
	if vA:IsZero() and vB:IsZero() then return end

	-- Get the velocity relative to each other along the normal.
	local rv = vB - vA
	local rnv = rv:Dot(mtv)
	if rnv > 0 then return end -- Objects already moving apart.

	-- Calculate the impulse to apply.
	local raCrossmtv, rbCrossmtv = rA:Cross(mtv), rB:Cross(mtv)
	local invMassA, invMassB = physboxA:GetInvMass(), physboxB:GetInvMass()
	local invInertiaA, invInertiaB = physboxA:GetInvInertia(), physboxB:GetInvInertia()
	local effMass = invMassA + invMassB + raCrossmtv^2 * invInertiaA + rbCrossmtv^2 * invInertiaB

	local bounce = 0.2
	local j = rnv * -(1 + bounce)
	j = j / effMass
	local impulse = mtv * j / div

	-- Apply linear impulse.
	physboxA:AddVel(-impulse * invMassA)
	physboxB:AddVel(impulse * invMassB)

	-- Apply angular impulse.
	print("before (A):", physboxA:GetRad())
	print("before (B):", physboxB:GetRad())
	physboxA:AddRadVel(rA:Cross(impulse) * -invInertiaA)
	physboxB:AddRadVel(rB:Cross(impulse) * invInertiaB)
end

local function CheckSupported(physboxA, physboxB, mtv)
	-- Check if our collision normal is roughly vertical.
	local _, ny = mtv:Unpack()
	if math_Abs(ny) <= 0.7 then return end

	-- Get our center points for our objects.
	local _, cay = physboxA:GetPointsOrigin():Unpack()
	local _, cby = physboxB:GetPointsOrigin():Unpack()

	-- If one is higher than the other, the other is being supported.
	-- Remember, a more positive y value is actually lower.
	if cay < cby then
		physboxA:SetSupported(true)
	else
		physboxB:SetSupported(true)
	end
end

function GM:ResolveVGUICollision(data)
	local physboxA = Rawget(data, "physboxA")
	local physboxB = Rawget(data, "physboxB")
	local overlap = Rawget(data, "overlap")
	local mtv = Rawget(data, "mtv")
	local contactPoints = Rawget(data, "contactPoints")

	-- We desire to apply a translation to resolve the collision.
	-- The root might be invalid if we are a solid wall!

	-- Only do a corrective translation if penetration is large enough.
	if overlap > VGUIPHYS_SLOP then
		local cappedOverlap = math.Min(overlap, 1)
		local translationA = -mtv * cappedOverlap
		ApplyTranslations(physboxA, physboxB, translationA)
	end

	OldResolveVelocity(physboxA, physboxB, mtv)
	for i = 1, #contactPoints do
		ResolveVelocity(physboxA, physboxB, mtv, contactPoints[i], #contactPoints, overlap)
	end

	CheckSupported(physboxA, physboxB, mtv)

end