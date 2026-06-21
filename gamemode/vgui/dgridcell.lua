-- ClientEnts never get GC'd.
if not dGridCellLoaded then
	local ent = ClientsideModel("models/props_junk/CinderBlock01a.mdl", RENDERGROUP_OTHER)
	if not IsValid(ent) then return end

	ent:SetNoDraw(true)
	GM.CellProp = ent
end

PANEL = {}

function PANEL:Init()
	self.fov = 45
	self.camPosOffset = Vector(0.6, 0, 0)
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
end

function PANEL:RefreshBackpackBindPoint()

end

function PANEL:Paint()
	local ent = GAMEMODE.CellProp
	if not IsValid(ent) then return end

	local buffer = 8
	local x, y = self:GetPos()
	local siz = self:GetSize()

	-- Adjust for the buffer
	x, y = x + buffer, y + buffer
	siz = siz - 2 * buffer

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local center = ent:OBBCenter() + Vector(0, 0, 4.8)
	local dist = mins:Distance(maxs)
	local camPos = center + self.camPosOffset * dist
	local lookat = center
	local towards = lookat - camPos
	local ang = towards:Angle()

	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)

	cam.Start3D(camPos, ang, self.fov, x, y, siz, siz, 8, 64)
		render.OverrideDepthEnable(true, false)
		GAMEMODE.CellProp:DrawModel()
		render.OverrideDepthEnable(false)
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

vgui.Register("DGridCell", PANEL, "DPanel")