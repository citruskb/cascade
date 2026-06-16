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
	self.relativeVelocity = normal:Dot(rv)

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

function meta:SolveContact(dt)
end
function meta:SolveFriction()
end

function meta:ApplyRestitution()

end

function meta:Remove()
	GAMEMODE.VGUICollisionConstraints[self.fID] = nil
	table.Empty(self)
end