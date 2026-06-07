GM.VGUIPhysboxes = {}
GM.DebugObjects = {}

if not VGUIPhysbox then
	VGUIPhysbox = Class:Create(nil, "VGUIPhysbox")
end

local meta = FindMetaTable("VGUIPhysbox")

function meta:GetParent() return Rawget(self, "_parent") end
function meta:SetParent(pan) Rawset(self, "_parent", pan) end

function meta:GetPartialPos() return Rawget(self, "_partialpos") end
function meta:SetPartialPos(vec2) Rawget(self, "_partialpos"):Set(vec2) end
function meta:AddPartialPos(vec2) Rawget(self, "_partialpos"):DoAdd(vec2) end

function meta:GetVel() return Rawget(self, "_vel") end
function meta:SetVel(vec2) Rawget(self, "_vel"):Set(vec2) end
function meta:AddVel(vec2) Rawget(self, "_vel"):DoAdd(vec2) end

function meta:GetDesiredTrans() return Rawget(self, "_desiredtrans") end
function meta:SetDesiredTrans(vec2) Rawget(self, "_desiredtrans"):Set(vec2) end
function meta:AddDesiredTrans(vec2) Rawget(self, "_desiredtrans"):DoAdd(vec2) end

function meta:IsPhysicsEnabled() return Rawget(self, "_physics") end
function meta:EnablePhysics()
	Rawset(self, "_physics", true)
end
function meta:DisablePhysics()
	Rawset(self, "_partialpos", Vector2())
	Rawset(self, "_vel", Vector2())
	Rawset(self, "_desiredtrans", Vector2())

	Rawset(self, "_physics", false)
end

function meta:GetHitboxes() return Rawget(self, "_hitboxes") end
function meta:SetHitboxes(tab) Rawset(self, "_hitboxes", tab) end

function meta:GetOriginCenterOffset() return Rawget(self, "_origincenteroffset") end
function meta:SetOriginCenterOffset(vec2) Rawset(self, "_origincenteroffset", vec2) end

function meta:GetAllHitboxPoints()
	if Rawget(self, "_allhitboxpointsdirty") then self:RecacheAllHitboxPoints() end
	return rawget(self, "_allhitboxpoints")
end
function meta:SetAllHitboxPoints(points)
	Rawset(self, "_allhitboxpoints", points)
	self:MarkAllHitboxPointsUpdated()
end

function meta:GetPointsOrigin()
	if Rawget(self, "_pointsorigindirty") then self:RecachePointsOrigin() end
	return Rawget(self, "_pointsorigin")
end
function meta:SetPointsOrigin(vec2)
	Rawset(self, "_pointsorigin", vec2)
	self:MarkPointsOriginUpdated()
end

function meta:GetAllHitboxPointsDirty() return Rawget(self, "_allhitboxpointsdirty") end
function meta:MarkAllHitboxPointsDirty() Rawset(self, "_allhitboxpointsdirty", true) end
function meta:MarkAllHitboxPointsUpdated() Rawset(self, "_allhitboxpointsdirty", false) end

function meta:GetPointsOriginDirty() return Rawget(self, "_pointsorigindirty") end
function meta:MarkPointsOriginDirty() Rawset(self, "_pointsorigindirty", true) end
function meta:MarkPointsOriginUpdated() Rawset(self, "_pointsorigindirty", false) end

function meta:MarkAllDirty()
	self:MarkAllHitboxPointsDirty()
	self:MarkPointsOriginDirty()
end

function VGUIPhysbox:__Create(parentPan)
	Rawset(self, "_parent", parentPan)
	Rawset(self, "_hitboxes", {})
	Rawset(self, "_origincenteroffset", Vector2())
	self:MarkAllDirty()

	self:DisablePhysics()

	GAMEMODE.VGUIPhysboxes[self] = true

	return self
end

function meta:AddHitbox(points, noResize)
	local hitbox = VGUIHitbox:Create(self, points)
	local hitboxes = Rawget(self, "_hitboxes")
	table.Insert(hitboxes, hitbox)
	self:MarkAllHitboxPointsDirty()

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
end

function meta:RecachePointsOrigin()
	-- If our parent isn't an item just assume our hitboxes originate from the item's top left corner.
	local parent = Rawget(self, "_parent")
	if not parent.GetCenterPos then
		local origin = Vector2(parent:GetVPos():Unpack())
		self:SetPointsOrigin(origin)
		return
	end

	local centerOffset = Rawget(self, "_origincenteroffset")
	local pcenter = parent.GetCenterPos and parent:GetCenterPos()

	self:SetPointsOrigin(pcenter + centerOffset)
end

function meta:RecacheAllHitboxPoints()
	local hitboxes = Rawget(self, "_hitboxes")
	local allpoints
	for k, hitbox in pairs(hitboxes) do
		if not allpoints then
			allpoints = hitbox:GetPoints()
			continue
		end

		allpoints = allpoints + hitbox:GetPoints()
	end

	self:SetAllHitboxPoints(allpoints)
end

function meta:Remove()
	GAMEMODE.VGUIPhysboxes[self] = nil

	local hitboxes = Rawget(self, "_hitboxes")
	for k, hitbox in pairs(hitboxes) do hitbox:Remove() end
end

-- Determine where we need to move our parent based on physics parameters.
-- This runs for every physbox for every frame after we handle collisions, gravity etc.
function meta:DoPhysicsThink()
	if not Rawget(self, "_physics") then return end

	local parent = Rawget(self, "_parent")

	local trans = Rawget(self, "_desiredtrans")
	local vel = Rawget(self, "_vel")
	local partial = Rawget(self, "_partialpos")

	-- Apply our translation and velocity to our partial pos.
	partial:DoAdd(trans + vel)

	-- Our desired translation is the accumulated needed movement requested by accumulated collision resolution.
	-- Since it has been applied, it has done its job.
	trans:Zero()

	-- To get our whole number movement, round partial to the nearest.
	local mx, my = partial:Unpack()
	local delta = Vector2(math.Round(mx, 0), math.Round(my, 0))

	-- If we're not moving do nothing.
	if delta:IsZero() then return end

	-- Move our parent!
	local ivpos = parent:GetVPos()
	ivpos:DoAdd(delta)
	parent:SetPos(ivpos:Unpack())

	-- The movement has been applied.
	-- Therefore, subtract our movement from our partial pos.
	partial:DoSub(delta)

	self:MarkPointsOriginDirty()
end
