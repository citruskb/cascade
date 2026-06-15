--See https://github.com/majikayogames/physics-tutorial/blob/main/simple_phys.js

if not VGUICol then
	GM.VGUICollisions = {}
	VGUICol = Class:Create(nil, "VGUICol")
end

local meta = FindMetaTable("VGUICol")

function VGUICol:__Create(objA, objB, screenPoint, normal, penetration, fID)
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

	return self
end

function VGUICol:ToString()
	return ""
end

function meta:SetCollisionData(screenPoint, normal, penetration)
	self.screenPoint = screenPoint
	self.normal = normal
	self.penetration = penetration

	-- TODO physbox:GetCenter()
	self.rA = screenPoint - bodyA:GetCenter()
	self.rB = screenPoint - bodyB:GetCenter()

	self.tangent = normal:GetRotate90CW()
end

function meta:Update()
end

function meta:Solve(dt)
	self:SolveContact(dt)
	self:SolveFriction()
end

function meta:SolveContact(dt)
end
function meta:SolveFriction()
end