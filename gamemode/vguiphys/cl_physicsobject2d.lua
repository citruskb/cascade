local math_Ang = math.Ang
local math_Cos = math.Cos
local math_Sin = math.Sin
local math_IsNearlyEqual = math.IsNearlyEqual

--	//////////////////////
--	[[	PhysicsObject2D	]]
--	//////////////////////

if not PhysicsObject2D then
	countPhysicsObjects2D = 0
	GM.PhysicsObjects2D = {}
	PhysicsObject2D = Class:Create(nil, "PhysicsObject2D")
end

local meta = FindMetaTable("PhysicsObject2D")

function PhysicsObject2D:__Create(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
	self.position = position
	self.rotation = rotation
	self.itemDataID = itemDataID

	self:InitPhysbox(velocity, angularVelocity, isStatic)

	-- We don't use the size of the table because these objects can be removed.
	countPhysicsObjects2D = countPhysicsObjects2D + 1
	self.id = countPhysicsObjects2D
	GAMEMODE.PhysicsObjects2D[self.id] = self

	self.isPhysicsObject2D = true

	return self
end

function PhysicsObject2D:ToString() return "PhysicsObject2D #" .. self.id end
function PhysicsObject2D:Eq(other)
	if not IsTable(other) then return false end
	if not other.isPhysicsObject2D then return false end
	return self.id == other.id
end

function meta:InitPhysbox(velocity, angularVelocity, isStatic)
	local physbox = VGUIPhysbox:Create(self)

	physbox.isStatic = isStatic or physbox.isStatic
	if not physbox.isStatic then
		physbox.velocity = velocity or physbox.velocity
		physbox.angularVelocity = angularVelocity or physbox.angularVelocity
	end

	self:AddHitboxesToPhysbox()
end

function meta:GetItemData() return self.itemDataID and GAMEMODE[self.itemDataID] end

function meta:AddHitboxesToPhysbox()
	if not self.itemData then return end
	if not self.itemData.hitboxPoints then return end

	local screenscale = BetterScreenScale()

	local hitboxPoints = self.itemData.hitboxPoints
	for i = 1, #hitboxPoints do
		local pointsTab = Points(hitboxPoints[i]):GetPoints() -- TODO maybe add a shortcut for this in the points obj.
		local scaledPointsTab = {}
		for j = 1, #pointsTab do
			scaledPointsTab[j] = pointsTab[i] * screenscale
		end

		local scaledPointsObj = Points(scaledPointsTab)
		self.physbox:AddHitbox(scaledPointsObj)
	end
end

function meta:EnablePhysics() self.physbox:EnablePhysics() end
function meta:DisablePhysics() self.physbox:DisablePhysics() end

function meta:Remove()
	GAMEMODE.PhysicsObjects2D[self.id] = nil
	table.Empty(self)
end

function GM:NewPhysicsObject2D(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
	return PhysicsObject2D:Create(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
end

--	//////////////////////////
--	[[	End PhysicsObject2D	]]
--	//////////////////////////

















































--	//////////////
--	[[	Physbox	]]
--	//////////////

if not VGUIPhysbox then
	VGUIPhysboxCount = 0
	GM.VGUIPhysboxes = {}
	GM.DebugObjects = {}
	VGUIPhysbox = Class:Create(nil, "VGUIPhysbox")
end

meta = FindMetaTable("VGUIPhysbox")

function meta:EnablePhysics() self.isPhysicsEnabled = true end
function meta:DisablePhysics()
	-- We update our position by updating our parent's position.
	-- We accumulate changes via. deltaPosition then apply the net change when needed.
	-- Done this way mainly because absolute VGUI Panel positions are always whole numbers, so fractional changes are lost.
	self.velocity = Vector2()
	self.angularVelocity = 0

	self.isPhysicsEnabled = false
end

function meta:AddVelocity(vec2)
	if not self.isPhysicsEnabled then return end
	self.velocity:DoAdd(vec2)
end

function meta:AddAngularVelocity(num)
	if not self.isPhysicsEnabled then return end
	self.angularVelocity = self.angularVelocity + num
end

function meta:AddPosition(vec2)
	if not self.isPhysicsEnabled then return end
	self.position:DoAdd(vec2)
end

function meta:AddRotation(num)
	if not self.isPhysicsEnabled then return end
	self.rotation = self.rotation + num
end

function VGUIPhysbox:__Create(parent)
	-- Makes sure we have a unique ID for contact persistence.
	VGUIPhysboxCount = VGUIPhysboxCount + 1
	self.id = VGUIPhysboxCount

	self.parent = parent

	-- Init a bunch of dummy values.
	-- To be set up a better way later?
	self.hitboxes = {}
	self.isStatic = false
	self.density = 1
	self.mass = 10
	self.momentOfInertia = 1
	self.friction = 0.6
	self.restitution = 0.05

	-- Offsets our hitbox point origin to center ourselves inside the item panel.
	self.originCenterOffset = Vector2()

	-- Initializes physics values.
	self.position = parent.position
	self.rotation = parent.rotation
	self:DisablePhysics()

	GAMEMODE.VGUIPhysboxes[self] = true
	self.isVGUIPhysbox = true

	self.checkStartSleep = 0
	self.isSleeping = false

	return self
end

function VGUIPhysbox:ToString() return "[VGUIPhysbox] #" .. self.id end

function VGUIPhysbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.VGUIPhysbox then return false end
	return self.id == other.id
end

function meta:AddHitbox(points, noResize)
	local id = #self.hitboxes + 1
	self.hitboxes[id] = VGUIHitbox:Create(self, points, id)

	local parent = self.parent
	GAMEMODE.DebugObjects[parent] = true

	if noResize then return end

	-- First we find the furthest point from all our hitbox centers.
	local allpoints = self:GetAllHitboxPoints()
	local center = allpoints:GetCenter()
	local fDistsq, fPoint

	local pointsTab = allpoints:GetPoints()
	for i = 1, #pointsTab do
		local point = pointsTab[i]
		local distsq = center:DistanceSqr(point) -- DistanceSqr is faster.

		if fDistsq and distsq < fDistsq then continue end
		fDistsq = distsq
		fPoint = point
	end

	-- Now that we know the furthest dist, get the actual distance.
	local fDist = center:Distance(fPoint)

	-- Next, our size is twice this plus a small buffer
	-- Setting our parent size also sets our "size"
	local siz = (fDist * 2) + 2
	parent:SetSize(siz, siz)

	self:RecalculateMassAndInertia()

	-- The center of our hitbox points must align with the center of our item.
	-- If we make the assumption that the top left of all our points grids is 0,0 ...
	-- our grid origin is the center minus half the max x and half the max y.
	self.originCenterOffset = Vector2(-allpoints:GetMaxX() * 0.5, -allpoints:GetMaxY() * 0.5)
end

function meta:GetAllHitboxPoints()
	local allpoints
	for _, hitbox in pairs(self.hitboxes) do
		if not allpoints then
			allpoints = hitbox.pointsObj
			continue
		end

		allpoints = allpoints + hitbox.pointsObj
	end

	return allpoints
end

function meta:GetAABB(raw)
	local aabb = VGUIAABB:Create(Vector2(math.HUGE, math.HUGE), -Vector2(math.HUGE, math.HUGE))
	for _, hitbox in pairs(self.hitboxes) do
		aabb:Expand(raw and hitbox.pointsObj or hitbox:GetHBScreenPointsObj())
	end
	return aabb
end

-- TODO better estimates.
-- Possibly calculate these for all hitboxes then add together?
function meta:RecalculateMassAndInertia()
	local w, h = self.parent:GetSize()
	self.mass = self.isStatic and math.HUGE or self.density * w / 100 * h / 100
	self.momentOfInertia = self.isStatic and math.HUGE or (self.mass * (w * w + h * h)) / 12
end

-- The center of our physbox, relative to screenspace.
function meta:GetCenterScreenPoint()
	local w, h
	if self.parent.isItem then
		w, h = self.parent:GetSize()
	else
		local aabb = self:GetAABB(true)
		local min, max = aabb.min, aabb.max
		w, h = max.x - min.x, max.y - min.y
	end

	return self.position + Vector2(w * 0.5, h * 0.5)
end

-- (0,0) of the grid the hitbox's points draw on.
function meta:GetScreenHitboxPointsOrigin()
	if self.parent.isItem then
		return self:GetCenterScreenPoint() + self.originCenterOffset
	else
		return self.position
	end
end

-- For now, we need to handle what happens if our parent panel gets removed.
function meta:Remove()
	GAMEMODE.VGUIPhysboxes[self] = nil

	for _, hitbox in pairs(self.hitboxes) do hitbox:Remove() end

	table.Empty(self)
end

function meta:UpdateParentVars()
end

-- TODO may need to recode a bit
function meta:Step(dt)
	if not self.isPhysicsEnabled then return end

	if self.isSleeping then
		self.velocity:Zero()
		self.angularVelocity = 0
	else
		-- Move & rotate
		self:AddPosition(self.velocity * dt)
		self:AddRotation(self.angularVelocity * dt)

		-- Update our parent's position based on our's
		self.parent:SetPos(self.position:Unpack())
	end

	-- Rotate our parent's model to match us.
	if IsValid(self.parent.ModPan) then
		self.parent.ModPan.rotation = -self.rotation
	end
end

function meta:ApplyImpulse(impulse, screenPoint)
	local r = screenPoint - self:GetCenterScreenPoint()
	local angularImpulse = r:Cross(impulse)

	self:AddVelocity(impulse / self.mass)
	self:AddAngularVelocity(angularImpulse / self.momentOfInertia)
end
--	/////////////////
--	[[ end Physbox ]]
--	/////////////////

















































--	//////////////////
--	[[	VGUIHitbox	]]
--	//////////////////
if not VGUIHitbox then
	GM.VGUIHitboxes = {}
	VGUIHitbox = Class:Create(nil, "VGUIHitbox")
end

meta = FindMetaTable("VGUIHitbox")

function VGUIHitbox:__Create(physbox, pointsObj, id)
	-- This coupled with the physbox's ID makes a completely unique pairing representing this hitbox for contact persistence.
	self.id = id

	self.physbox = physbox

	-- The local configuration of our points
	self.pointsObj = pointsObj

	-- The actual screen location of our points, accounting for rotation, physbox position, etc
	-- This is initialized here but recalculated when needed.
	self.screenPointsObj = pointsObj:Copy()
	self.screenPointsObjDirty = true

	GAMEMODE.VGUIHitboxes[self] = true

	self.isVGUIHitbox = true

	return self
end

function VGUIHitbox:ToString() return "A [VGUIHitbox] of " .. ToString(self.physbox) end

function VGUIHitbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.isVGUIHitbox then return false end
	if self.physbox ~= other.physbox then return false end
	return self.id == other.id
end

function meta:GetScreenOriginPoint() return self.physbox:GetScreenHitboxPointsOrigin() end

function meta:TransformPointsAroundOrigin(inputPoints, origin, pivot)
	local ret = inputPoints

	inputPoints = inputPoints:GetPoints()
	local points = self.pointsObj:GetPoints()

	-- Used for rotation
	local rad = self.physbox.rotation
	local ang = math_Ang(rad)
	local cos, sin
	local angZero = math_IsNearlyEqual(ang, 0)
	if not angZero then
		cos, sin = math_Cos(rad), math_Sin(rad)
	end

	local ox, oy = origin:Unpack()
	local pivx, pivy = pivot:Unpack()
	for i = 1, #inputPoints do
		local inputPoint = inputPoints[i]
		local px, py = points[i]:Unpack()
		local tx, ty = px + ox, py + oy

		if angZero then
			inputPoint:SetUnpacked(tx, ty)
		else
			local rx = tx - pivx
			local ry = ty - pivy
			inputPoint:SetUnpacked(
				pivx + cos * rx - sin * ry,
				pivy + sin * rx + cos * ry
			)
		end
	end

	return ret
end

-- Done this way to save memory/GC. We don't want to make literally thousands of new Vector2/Point objects per frame.
-- Returns the position of our points on the screen.
-- We also want to cache this per physics pass.
function meta:GetHBScreenPointsObj()
	if self.screenPointsObjDirty then
		local physpassScreenpoints = self.screenPointsObj
		local physpassOrigin = self.physbox:GetScreenHitboxPointsOrigin()
		local physpassPivot = self.physbox:GetCenterScreenPoint()

		self:TransformPointsAroundOrigin(physpassScreenpoints, physpassOrigin, physpassPivot)
		self.screenPointsObjDirty = false
	end

	return self.screenPointsObj
end

function meta:Remove()
	GAMEMODE.VGUIHitboxes[self] = nil
	table.Empty(self)
end

--	//////////////////////
--	[[	End VGUIHitbox	]]
--	//////////////////////

















































--	//////////////////////////////
--	[[	VGUICollisionConstraint	]]
--	//////////////////////////////

if not VGUICollisionConstraint then
	VGUICollisionConstraint = Class:Create(nil, "VGUICollisionConstraint")
end

meta = FindMetaTable("VGUICollisionConstraint")

function VGUICollisionConstraint:__Create(objA, objB, screenPoint, normal, penetration, fID)
	self.bodyA = objA
	self.bodyB = objB
	self.fID = fID -- Contact persistence -> see cl_warmstarting.lua
	self.isReused = false -- Track if this contact was reused from last physics step
	self.friction = math.Sqrt(objA.friction * objB.friction)
	self.restitution = math.Sqrt(objA.restitution * objB.restitution)
	self.accuNormalLambda = 0
	self.accuFrictionLambda = 0
	self.lastNormalLambda = 0

	local objAStatic, objBStatic = objA.isStatic, objB.isStatic
	self.invMassA = objAStatic and 0 or 1 / objA.mass
	self.invMassB = objBStatic and 0 or 1 / objB.mass
	self.invIA = objAStatic and 0 or 1 / objA.momentOfInertia
	self.invIB = objBStatic and 0 or 1 / objB.momentOfInertia

	-- Used to initialize or update geometric/contact derived properties
	self:SetCollisionData(screenPoint, normal, penetration)

	-- Store intial relative vel for restitution
	-- (Needs to happen prior to any solving)
	local vA = self.bodyA.velocity + (self.rA:CrossS(self.bodyA.angularVelocity))
	local vB = self.bodyB.velocity + (self.rB:CrossS(self.bodyB.angularVelocity))
	local rv = vB - vA
	self.relativeVelocity = normal:Dot(rv)

	return self
end

function VGUICollisionConstraint:ToString() return "[VGUICol] - " .. self.fID end

function meta:SetCollisionData(screenPoint, normal, penetration)
	self.screenPoint = screenPoint
	self.normal = normal
	self.penetration = penetration

	self.rA = screenPoint - self.bodyA:GetCenterScreenPoint()
	self.rB = screenPoint - self.bodyB:GetCenterScreenPoint()

	self.tangent = self.normal:GetRotate90CW()
end

function meta:ApplyImpulses(impulse)
	self.bodyA:AddVelocity(-impulse * self.invMassA)
	self.bodyA:AddAngularVelocity(-self.invIA * self.rA:Cross(impulse))
	self.bodyB:AddVelocity(impulse * self.invMassB)
	self.bodyB:AddAngularVelocity(self.invIB * self.rB:Cross(impulse))
end

function meta:Update()
	self.rA = self.screenPoint - self.bodyA:GetCenterScreenPoint()
	self.rB = self.screenPoint - self.bodyB:GetCenterScreenPoint()

	local objAStatic, objBStatic = self.bodyA.isStatic, self.bodyB.isStatic
	self.invMassA = objAStatic and 0 or 1 / self.bodyA.mass
	self.invMassB = objBStatic and 0 or 1 / self.bodyB.mass
	self.invIA = objAStatic and 0 or 1 / self.bodyA.momentOfInertia
	self.invIB = objBStatic and 0 or 1 / self.bodyB.momentOfInertia

	-- Store relative velocity before warm starting, for restitution.
	local vA = self.bodyA.velocity + (self.rA:CrossS(self.bodyA.angularVelocity))
	local vB = self.bodyB.velocity + (self.rB:CrossS(self.bodyB.angularVelocity))
	local rv = vB - vA
	self.relativeVelocity = self.normal:Dot(rv)

	-- Warmstarting -- apply the accumulated point impulse from the previous frame.
	local normalImpulse = self.normal * self.accuNormalLambda
	local frictionImpulse = self.tangent * self.accuFrictionLambda
	local totalImpulse = normalImpulse + frictionImpulse

	self:ApplyImpulses(totalImpulse)
end

function meta:Asleep() return (self.bodyA.isSleeping or self.bodyA.isStatic) and (self.bodyB.isSleeping or self.bodyB.isStatic) end
function meta:SleepBodies()
	self.bodyA.isSleeping = true
	self.bodyB.isSleeping = true
end
function meta:WakeBodies()
	self.bodyA.isSleeping = false
	self.bodyB.isSleeping = false
end

function meta:Solve(dt)
	self:SolveContact(dt)
	self:SolveFriction()
end

local function GetSoftConstraintParams(hertz, dampingRatio, dt)
	if hertz == 0 then
		return {biasRate = 0, massScale = 0, impulseScale = 0}
	end
	local omega = 2 * math.PI * hertz
	local a1 = 2 * dampingRatio + dt * omega
	local a2 = dt * omega * a1
	local a3 = 1 / (1 + a2)

	return {biasRate = omega / a1, massScale = a2 * a3, impulseScale = a3}
end
function meta:SolveContact(dt)
	local vA = self.bodyA.velocity + (self.rA:CrossS(self.bodyA.angularVelocity))
	local vB = self.bodyB.velocity + (self.rB:CrossS(self.bodyB.angularVelocity))
	local rv = vB - vA
	local Cdot = self.normal:Dot(rv)

	local rnA = self.rA:Cross(self.normal)
	local rnB = self.rB:Cross(self.normal)
	local effectiveMass = self.invMassA + self.invMassB + rnA * rnA * self.invIA + rnB * rnB * self.invIB
	if effectiveMass < 0.0000001 then return end -- Prevent divide by zero.

	-- using "soft" constaint settings
	local allowedPenetration = VGUIPHYS_SLOP_LINEAR
	local velocityBias = 0
	local massScale = 1
	local impulseScale = 0

	local maxHertz = 0.25 / dt
	local hz = math.Min(VGUIPHYS_SOFT_HERTZ, maxHertz)
	local soft = GetSoftConstraintParams(hz, VGUIPHYS_SOFT_DAMPINGRATIO, dt)
	local separation = math.Min(0, -self.penetration + allowedPenetration)
	velocityBias = math.Max(soft.biasRate * separation, -VGUIPHYS_SOFT_CONTACTSPEED)
	massScale = soft.massScale
	impulseScale = soft.impulseScale

	-- Compute normal impulse with bias included
	local lambda = -(massScale * Cdot + velocityBias) / effectiveMass
	lambda = lambda - impulseScale * self.accuNormalLambda / effectiveMass

	-- Clamp accumulated impulse
	local oldAccum = self.accuNormalLambda
	self.accuNormalLambda = math.Max(oldAccum + lambda, 0)
	lambda = self.accuNormalLambda - oldAccum

	self.lastNormalLambda = lambda
	if lambda == 0 then return end

	local impulse = self.normal * lambda
	self.bodyA:ApplyImpulse(-impulse, self.screenPoint)
	self.bodyB:ApplyImpulse(impulse, self.screenPoint)
end

function meta:SolveFriction()
	if self.friction <= 0 then return end

	local vA = self.bodyA.velocity + (self.rA:CrossS(self.bodyA.angularVelocity))
	local vB = self.bodyB.velocity + (self.rB:CrossS(self.bodyB.angularVelocity))
	local relVel = vB - vA
	local Cdot = self.tangent:Dot(relVel)

	local rtA = self.rA:Cross(self.tangent)
	local rtB = self.rB:Cross(self.tangent)
	local effectiveMassTangent = self.invMassA + self.invMassB + rtA * rtA * self.invIA + rtB * rtB * self.invIB
	if effectiveMassTangent < 0.000001 then return end

	local lambda = -Cdot / effectiveMassTangent

	-- Maximum friction impulse according to Coulumb's law
	local maxFriction = self.friction * self.accuNormalLambda

	-- Clamp force between -maxFriction and maxFriction
	local oldAccum = self.accuFrictionLambda
	self.accuFrictionLambda = math.Clamp(oldAccum + lambda, -maxFriction, maxFriction)
	lambda = self.accuFrictionLambda - oldAccum

	local frictionImpulse = self.tangent * lambda
	self.bodyA:ApplyImpulse(-frictionImpulse, self.screenPoint)
	self.bodyB:ApplyImpulse(frictionImpulse, self.screenPoint)
end

function meta:ApplyRestitution()
	-- We only apply restitution if:
	-- 1. Theres a restitution coefficient > 0
	-- 2. The contact point isn't persistent
	-- 3. The initial relative velocity was approaching fast enough
	if self.isReused or self.restitution == 0 then return end

	local restitutionThreshold = 1
	if self.relativeVelocity < -restitutionThreshold then return end

	local rnA = self.rA:Cross(self.normal)
	local rnB = self.rB:Cross(self.normal)
	local effectiveMass = self.invMassA + self.invMassB + rnA * rnA * self.invIA + rnB * rnB * self.invIB
	if effectiveMass < 0.000001 then return end

	local vA = self.bodyA.velocity + self.rA:CrossS(self.bodyA.angularVelocity)
	local vB = self.bodyB.velocity + self.rB:CrossS(self.bodyB.angularVelocity)
	local relVel = vB - vA
	local vn = self.normal:Dot(relVel)

	-- Compute restitution impulse!
	local impulse = -(vn + self.restitution * self.relativeVelocity) / effectiveMass

	-- Make sure impulse is positive only! (objects separating)
	if impulse <= 0 then return end
	local restitutionImpulse = self.normal * impulse
	self.bodyA:ApplyImpulse(-restitutionImpulse, self.screenPoint)
	self.bodyB:ApplyImpulse(restitutionImpulse, self.screenPoint)
end

function meta:Remove()
	GAMEMODE.VGUICollisionConstraints[self.fID] = nil
	table.Empty(self)
end

--	//////////////////////////////////
--	[[	End VGUICollisionConstraint	]]
--	//////////////////////////////////

















































--	//////////////////
--	[[	VGUIAABB	]]
--	//////////////////

if not VGUIAABB then
	VGUIAABB = Class:Create(nil, "VGUIAABB")
end

meta = FindMetaTable("VGUIAABB")

function VGUIAABB:__Create(min, max)
	self.min = min
	self.max = max
	return self
end

function meta:Expand(pointsObj)
	local points = pointsObj:GetPoints()
	for i = 1, #points do
		local point = points[i]
		self.min = self.min:GetMin(point)
		self.max = self.max:GetMax(point)
	end
end

function meta:Overlaps(other)
	return
		self.min.x <= other.max.x and
		self.max.x >= other.min.x and
		self.min.y <= other.max.y and
		self.max.y >= other.min.y
end

--	//////////////////////
--	[[	End VGUIAABB	]]
--	//////////////////////