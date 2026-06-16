if not VGUICollisionConstraint then
	GM.VGUICollisionConstraints = {}
	VGUICollisionConstraint = Class:Create(nil, "VGUICollisionConstraint")
end

local meta = FindMetaTable("VGUICollisionConstraint")

function VGUICollisionConstraint:__Create(objA, objB, screenPoint, normal, penetration, fID)
	self.bodyA = objA
	self.bodyB = objB
	self.fID = fID -- Contact persistence -> see cl_warmstarting.lua
	self.isReused = false -- Track if this contact was reused from last physics step
	self.friction = math.Sqrt(objA.friction * objB.friction)
	self.restitution = math.Sqrt(objA.restitution * objB.restitution)
	self.accuNormalLambda = 0
	self.accuFrictionLambda = 0

	local objAStatic, objBStatic = objA:IsStatic(), objB:IsStatic()
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

	GAMEMODE.VGUICollisionConstraints[fID] = self

	return self
end

function VGUICollisionConstraint:ToString() return "[VGUICol] - " .. self.fID end

function meta:SetCollisionData(screenPoint, normal, penetration)
	self.screenPoint = screenPoint
	self.normal = normal
	self.penetration = penetration

	-- TODO physbox:GetCenter()
	self.rA = screenPoint - bodyA:GetCenter()
	self.rB = screenPoint - bodyB:GetCenter()

	self.tangent = normal:GetRotate90CW()
end

function meta:ApplyImpulses(impulse)
	self.bodyA:AddVelocity(-impulse * self.invMassA)
	self.bodyA:AddAngularVelocity(-self.invIA * self.rA:Cross(impulse))
	self.bodyB:AddVelocity(impulse * self.invMassB)
	self.bodyB:AddAngularVelocity(self.invIB * self.rB:Cross(impulse))
end

function meta:Update()
	self.rA = self.screenPoint - self.BodyA:GetCenter()
	self.rB = self.screenPoint - self.BodyB:GetCenter()

	local objAStatic, objBStatic = objA:IsStatic(), objB:IsStatic()
	self.invMassA = objAStatic and 0 or 1 / objA.mass
	self.invMassB = objBStatic and 0 or 1 / objB.mass
	self.invIA = objAStatic and 0 or 1 / objA.momentOfInertia
	self.invIB = objBStatic and 0 or 1 / objB.momentOfInertia

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
	local oldAccum = self.accumulatedNormalLambda
	self.accumulatedNormalLambda = math.Max(oldAccum + lambda, 0)
	lambda = self.accumulatedNormalLambda - oldAccum

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
	local maxFriction = self.friction * self.accumulatedNormalLambda

	-- Clamp force between -maxFriction and maxFriction
	local oldAccum = self.accumulatedFrictionLambda
	self.accumulatedFrictionLambda = math.Clamp(oldAccum + lambda, -maxFriction, maxFriction)
	lambda = self.accumulatedFrictionLambda - oldAccum

	local frictionImpulse = self.tangent * lambda
	self.bodyA:ApplyImpulse(-frictionImpulse, self.screenPoint)
	self.bodyB:ApplyImpulse(frictionImpulse, self.screenPoint)
end

function meta:ApplyRestitution()
	-- We only apply restitution if:
	-- 1. Theres a restitution coefficient > 0
	-- 2. The contact point isn't persistent (isReused == false)
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