local math_Ang = math.Ang
local math_Cos = math.Cos
local math_Sin = math.Sin
local math_IsNearlyEqual = math.IsNearlyEqual

if not Hitbox2 then
	Hitbox2 = Class:Create(nil, "Hitbox2")
end

local meta = FindMetaTable("Hitbox2")

function Hitbox2:__Create(physbox, pointsObj, id)
	-- This coupled with the physbox's ID makes a completely unique pairing representing this hitbox for contact persistence.
	self.id = id

	self.physbox = physbox

	-- The local configuration of our points
	self.pointsObj = pointsObj
	self:RecalculateScreenScaledPoints()

	-- The actual screen location of our points, accounting for rotation, physbox position, etc
	-- This is initialized here but recalculated when needed.
	self.screenPointsObj = pointsObj:Copy()
	self.screenPointsObjDirty = true

	self.isScreenScaled = physbox.isScreenScaled

	PhysObj2D.hitboxes[self] = true

	self.isHitbox2 = true

	return self
end

function Hitbox2:ToString() return "A [Hitbox2] of " .. ToString(self.physbox) end

function Hitbox2:Eq(other)
	if not IsTable(other) then return false end
	if not other.isHitbox2 then return false end
	if self.physbox ~= other.physbox then return false end
	return self.id == other.id
end

function meta:GetScreenOriginPoint() return self.physbox:GetScreenHitboxPointsOrigin() end

function meta:GetScreenScaledPoints()
	if not self.isScreenScaled then return self.pointsObj end
	return self.pointsObj * (1 / GAMEMODE.UncappedScreenScaleW)
end

function meta:RecalculateScreenScaledPoints()
	if not self.isScreenScaled or self.isScreenScaled and GAMEMODE.UncappedScreenScaleW == 1 then
		self.screenScaledPointsObj = self.pointsObj:Copy()
	else
		local pointsTab = self.pointsObj:GetPoints()
		local scaledTab = {}
		for i = 1, #pointsTab do
			scaledTab[i] = pointsTab[i] * GAMEMODE.UncappedScreenScaleW
		end
		self.screenScaledPointsObj = Points(scaledTab)
	end
end

hook.Add("ScreenScaleChanged", "ScreenScaleChanged.hitboxes", function(old)
	for hitbox, _ in pairs(PhysObj2D.hitboxes) do
		hitbox:RecalculateScreenScaledPoints()
	end
end)

function meta:TransformPointsAroundOrigin(inputPoints, origin, pivot)
	local ret = inputPoints

	inputPoints = inputPoints:GetPoints()
	local points = self.screenScaledPointsObj:GetPoints()

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
	PhysObj2D.hitboxes[self] = nil
	table.Empty(self)
end