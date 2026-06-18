-- TODO: Add support for multiple models rendered at once?

PANEL = {}

--[[
Critical vars:

FOV
camPos
]]

-- Init vars?
-- Make sure item is postioned correctly?
function PANEL:Init()
	self.fov = 60
	self.camPos = Vector(1, 0, 0)
	self.rotation = 0
end

-- ?
function PANEL:Think()

end

function PANEL:OnRemove()
	if IsValid(self.Entity) then self.Entity:Remove() end
end

function PANEL:LayoutEntity(ent) end

-- Handle the camera
function PANEL:Paint()
	local ent = self.Entity
	if not IsValid(ent) then return end

	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local campos = mins:Distance(maxs) * self.camPos
	local lookat = (mins + maxs) / 2
	local towards = lookat - campos
	local ang = towards:Angle()
	ang:RotateAroundAxis(towards, self.rotation)

	local x, y = self:LocalToScreen(0, 0)
	local w, h = self:GetSize()

	cam.Start3D(campos, ang, self.FOV, x, y, w, h, 8, 4096)
		render.OverrideDepthEnable(true, false)
		ent:DrawModel()
		render.OverrideDepthEnable(false)
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

vgui.Register("DItemModel", PANEL, "DModelPanel")