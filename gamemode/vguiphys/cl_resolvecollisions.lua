if not VGUICollisionsLoaded then
	GM.WarmStartImpulses = {}
	VGUICollisionsLoaded = true
end

local math_Abs = math.Abs
local gamemode_Call = gamemode.Call

function GM:SeparatePhysboxes(data)
	local overlap = Rawget(data, "overlap")
	if overlap <= VGUIPHYS_SLOP then return end

	local physboxA = Rawget(data, "physboxA")
	local physboxB = Rawget(data, "physboxB")
	local mtv = Rawget(data, "mtv")

	-- We target our movement for the middle of our slop allowance. 
	overlap = overlap - (VGUIPHYS_SLOP * 0.5)

	if not Rawget(physboxA, "_physics") then
		physboxB:AddPartialPos(mtv * overlap)
	elseif not Rawget(physboxB, "_physics") then
		physboxA:AddPartialPos(-mtv * overlap)
	else
		physboxA:AddPartialPos(-mtv * overlap * 0.5)
		physboxB:AddPartialPos(mtv * overlap * 0.5)
	end
end

local function GetNormal(tab, i)
	local vec1 = Rawget(tab, i)
	local vec2 = Rawget(tab, (i % #tab) + 1)
	local normal = Vector2(Rawget(vec2, "y") - Rawget(vec1, "y"), Rawget(vec1, "x") - Rawget(vec2, "x"))
	return normal:GetNormalized()
end
local function GetBestAlignment(pointsTab, alignTo)
	local bestP1, bestP2, bestIDX
	local bestAlignment
	for i = 1, #pointsTab do
		local p1 = pointsTab[i]
		local p2 = pointsTab[(i % #pointsTab) + 1]
		local normal = GetNormal(pointsTab, i)
		local alignment = normal:Dot(alignTo)

		if bestAlignment and alignment >= bestAlignment then continue end
		bestAlignment = alignment
		bestP1 = p1
		bestP2 = p2
		bestIDX = i
	end
	return Points({bestP1, bestP2}), bestIDX
end

function GM:GetCollisionPoints(data)
	local hbA = Rawget(data, "hbA")
	local hbB = Rawget(data, "hbB")
	local mtv = Rawget(data, "mtv")
	local pointsTabA = hbA:GetPhysicsPassScreenPoints():GetPoints()
	local pointsTabB = hbB:GetPhysicsPassScreenPoints():GetPoints()

	local referenceLine, refIDX = GetBestAlignment(pointsTabA, -mtv)
	local incidentLine, incIDX = GetBestAlignment(pointsTabB, mtv)
	local contactPoints = gamemode_Call("VGUIGetContactPoints", referenceLine, incidentLine, mtv)

	return contactPoints, refIDX, incIDX
end

local function ApplyImpulse(physboxA, physboxB, impulse, rA, rB)
	if impulse:IsZero() then return impulse end

	physboxA:AddVel(-impulse * physboxA:GetInvMass())
	physboxB:AddVel(impulse * physboxB:GetInvMass())
	physboxA:AddRadVel(-rA:Cross(impulse) * physboxA:GetInvInertia())
	physboxB:AddRadVel(rB:Cross(impulse) * physboxB:GetInvInertia())

	return impulse
end

local function ResolveWarmStart(physboxA, physboxB, contactPoint, fID)
	local rA = contactPoint - physboxA:GetPhysicsPassPointsCenter()
	local rB = contactPoint - physboxB:GetPhysicsPassPointsCenter()

	local warmImpulse = gamemode.Call("VGUIGetWarmImpulse", fID) or 0
	ApplyImpulse(physboxA, physboxB, warmImpulse, rA, rB)

	local warmFrictionImpulse = gamemode.Call("VGUIGetWarmFrictionImpulse", fID) or 0
	ApplyImpulse(physboxA, physboxB, warmFrictionImpulse, rA, rB)

	return warmImpulse, warmFrictionImpulse
end

local function ResolveVelocity(warmImpulse, hbA, hbB, physboxA, physboxB, mtv, contactPoint, div, i)
	-- First, get our lever points.
	local centerA, centerB = physboxA:GetPhysicsPassPointsCenter(), physboxB:GetPhysicsPassPointsCenter()

	local rA = contactPoint - centerA
	local xa, ya = rA:Unpack()
	local rB = contactPoint - centerB
	local xb, yb = rB:Unpack()

	local rAP = Vector2(-ya, xa)
	local rBP = Vector2(-yb, xb)

	-- We need our velocity at these points.
	local vA = Rawget(physboxA, "_vel") + rAP * Rawget(physboxA, "_radvel")
	local vB = Rawget(physboxB, "_vel") + rBP * Rawget(physboxB, "_radvel")

	-- If velocities are zero, do nothing.
	--if vA:IsZero() and vB:IsZero() then return liA, liB, riA, riB end

	-- Get the velocity relative to each other along the normal.
	local rv = vB - vA
	local rnv = rv:Dot(mtv)

	if rnv > 0 then return end -- Objects already moving apart.

	-- Calculate the impulse to apply.
	local rAPDotMTV, rBPDotMTV = rAP:Dot(mtv), rBP:Dot(mtv)
	local invMassA, invMassB = physboxA:GetInvMass(), physboxB:GetInvMass()
	local invInertiaA, invInertiaB = physboxA:GetInvInertia(), physboxB:GetInvInertia()
	local denom = invMassA + invMassB + rAPDotMTV * rAPDotMTV * invInertiaA + rBPDotMTV * rBPDotMTV * invInertiaB

	local bounce = 0.2
	local j = rnv * -(1 + bounce)
	j = j / denom
	j = j / div
	local impulse = j * mtv

	-- For warmstarting we need to get the difference between our warmstart and apply that as our impulse instead.
	impulse = impulse - warmImpulse

	return impulse, rA, rB, j
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
		--physboxA:SetSupported(true, physboxB)
	else
		--physboxB:SetSupported(true, physboxA)
	end
end

local function ResolveFriction(warmFrictionImpulse, physboxA, physboxB, mtv, contactPoint, div, j)
	-- First, get our lever points.
	local centerA, centerB = physboxA:GetPhysicsPassPointsCenter(), physboxB:GetPhysicsPassPointsCenter()

	local rA = contactPoint - centerA
	local xa, ya = rA:Unpack()
	local rB = contactPoint - centerB
	local xb, yb = rB:Unpack()

	local rAP = Vector2(-ya, xa)
	local rBP = Vector2(-yb, xb)

	-- We need our velocity at these points.
	local vA = Rawget(physboxA, "_vel") + rAP * Rawget(physboxA, "_radvel")
	local vB = Rawget(physboxB, "_vel") + rBP * Rawget(physboxB, "_radvel")

	-- If velocities are zero, do nothing.
	--if vA:IsZero() and vB:IsZero() then return liA, liB, riA, riB end

	-- Get the velocity relative to each other along the normal.
	local rv = vB - vA
	local rnv = rv:Dot(mtv)
	if rnv > 0 then return liA, liB, riA, riB end -- Objects already moving apart.

	local tangent = rv - rv:Dot(mtv) * mtv
	if tangent:IsEqualTol(VECTOR2_ZERO, 0.00001) then
		return
	end

	tangent:Normalize()

	-- Calculate the impulse to apply.
	local rAPDotT, rBPDotT = rAP:Dot(tangent), rBP:Dot(tangent)
	local invMassA, invMassB = physboxA:GetInvMass(), physboxB:GetInvMass()
	local invInertiaA, invInertiaB = physboxA:GetInvInertia(), physboxB:GetInvInertia()
	local denom = invMassA + invMassB + rAPDotT^2 * invInertiaA + rBPDotT^2 * invInertiaB

	local jT = -rv:Dot(tangent)
	jT = jT / denom
	jT = jT / div

	-- Coulomb's Law
	local frictionImpulse
	if math.Abs(jT) <= j * VGUI_STATIC_FRICTION then
		frictionImpulse = jT * tangent
	else
		frictionImpulse = -j * tangent * VGUI_DYNAMIC_FRICTION
	end

	-- For warmstarting we need to get the difference between our warmstart and apply that as our impulse instead.
	frictionImpulse = frictionImpulse - warmFrictionImpulse

	return frictionImpulse, rA, rB
end

function GM:ResolveCollision(manifold)
	local hbA = Rawget(manifold, "hbA")
	local hbB = Rawget(manifold, "hbB")
	local refIDX = Rawget(manifold, "refIDX")
	local incIDX = Rawget(manifold, "incIDX")
	local physboxA = Rawget(manifold, "physboxA")
	local physboxB = Rawget(manifold, "physboxB")
	local mtv = Rawget(manifold, "mtv")
	local contactPoints = Rawget(manifold, "contactPoints")

	Rawset(manifold, "fIDList", {})

	-- First, warmstarting.
	-- We check if this contact point is persistent frame-to-frame.
	-- If it is, we apply a portion of the old accumulated solution as our starting point here
	-- This is done for both our typical impulses and friction.
	-- Helps improve stability.

	local fIDList = Rawget(manifold, "fIDList")
	local warmstartImpulses = {}
	local warmStartFrictionImpulses = {}
	local unstable
	for i = 1, #contactPoints do
		local fID = gamemode.Call("GetFeatureID", hbA, hbB, refIDX, incIDX, i)
		table.Insert(fIDList, fID)

		-- If our contact point isn't persistent, reset our contact data. No warm start.
		local contactPoint = contactPoints[i]
		if not gamemode.Call("VGUIIsPersistentContact", fID, contactPoint) then
			warmstartImpulses[i], warmStartFrictionImpulses[i] = Vector2(), Vector2()
			gamemode.Call("VGUIInitWarmstartData", fID, contactPoint, warmstartImpulses[i], warmStartFrictionImpulses[i])

			unstable = true
			physboxA:SetStable(false)
			physboxB:SetStable(false)
			continue
		end

		-- if persistent, apply stored impulses, and remember that we are warmstarting.
		warmstartImpulses[i], warmStartFrictionImpulses[i] = ResolveWarmStart(physboxA, physboxB, contactPoint, fID)
		physboxA:SetStable(not unstable)
		physboxB:SetStable(not unstable)
	end

	-- Get our velocity impulses.
	local impulses = {}
	local rAs = {}
	local rBs = {}
	local js = {}
	for i = 1, #contactPoints do
		local impulse, rA, rB, j = ResolveVelocity(warmstartImpulses[i], hbA, hbB, physboxA, physboxB, mtv, contactPoints[i], #contactPoints, i)
		if not impulse then continue end

		impulses[i] = impulse
		rAs[i] = rA
		rBs[i] = rB
		js[i] = j
	end

	-- Apply our velocity impulses.
	for i = 1, #contactPoints do
		if not impulses[i] then continue end
		impulses[i] = ApplyImpulse(physboxA, physboxB, impulses[i], rAs[i], rBs[i])
	end

	-- Get our friction impulses.
	local frictionImpulses = {}
	rAs = {}
	rBs = {}
	for i = 1, #contactPoints do
		if not js[i] then continue end

		local frictionImpulse, rA, rB = ResolveFriction(warmStartFrictionImpulses[i], physboxA, physboxB, mtv, contactPoints[i], #contactPoints, js[i])
		if not frictionImpulse then continue end

		frictionImpulses[i] = frictionImpulse
		rAs[i] = rA
		rBs[i] = rB
	end

	-- Apply our friction impulses.
	for i = 1, #contactPoints do
		if not frictionImpulses[i] then continue end
		frictionImpulses[i] = ApplyImpulse(physboxA, physboxB, frictionImpulses[i], rAs[i], rBs[i])
	end

	-- Update our warmstart values.
	-- But only if we aren't frozen.
	for i = 1, #contactPoints do
		gamemode.Call("VGUIWarmstartLambda", fIDList[i], impulses[i], frictionImpulses[i], contactPoints[i])
	end

	CheckSupported(physboxA, physboxB, mtv)
end