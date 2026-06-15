local math_Ang = math.Ang
local math_Rad = math.Rad
local math_Cos = math.Cos
local math_Sin = math.Sin
local math_IsNearlyEqual = math.IsNearlyEqual


if not VGUIHitbox then
	GM.VGUIHitboxes = {}
	VGUIHitbox = Class:Create(nil, "VGUIHitbox")
end

local meta = FindMetaTable("VGUIHitbox")

function meta:GetID() return Rawget(self, "_id") end
function meta:SetID(val) Rawset(self, "_id", val) end

function meta:GetPhysbox() return Rawget(self, "_physbox") end
function meta:SetPhysbox(physbox) Rawset(self, "_physbox", physbox) end

function meta:GetPoints() return Rawget(self, "_points") end
function meta:SetPoints(points) Rawset(self, "_points", points) end


function meta:SetScreenPoints(points) Rawset(self, "_screenpoints") end

function meta:GetPhysicsPassScreenPoints()
	if Rawget(self, "_cachedirty") then self:RecachePhysicsPassScreenPoints() end
	return Rawget(self, "_physicspassscreenpoints")
end
function meta:SetPhysicsPassScreenPoints(points) Rawset(self, "_physicspassscreenpoints") end

function meta:GetCacheDirty() return Rawget(self, "_cachedirty") end
function meta:SetCacheDirty(bool) Rawset(self, "_cachedirty", bool) end

function meta:GetCenter() return Rawget(self, "_points"):GetCenter() end

function VGUIHitbox:__Create(physbox, points, id)
	Rawset(self, "_physbox", physbox)
	Rawset(self, "_points", points)
	Rawset(self, "_id", id)
	Rawset(self, "_screenpoints", points:Copy())
	Rawset(self, "_physicspassscreenpoints", points:Copy())
	Rawset(self, "_cachedirty", true)

	GAMEMODE.VGUIHitboxes[self] = true

	self.IsVGUIHitbox = true

	return self
end

function VGUIHitbox:ToString()
	local physbox = Rawget(self, "_physbox")
	return "A [VGUIHitbox] of " .. ToString(physbox)
end

function VGUIHitbox:Eq(other)
	if not IsTable(other) then return false end
	if not Rawget(other, "IsVGUIHitbox") then return false end

	local physbox = Rawget(self, "_physbox")
	local otherPhysbox = Rawget(other, "_physbox")
	if physbox ~= otherPhysbox then return false end

	return Rawget(self, "_id") == Rawget(other, "_id")
end

function meta:GetScreenOriginPoint() return Rawget(self, "_physbox"):GetScreenHitboxPointsOrigin() end

function meta:TransformPointsAroundOrigin(inputPoints, origin, pivot)
	local ret = inputPoints

	inputPoints = inputPoints:GetPoints()
	local points = self:GetPoints():GetPoints()
	local physbox = Rawget(self, "_physbox")

	-- Used for rotation
	local rad = Rawget(physbox, "_rad")
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
function meta:GetScreenPoints()
	local screenpoints = Rawget(self, "_screenpoints")
	local physbox = Rawget(self, "_physbox")
	local origin = physbox:GetScreenHitboxPointsOrigin() -- (0,0) relative to our base hitbox points.
	local pivot = physbox:GetCenterScreenPoint() -- Center of the physbox.

	return self:TransformPointsAroundOrigin(screenpoints, origin, pivot)
end

function meta:RecachePhysicsPassScreenPoints()
	local physpassScreenpoints = Rawget(self, "_physicspassscreenpoints")
	local physbox = Rawget(self, "_physbox")
	local physpassOrigin = physbox:GetPhysicsPassPointsOrigin()
	local physpassPivot = physbox:GetPhysicsPassPointsCenter()

	self:TransformPointsAroundOrigin(physpassScreenpoints, physpassOrigin, physpassPivot)
	self:SetCacheDirty(false)
end

function meta:Remove()
	GAMEMODE.VGUIHitboxes[self] = nil
	table.Empty(self)
end