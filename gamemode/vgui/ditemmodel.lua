-- TODO: Add support for multiple models rendered at once?

PANEL = {}

-- Init vars?
-- Make sure item is postioned correctly?
function PANEL:Init()
	self.FOV = 60
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
	maxs.z = maxs.x * 4.5
	local campos = mins:Distance(maxs) * Vector(0, -0.9, 0.4)
	local lookat = (mins + maxs) / 2
	local ang = (lookat - campos):Angle()

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