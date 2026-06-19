local math_Ang = math.Ang
local math_Cos = math.Cos
local math_Sin = math.Sin
local math_IsNearlyEqual = math.IsNearlyEqual

if not VGUIHitbox then
	GM.VGUIHitboxes = {}
	VGUIHitbox = Class:Create(nil, "VGUIHitbox")
end

local meta = FindMetaTable("VGUIHitbox")



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