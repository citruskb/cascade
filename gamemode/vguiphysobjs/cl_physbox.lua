
if not VGUIPhysbox then
	VGUIPhysboxCount = 0
	GM.VGUIPhysboxes = {}
	GM.DebugObjects = {}
	VGUIPhysbox = Class:Create(nil, "VGUIPhysbox")
end

local meta = FindMetaTable("VGUIPhysbox")

function meta:GetHitboxes() return Rawget(self, "_hitboxes") end
function meta:SetHitboxes(tab) Rawset(self, "_hitboxes", tab) end

function meta:GetOriginCenterOffset() return Rawget(self, "_origincenteroffset") end
function meta:SetOriginCenterOffset(vec2) Rawset(self, "_origincenteroffset", vec2) end

--[[ new ]]
function meta:GetCenter() return self.parent.scpos end

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

function meta:AddDeltaPosition(vec2)
	if not self.isPhysicsEnabled then return end
	self.deltaPosition:DoAdd(vec2)
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
	self.mass = 1
	self.momentOfInertia = 1
	self.friction = 0.6
	self.restitution = 0.05

	-- Offsets our hitbox point origin to center ourselves inside the item panel.
	self.originCenterOffset = Vector2()

	-- Initializes physics values.
	self.deltaPosition = Vector2()
	self.rotation = 0
	self:DisablePhysics()

	GAMEMODE.VGUIPhysboxes[self] = true
	self.isVGUIPhysbox = true

	return self
end

function VGUIPhysbox:ToString() return "[VGUIPhysbox] #" .. self.id end

function VGUIPhysbox:Eq(other)
	if not IsTable(other) then return false end
	if not other.VGUIPhysbox then return false end

	local parent = Rawget(self, "_parent")
	local otherParent = Rawget(other, "_parent")

	return parent == otherParent
end

function meta:AddHitbox(points, noResize)
	local hitboxCount = Rawget(self, "_hitboxcount")
	local id = hitboxCount + 1
	Rawset(self, "_hitboxcount", id)

	local hitbox = VGUIHitbox:Create(self, points, id)
	local hitboxes = Rawget(self, "_hitboxes")
	table.Insert(hitboxes, hitbox)

	GAMEMODE.DebugObjects[Rawget(self, "_parent")] = true

	if noResize then return end

	-- Adjust the parent size to accomodate rotation of our hitboxes around their center point.
	-- But only if our parent is an item.
	local parent = Rawget(self, "_parent")
	if not parent.IsItem then return end

	-- First we find the furthest point from all our hitbox centers.
	local allpoints = self:GetAllHitboxPoints()
	local center = allpoints:GetCenter()
	local fDistsq, fPoint

	local pointsTab = allpoints:GetPoints()
	for i = 1, #pointsTab do
		local point = pointsTab[i]
		local distsq = center:DistanceSqr(point)

		if fDistsq and distsq < fDistsq then continue end
		fDistsq = distsq
		fPoint = point
	end

	-- Now that we know the furthest dist, get the distance.
	local fDist = center:Distance(fPoint)

	-- Next, our size is twice this plus a small buffer
	local siz = (fDist * 2) + 2
	parent:SetSize(siz, siz)

	-- The center of our hitbox points must align with the center of our item.
	-- If we make the assumption that the top left of all our points grids is 0,0 ...
	-- our grid origin is the center minus half the max x and half the max y.
	self:SetOriginCenterOffset(Vector2(-allpoints:GetMaxX() * 0.5, -allpoints:GetMaxY() * 0.5))
	--self:RecalculateInertia()
end

function meta:GetPhysicsPassPointsOrigin()
	local pointsOrigin = self:GetPointsOrigin()
	local partial = self:GetPartialPos()
	return pointsOrigin + partial
end

function meta:GetPointsOrigin()
	-- If our parent isn't an item just assume our hitboxes originate from the item's top left corner.
	local parent = Rawget(self, "_parent")
	if not parent.GetCenterPos then
		local origin = Vector2(parent:GetVPos():Unpack())
		return origin
	end

	local centerOffset = Rawget(self, "_origincenteroffset")
	local pcenter = parent.GetCenterPos and parent:GetCenterPos()
	return pcenter + centerOffset
end

function meta:GetPhysicsPassPointsCenter()
	local pointsCenter = self:GetPointsCenter()
	local partial = self:GetPartialPos()
	return pointsCenter + partial
end

function meta:GetPointsCenter()
	-- If our parent isn't an item just assume our center is the calculated center.
	local parent = Rawget(self, "_parent")
	if not parent.GetCenterPos then
		local w, h = parent:GetSize()
		local x, y = parent:GetVPos():Unpack()
		local center = Vector2(x + w / 2, y + h / 2)
		return center
	end

	return parent:GetCenterPos()
end

function meta:GetAllHitboxPoints()
	local hitboxes = Rawget(self, "_hitboxes")
	local allpoints
	for k, hitbox in pairs(hitboxes) do
		if not allpoints then
			allpoints = hitbox:GetPoints()
			continue
		end

		allpoints = allpoints + hitbox:GetPoints()
	end

	return allpoints
end

-- TODO is this worth caching?
function meta:GetInvMass()
	if Rawget(self, "_static") then return 0 end
	return 1 / Rawget(self, "_mass")
end
function meta:GetInvInertia()
	if Rawget(self, "_static") then return 0 end
	return 1 / Rawget(self, "_inertia")
end

function meta:Remove()
	GAMEMODE.VGUIPhysboxes[self] = nil

	local hitboxes = Rawget(self, "_hitboxes")
	for k, hitbox in pairs(hitboxes) do hitbox:Remove() end

	table.Empty(self)
end

function meta:Step(tim, iterations)
	if not Rawget(self, "_physics") then return end
	self:MarkHitboxesDirty()

	tim = tim / iterations

	local vel = Rawget(self, "_vel")

	-- Move & rotate
	self:AddPartialPos(vel * tim)
	self:AddRad(Rawget(self, "_radvel") * tim)

	-- Gravity.
	-- We apply this after moving to allow our solver a chance to respond to it.
	local _, vy = Rawget(self, "_vel"):Unpack()
	if vy < VGUIPHYS_TERMINAL_VELOCITY then
		self:AddVel(VGUIPHYS_GRAVITY_VEC2 * tim)
	end
end

function meta:UpdateParentVars()
	-- When the partial movements get high enough, move our parent panel.
	-- Done this way because we can't move panels fractional pixels.
	local partial = Rawget(self, "_partialpos")
	local mx, my = partial:Unpack()
	local delta = Vector2(math.Round(mx, 0), math.Round(my, 0))
	if not delta:IsZero() then
		local parent = Rawget(self, "_parent")
		local ivpos = parent:GetVPos()
		ivpos:DoAdd(delta)
		parent:SetPos(ivpos:Unpack())

		-- The movement has been applied.
		-- Therefore, subtract our movement from our partial pos.
		partial:DoSub(delta)
	end
end

function meta:MarkHitboxesDirty()
	for _, hb in pairs(self:GetHitboxes()) do
		hb:SetCacheDirty(true)
	end
end
