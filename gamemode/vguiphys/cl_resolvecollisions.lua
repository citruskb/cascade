local meta = FindMetaTable("v2")
local V2_Cross = meta.Cross
local V2_IsZero = meta.IsZero

meta = FindMetaTable("VGUIPhysbox")
local Phys_AddVel = meta.AddVel
local Phys_AddRadVel = meta.AddRadVel
local Phys_GetInvMass = meta.GetInvMass
local Phys_GetInvInertia = meta.GetInvInertia

if not VGUICollisionsLoaded then
	GM.WarmStartImpulses = {}
	VGUICollisionsLoaded = true
end

local gamemode_Call = gamemode.Call

local function GetRVars(physboxA, physboxB, contactPoint)
	-- First, get our lever points.
	local centerA, centerB = physboxA:GetPhysicsPassPointsCenter(), physboxB:GetPhysicsPassPointsCenter()

	local rA = contactPoint - centerA
	local xa, ya = rA:Unpack()
	local rB = contactPoint - centerB
	local xb, yb = rB:Unpack()

	local rAP = Vector2(-ya, xa)
	local rBP = Vector2(-yb, xb)

	return rA, rB, rAP, rBP
end

local function GetRV(physboxA, physboxB, rAP, rBP)
	-- We need our velocity at these points.
	local vA = Rawget(physboxA, "_vel") + rAP * Rawget(physboxA, "_radvel")
	local vB = Rawget(physboxB, "_vel") + rBP * Rawget(physboxB, "_radvel")

	-- Get the velocity relative to each other along the normal.
	return vB - vA
end

function GM:SettlePhysboxes(data, rv)
	-- Very specific case. 
	-- If velA is close to zero
	-- And velB is close to zero
	-- And the relative velocity is close to zero
	-- Then it means we shouldn't be moving.
	local mtv = Rawget(data, "mtv")
	local y = Rawget(mtv, "y")
	if y > -0.7 and y < 0.7 then return end

	local physboxA = Rawget(data, "physboxA")
	local physboxB = Rawget(data, "physboxB")
	local velA = Rawget(physboxA, "_vel")
	local velB = Rawget(physboxB, "_vel")

	if (physboxA:IsStatic() or physboxA:IsStable()) or (physboxB:IsStatic() or physboxB:IsStable()) then
		if velA:LengthSqr() < VGUIPHYS_SLEEP_VEL and velB:LengthSqr() < VGUIPHYS_SLEEP_VEL then
			local _, _, rAP, rBP = GetRVars(physboxA, physboxB, physboxB:GetPhysicsPassPointsCenter() - physboxA:GetPhysicsPassPointsCenter())
			local rv = GetRV(physboxA, physboxB, rAP, rBP)
			if rv:LengthSqr() < VGUIPHYS_SLEEP_VEL then
				Rawget(physboxA, "_vel"):Zero()
				Rawset(physboxA, "_radvel", 0)
				Rawget(physboxB, "_vel"):Zero()
				Rawset(physboxB, "_radvel", 0)
			end
		end
	end
end

function GM:SeparatePhysboxes(data)
	self:SettlePhysboxes(data)

	local physboxA = Rawget(data, "physboxA")
	local physboxB = Rawget(data, "physboxB")
	local mtv = Rawget(data, "mtv")

	local overlap = Rawget(data, "overlap")
	if overlap <= VGUIPHYS_SLOP then return end

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

local function GetBestAlignment(pointsTab, alignTo)
	local bestP1, bestP2, bestIDX
	local bestAlignment
	for i = 1, #pointsTab do
		local p1 = Rawget(pointsTab, i)
		local p2 = Rawget(pointsTab,(i % #pointsTab) + 1)
		local checkAlign = Vector2(Rawget(p2, "y") - Rawget(p1, "y"), Rawget(p1, "x") - Rawget(p2, "x"))
		local alignment = checkAlign:Dot(alignTo)

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
	local pointsTabA = hbA:GetHBScreenPointsObj():GetPoints()
	local pointsTabB = hbB:GetHBScreenPointsObj():GetPoints()

	local referenceLine, refIDX = GetBestAlignment(pointsTabA, -mtv)
	local incidentLine, incIDX = GetBestAlignment(pointsTabB, mtv)
	local contactPoints = gamemode_Call("VGUIGetContactPoints", referenceLine, incidentLine, mtv)

	return contactPoints, refIDX, incIDX
end

local function ApplyImpulse(physboxA, physboxB, impulse, rA, rB, isFriction)
	if V2_IsZero(impulse) then return impulse end

	Phys_AddVel(physboxA,
		-impulse * Phys_GetInvMass(physboxA))

	Phys_AddRadVel(physboxA,
		V2_Cross(-rA, impulse) * Phys_GetInvInertia(physboxA))

	Phys_AddVel(physboxB,
		impulse * Phys_GetInvMass(physboxB))

	Phys_AddRadVel(physboxB,
		V2_Cross(rB, impulse) * Phys_GetInvInertia(physboxB))

	return impulse
end

local function ResolveWarmStart(physboxA, physboxB, contactPoint, normal, tangent, rv, rA, rB, fID)
	-- Get the velocity relative to each other along the normal.
	-- Only apply impulse if objects aren't already moving apart.
	local rnv = rv:Dot(normal)
	local warmJ
	if rnv <= 0 then
		warmJ = gamemode.Call("VGUIGetWarmJ", fID) or 0
		ApplyImpulse(physboxA, physboxB, warmJ * normal, rA, rB)
	end

	local warmJT
	if tangent then
		warmJT = gamemode.Call("VGUIGetWarmJT", fID) or 0
		ApplyImpulse(physboxA, physboxB, warmJT * tangent, rA, rB, true)
	end

	return (warmJ or 0), (warmJT or 0)
end

local function ResolveVelocity(warmJ, physboxA, physboxB, mtv, rv, rAP, rBP, contactPoint, div, i)
	-- Get the velocity relative to each other along the normal.
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


	-- For warmstarting we need to get the difference between our warmstart and apply that as our impulse instead.

	j = warmJ == 0 and j or math.Max(warmJ - j, 0)

	local impulse = j * mtv


	return impulse, j
end

local function ResolveFriction(warmJT, physboxA, physboxB, mtv, tangent, rv, rAP, rBP, contactPoint, div)
	if not tangent then return end

	local rnv = rv:Dot(mtv)
	if rnv > 0 then return end -- Objects already moving apart.

	-- Calculate the impulse to apply.
	local rAPDotT, rBPDotT = rAP:Dot(tangent), rBP:Dot(tangent)
	local invMassA, invMassB = physboxA:GetInvMass(), physboxB:GetInvMass()
	local invInertiaA, invInertiaB = physboxA:GetInvInertia(), physboxB:GetInvInertia()
	local denom = invMassA + invMassB + rAPDotT * rAPDotT * invInertiaA + rBPDotT * rBPDotT * invInertiaB

	local jT = -rv:Dot(tangent)
	jT = jT / denom
	jT = jT / div

	-- For warmstarting we need to get the difference between our warmstart and apply that as our impulse instead.
	jT = warmJT == 0 and jT or math.Min(warmJT - jT, 0)

	local frictionImpulse = jT * tangent

	return frictionImpulse, jT
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

	if #contactPoints == 2 then
		local stableA, stableB = physboxA:IsStable(), physboxB:IsStable()
		physboxB:SetStable(physboxA:IsStatic() or stableA)
		physboxA:SetStable(physboxB:IsStatic() or stableB)
	else
		--physboxB:SetStable(false)
		--physboxA:SetStable(false)
	end

	-- Cache some values we will be going back to repeatedly.
	local rAs = {}
	local rBs = {}
	local rAPs = {}
	local rBPs = {}
	local rvs = {}
	for i = 1, #contactPoints do
		rAs[i], rBs[i], rAPs[i], rBPs[i] = GetRVars(physboxA, physboxB, contactPoints[i])
		rvs[i] = GetRV(physboxA, physboxB, rAPs[i], rBPs[i])
	end

	-- We need the tangents for warmstarting and other calculations.
	-- The normal for all contactPoints are the same -- the mtv.
	local tangents = {}
	for i = 1, #contactPoints do
		local rv = rvs[i]
		local tangent = rv - rv:Dot(mtv) * mtv
		if tangent:IsEqualTol(VECTOR2_ZERO, 0.00001) then continue end
		tangent:Normalize()
		tangents[i] = tangent
	end


	-- First, warmstarting.
	-- We check if this contact point is persistent frame-to-frame.
	-- If it is, we apply a portion of the old accumulated solution as our starting point here
	-- This is done for both our typical impulses and friction.
	-- Helps improve stability.

	local fIDList = Rawget(manifold, "fIDList")
	local warmstartJ = {}
	local warmstartJT = {}
	local didWarmstart = false
	for i = 1, #contactPoints do
		local fID = gamemode.Call("GetFeatureID", hbA, hbB, refIDX, incIDX, i)
		table.Insert(fIDList, fID)

		-- If our contact point isn't persistent, reset our contact data. No warm start.
		local contactPoint = contactPoints[i]
		if not gamemode.Call("VGUIIsPersistentContact", fID, contactPoint) then
			warmstartJ[i], warmstartJT[i] = 0, 0
			gamemode.Call("VGUIInitWarmstartData", fID, contactPoint, warmstartJ[i], warmstartJT[i])
			continue
		end

		-- if persistent, apply stored impulses, and remember that we are warmstarting.
		didWarmstart = true
		warmstartJ[i], warmstartJT[i] = ResolveWarmStart(physboxA, physboxB, contactPoint, mtv, tangents[i], rvs[i], rAs[i], rBs[i], fID)
	end

	-- We need to recalculate our rvs if we changed our velocity from warmstarting.
	if didWarmstart then
		for i = 1, #contactPoints do
			rvs[i] = GetRV(physboxA, physboxB, rAPs[i], rBPs[i])
		end
	end

	-- Get our velocity impulses.
	local impulses = {}
	local js = {}
	for i = 1, #contactPoints do
		local impulse, j = ResolveVelocity(warmstartJ[i], physboxA, physboxB, mtv, rvs[i], rAPs[i], rBPs[i], contactPoints[i], #contactPoints, i)
		if not impulse then continue end

		impulses[i] = impulse
		js[i] = j
	end

	-- Apply our velocity impulses.
	for i = 1, #contactPoints do
		if not impulses[i] then continue end
		impulses[i] = ApplyImpulse(physboxA, physboxB, impulses[i], rAs[i], rBs[i])
	end

	-- Get our friction impulses.
	local frictionImpulses = {}
	local jTs = {}
	for i = 1, #contactPoints do
		if not js[i] then continue end

		local frictionImpulse, jT = ResolveFriction(warmstartJT[i], physboxA, physboxB, mtv, tangents[i], rvs[i], rAPs[i], rBPs[i], contactPoints[i], #contactPoints)
		if not frictionImpulse then continue end

		frictionImpulses[i] = frictionImpulse
		jTs[i] = jT
	end

	-- Apply our friction impulses.
	for i = 1, #contactPoints do
		if not frictionImpulses[i] then continue end
		frictionImpulses[i] = ApplyImpulse(physboxA, physboxB, frictionImpulses[i], rAs[i], rBs[i], true)
	end

	-- Update our warmstart values.
	-- But only if we aren't frozen.
	for i = 1, #contactPoints do
		gamemode.Call("VGUIWarmstartLambda", fIDList[i], js[i], jTs[i], contactPoints[i])
	end

	self:SettlePhysboxes(manifold)
end