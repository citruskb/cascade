
if not VGUIPhysbox then
	VGUIPhysboxCount = 0
	GM.VGUIPhysboxes = {}
	GM.DebugObjects = {}
	VGUIPhysbox = Class:Create(nil, "VGUIPhysbox")
end

local meta = FindMetaTable("VGUIPhysbox")

function meta:GetID() return Rawget(self, "_id") end
function meta:SetID(val) Rawset(self, "_id", val) end

function meta:GetHitboxCount() return Rawget(self, "_hitboxcount") end
function meta:SetHitboxCount(val) Rawset(self, "_hitboxcount", val) end

function meta:GetParent() return Rawget(self, "_parent") end
function meta:SetParent(pan) Rawset(self, "_parent", pan) end

function meta:GetPartialPos() return Rawget(self, "_partialpos") end
function meta:SetPartialPos(vec2) Rawget(self, "_partialpos"):Set(vec2) end
function meta:AddPartialPos(vec2) Rawget(self, "_partialpos"):DoAdd(vec2) end

function meta:GetVel() return Rawget(self, "_vel") end
function meta:SetVel(vec2) Rawget(self, "_vel"):Set(vec2) end
function meta:AddVel(vec2)
	if not Rawget(self, "_physics") then return end
	Rawget(self, "_vel"):DoAdd(vec2)
end

function meta:GetRad() return Rawget(self, "_rad") end
function meta:SetRad(num) Rawset(self, "_rad", num) end
function meta:AddRad(num) Rawset(self, "_rad", Rawget(self, "_rad") + num) end

function meta:GetRadVel() return Rawget(self, "_radvel") end
function meta:SetRadVel(num) Rawset(self, "_radvel", num) end
function meta:AddRadVel(num)
	if not Rawget(self, "_physics") then return end
	Rawset(self, "_radvel", Rawget(self, "_radvel") + num)
end

function meta:GetDesiredTrans() return Rawget(self, "_desiredtrans") end
function meta:SetDesiredTrans(vec2) Rawget(self, "_desiredtrans"):Set(vec2) end
function meta:AddDesiredTrans(vec2)
	if not Rawget(self, "_physics") then return end
	Rawget(self, "_desiredtrans"):DoAdd(vec2)
end

--function meta:IsSupported() return Rawget(self, "_supported") end
--function meta:SetSupported(bool) Rawset(self, "_supported", bool) end

function meta:IsSupporting() return table.Count(Rawget(self, "_supporting")) > 0 end
function meta:GetSupporting() return Rawget(self, "_supporting") end
function meta:ClearSupporting() table.Empty(Rawget(self, "_supporting")) end
function meta:SetSupporting(physbox) Rawget(self, "_supporting")[physbox] = true end
function meta:AmSupporting(physbox) return Rawget(self, "_supporting")[physbox] end

function meta:GetSleeping() return Rawget(self, "_sleeping") end
function meta:SetSleeping(bool) Rawset(self, "_sleeping", bool) end
function meta:Wake() self:SetSleeping(false) end

function meta:IsStable()
	if Rawget(self, "_static") then return true end
	return Rawget(self, "_stable")
end
function meta:GetStable() return Rawget(self, "_stable") end
function meta:SetStable(bool) Rawset(self, "_stable", bool) end

function meta:IsStatic() return Rawget(self, "_static") end
function meta:SetStatic(bool) Rawset(self, "_static", bool) end

function meta:IsPhysicsEnabled() return Rawget(self, "_physics") end
function meta:EnablePhysics()
	Rawset(self, "_physics", true)
end
function meta:DisablePhysics()
	Rawset(self, "_partialpos", Vector2())
	Rawset(self, "_vel", Vector2())
	Rawset(self, "_desiredtrans", Vector2())

	Rawset(self, "_radvel", 0)

	Rawset(self, "_sleeping", false)
	Rawset(self, "_physics", false)
	Rawset(self, "_static", false)
	Rawset(self, "_stable", false)
end

function meta:GetMass() return Rawget(self, "_mass") end

function meta:GetInertia() return Rawget(self, "_inertia") end

function meta:GetHitboxes() return Rawget(self, "_hitboxes") end
function meta:SetHitboxes(tab) Rawset(self, "_hitboxes", tab) end

function meta:GetOriginCenterOffset() return Rawget(self, "_origincenteroffset") end
function meta:SetOriginCenterOffset(vec2) Rawset(self, "_origincenteroffset", vec2) end

function VGUIPhysbox:__Create(parentPan)
	Rawset(self, "_parent", parentPan)
	Rawset(self, "_supported", false)
	Rawset(self, "_supporting", {})
	Rawset(self, "_rad", 0)
	Rawset(self, "_mass", 1)
	Rawset(self, "_inertia", 200)
	Rawset(self, "_hitboxes", {})
	Rawset(self, "_hitboxcount", 0)
	Rawset(self, "_origincenteroffset", Vector2())
	Rawset(self, "_center", Vector2())

	self:DisablePhysics()

	GAMEMODE.VGUIPhysboxes[self] = true
	self.IsVGUIPhysbox = true

	VGUIPhysboxCount = VGUIPhysboxCount + 1
	Rawset(self, "_id", VGUIPhysboxCount)

	return self
end

function VGUIPhysbox:ToString()
	local parent = Rawget(self, "_parent")
	local id = parent.ID

	if id then
		return "[VGUIPhysbox] #" .. id
	else
		return "[VGUIPhysbox] associated with " .. ToString(parent)
	end
end

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
	local desiredTranslation = self:GetDesiredTrans()
	local partial = self:GetPartialPos()
	return pointsOrigin + desiredTranslation + partial
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
	local desiredTranslation = self:GetDesiredTrans()
	local partial = self:GetPartialPos()
	return pointsCenter + desiredTranslation + partial
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
	if Rawget(self, "_sleeping") then return end

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

--[[
function meta:EvaluateSupport()
	if not Rawget(self, "_supported") then return end

	local tab = {}
	local physbox = self
	local supportedBy = Rawget(self, "_supportedby")
	local staticSupport = Rawget(supportedBy, "_static")
	table.Insert(tab, supportedBy)

	-- We don't know how many supporting elements we have.
	while supportedBy and not staticSupport do
		physbox = supportedBy
		supportedBy = Rawget(physbox, "_supportedby")
		staticSupport = Rawget(supportedBy, "_static")
		table.Insert(tab, supportedBy)
	end

	if staticSupport then return end

	-- Uh oh. Not supported.
	self:SetSupported(false)

	for i = 1, #tab do
		local phys = tab[i]
		if Rawget(phys, "_static") then break end
		tab[i]:SetSupported(false)
	end
end

function meta:SetSupported(bool, physbox)
	Rawset(self, "_supported", bool)
	Rawset(self, "_supportedby", physbox)
end
]]
