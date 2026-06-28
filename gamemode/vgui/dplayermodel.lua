PANEL = {}

function PANEL:Init()
	local w, h = ScrW(), ScrH()

	self.fov = 60
	self.camPosOffset = Vector(1, 0, 0)

	self:SetPos(0, h * 0.6)
	self:SetSize(w * 0.2, h * 0.4)
end

function PANEL:SetPlayer(pl)
	if pl == MySelf then
		print("set player!", MySelf, MySelf:GetModel())
		self.model = MySelf:GetModel()
	else
		-- TODO
	end

	self.ent = ClientsideModel(self.model)
	if not IsValid(self.ent) then return end
	self.ent:SetNoDraw(true)
	self.ent:SetIK(false)

	local iSeq = self.ent:LookupSequence( "walk_all" )
	if ( iSeq <= 0 ) then iSeq = self.ent:LookupSequence( "WalkUnarmed_all" ) end
	if ( iSeq <= 0 ) then iSeq = self.ent:LookupSequence( "walk_all_moderate" ) end

	if ( iSeq > 0 ) then self.ent:ResetSequence( iSeq ) end
end

function PANEL:Paint()
	local ent = self.ent
	if not IsValid(ent) then return end

	local buffer = 0
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

	cam.Start3D(camPos, ang, self.fov, x, y, siz, siz, 8, 256)
		render.OverrideDepthEnable(true, false)

		self.ent:DrawModel()

		render.OverrideDepthEnable(false)
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

vgui.Register("DPlayerModel", PANEL, "DPanel")