local gamemode_Call = gamemode.Call

function GM:SeparatePhysboxes(data)
	local overlap = Rawget(data, "overlap")
	if overlap <= VGUIPHYS_SLOP then return end

	local physboxA = Rawget(data, "physboxA")
	local physboxB = Rawget(data, "physboxB")
	local mtv = Rawget(data, "mtv")

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
	local bestP1, bestP2
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
	end
	return Points({bestP1, bestP2})
end

function GM:GetCollisionPoints(data)
	local hbA = Rawget(data, "hbA")
	local hbB = Rawget(data, "hbB")
	local mtv = Rawget(data, "mtv")
	local pointsTabA = hbA:GetPhysicsPassScreenPoints():GetPoints()
	local pointsTabB = hbB:GetPhysicsPassScreenPoints():GetPoints()

	local referenceLine = GetBestAlignment(pointsTabA, -mtv)
	local incidentLine = GetBestAlignment(pointsTabB, mtv)
	local contactPoints = gamemode_Call("VGUIGetContactPoints", referenceLine, incidentLine, mtv)

	return contactPoints
end

local function SimpleResolution(physboxA, physboxB, mtv)
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

	physboxA:AddVel(-impulse * physboxA:GetInvMass())
	physboxB:AddVel(impulse * physboxB:GetInvMass())
end

function GM:ResolveCollision(manifold)
	local physboxA = Rawget(manifold, "physboxA")
	local physboxB = Rawget(manifold, "physboxB")
	local mtv = Rawget(manifold, "mtv")
	local contactPoints = Rawget(manifold, "contactPoints")

	SimpleResolution(physboxA, physboxB, mtv)

	--[[

	-- We sum up all our impulses over the contact points and apply them once at the end.
	local impulses = {}
	local rAs = {}
	local rBs = {}
	for i = 1, #contactPoints do
		local impulse, rA, rB = ResolveVelocity(physboxA, physboxB, mtv, contactPoints[i], #contactPoints)
		if not impulse then continue end

		impulses[i] = impulse
		rAs[i] = rA
		rBs[i] = rB
	end

	for i = 1, #contactPoints do
		if not impulses[i] then continue end
		ApplyImpulse(physboxA, physboxB, impulses[i], rAs[i], rBs[i])
	end
	]]
end