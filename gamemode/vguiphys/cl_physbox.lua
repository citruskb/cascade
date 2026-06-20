if not VGUIPhysbox then
	VGUIPhysboxCount = 0
	GM.VGUIPhysboxes = {}
	GM.DebugObjects = {}
	VGUIPhysbox = Class:Create(nil, "VGUIPhysbox")
end

local meta = FindMetaTable("VGUIPhysbox")

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

function meta:GetSize() return self.w, self.h end

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
	self.mass = 1
	self.momentOfInertia = 1
	self.w = 0
	self.h = 0
	self.friction = 0.6
	self.restitution = 0.05

	-- Offsets our hitbox point origin to center ourselves inside the item panel.
	self.originCenterOffset = Vector2()

	-- Initializes physics values.
	self.position = parent.position
	self.rotation = parent.rotation
	self:DisablePhysics()

	self.isScreenScaled = parent.isScreenScaled

	GAMEMODE.VGUIPhysboxes[self] = true
	self.isVGUIPhysbox = true

	self.checkStartSleep = 0
	self.isSleeping = false

	return self
end

function VGUIPhysbox:ToString()
	return "[VGUIPhysbox] #" --.. self.id
end

function VGUIPhysbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.VGUIPhysbox then return false end
	return self.id == other.id
end

function meta:AddHitbox(points, noResize)
	local id = #self.hitboxes + 1
	self.hitboxes[id] = VGUIHitbox:Create(self, points, id)

	self:RecalculateSize()
	self:RecalculateMassAndInertia()

	local w, h = self:GetSize()
	self.originCenterOffset = -Vector2(w * 0.5, h * 0.5)
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


function meta:RecalculateSize()
	local aabb = self:GetAABB(true)
	local min, max = aabb.min, aabb.max
	self.w = max.x - min.x
	self.h = max.y - min.y
end

-- TODO better estimates.
-- Possibly calculate these for all hitboxes then add together?
function meta:RecalculateMassAndInertia()
	local w, h = self:GetSize()
	self.mass = self.isStatic and math.HUGE or self.density * w / 100 * h / 100
	self.momentOfInertia = self.isStatic and math.HUGE or (self.mass * (w * w + h * h)) / 12
end

-- The center of our physbox, relative to screenspace.
function meta:GetCenterScreenPoint()
	return self.position
end

-- (0,0) of the grid the hitbox's points draw on.
function meta:GetScreenHitboxPointsOrigin()
	local w, h = self:GetSize()
	return self.position - Vector2(w * 0.5, h * 0.5)
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
		self.parent.position:Set(self.position)
		self.parent.rotation = self.rotation
	end
end

function meta:ApplyImpulse(impulse, screenPoint)
	local r = screenPoint - self:GetCenterScreenPoint()
	local angularImpulse = r:Cross(impulse)

	self:AddVelocity(impulse / self.mass)
	self:AddAngularVelocity(angularImpulse / self.momentOfInertia)
end