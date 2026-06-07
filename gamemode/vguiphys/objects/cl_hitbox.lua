GM.VGUIHitboxes = {}

if not VGUIHitbox then
	VGUIHitbox = Class:Create(nil, "VGUIHitbox")
end

local meta = FindMetaTable("VGUIHitbox")

function meta:GetPhysbox() return Rawget(self, "_physbox") end
function meta:SetPhysbox(physbox) Rawset(self, "_physbox", physbox) end

function meta:GetPoints() return Rawget(self, "_points") end
function meta:SetPoints(points) Rawset(self, "_points", points) end

function meta:GetCenter() return Rawget(self, "_points"):GetCenter() end

function VGUIHitbox:__Create(physbox, points)
	Rawset(self, "_physbox", physbox)
	Rawset(self, "_points", points)

	GAMEMODE.VGUIHitboxes[self] = true

	return self
end

function meta:GetScreenOriginPoint() return Rawget(self, "_physbox"):GetPointsOrigin() end

function meta:Remove()
	GAMEMODE.VGUIHitboxes[self] = nil
end