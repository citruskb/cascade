PANEL = {}

function PANEL:Init()
	local w, h = ScrW(), ScrH()

	self.fov = 50
	self.camPosOffset = Vector(0.2, -0.8, 0)

	self:SetPos(0, h * 0.6)
	self:SetSize(w * 0.2, h * 0.4)
end

function PANEL:SetPlayer(pl)
	if pl == MySelf then
		self.MySelf = true
		self.model = MySelf:GetModel()
	else
		-- TODO
	end

	self.ent = ClientsideModel(self.model)
	if not IsValid(self.ent) then return end
	self.ent:SetNoDraw(true)
	self.ent:SetIK(false)

	self.ent.GetPlayerColor = function() return MySelf:GetPlayerColor() end

	-- idle_melee_angry looks quite good for your own model.
	self:SendSequence("idle_melee_angry")
end

function PANEL:SendSequence(seq)
	local iSeq = self.ent:LookupSequence(seq)
	if iSeq > 0 then self.ent:ResetSequence(iSeq) end
end

function PANEL:Paint()
	local ent = self.ent
	if not IsValid(ent) then return end

	local buffer = 0
	local x, y = self:GetPos()
	local w, h = self:GetSize()

	-- Adjust for the buffer
	x, y = x + buffer, y + buffer
	--siz = siz - 2 * buffer

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local center = ent:OBBCenter() + Vector(0, 0, -5)
	local dist = mins:Distance(maxs)
	local camPos = center + self.camPosOffset * dist
	local lookat = center
	local towards = lookat - camPos
	local ang = towards:Angle()

	if self.MySelf then
		--ang:RotateAroundAxis(towards:GetNormalized(), 180)
	end

	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)

	cam.Start3D(camPos, ang, self.fov, x, y, w, h, 8, 256)
		self.ent:DrawModel()
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

vgui.Register("DPlayerModel", PANEL, "DPanel")