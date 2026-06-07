local math_Rad = math.Rad
local math_Cos = math.Cos
local math_Sin = math.Sin

GM.VGUIHitboxes = {}

if not VGUIHitbox then
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
function meta:SetPhysicsPassScreenPoints(points) Rawset(self, "_physicspassscreenpoints") end

function meta:GetCenter() return Rawget(self, "_points"):GetCenter() end

function VGUIHitbox:__Create(physbox, points)
	Rawset(self, "_physbox", physbox)
	Rawset(self, "_points", points)
	Rawset(self, "_screenpoints", points:Copy())
	Rawset(self, "_physicspassscreenpoints", points:Copy())

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

function meta:GetScreenOriginPoint() return Rawget(self, "_physbox"):GetPointsOrigin() end

function meta:TransformPointsAroundOrigin(inputPoints, origin)
	local ret = inputPoints

	inputPoints = inputPoints:GetPoints()
	local points = self:GetPoints():GetPoints()
	local physbox = Rawget(self, "_physbox")

	-- Used for rotation
	local angle = Rawget(physbox, "_ang")
	local radians, cos, sin
	if angle ~= 0 then
		radians = math_Rad(angle)
		cos, sin = math_Cos(radians), math_Sin(radians)
	end

	for i = 1, #inputPoints do
		local inputPoint = inputPoints[i]
		local px, py = points[i]:Unpack()
		local ox, oy = origin:Unpack()
		local tx, ty = px + ox, py + oy

		if angle == 0 then
			inputPoint:SetUnpacked(tx, ty)
		else
			inputPoint:SetUnpacked(
				ox + cos * (tx - ox) - sin * (ty- oy),
				oy + sin * (tx - ox) + cos * (ty - oy)
			)
		end
	end

	ret:MarkAllDirty()

	return ret
end

-- Done this way to save memory/GC. We don't want to make literally thousands of new Vector2/Point objects per frame.
-- Returns the position of our points on the screen.
function meta:GetScreenPoints()
	local screenpoints = Rawget(self, "_screenpoints")
	local physbox = Rawget(self, "_physbox")
	local origin = physbox:GetPointsOrigin()

	return self:TransformPointsAroundOrigin(screenpoints, origin)
end

-- TODO: Maybe this is worth caching?
-- Can't think of a clean way to detect when it has changed.. I suppose in the physbox whenever its desired translation changes?
function meta:GetPhysicsPassScreenPoints()
	local physpassScreenpoints = Rawget(self, "_physicspassscreenpoints")
	local physbox = Rawget(self, "_physbox")
	local physpassOrigin = physbox:GetPhysicsPassPointsOrigin()

	return self:TransformPointsAroundOrigin(physpassScreenpoints, physpassOrigin)
end

function meta:Remove()
	GAMEMODE.VGUIHitboxes[self] = nil
	table.Empty(self)
end