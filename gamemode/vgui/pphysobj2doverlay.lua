--[[
	The point of this is a single screen-wide panel to handle drawing anything needed for our 2d physics objects.
	Be it the objects themselves, effects, whatever.
	We don't do this on the shop or battle screens directly because we may want to be hiding those panels while displaying this one. 
]]--

PANEL = {}

function PANEL:Init()
	self:SetZPos(GM_ZPOS_POVERLAY)
	self:SetPos(0, 0)

	local w, h = ScrW(), ScrH()
	self:SetSize(w, h)
	self:Center()

	self:SetVisible(true)
end

function PANEL:Think() end

function PANEL:PaintPhysObj2D(obj)
	local data = obj.itemData
	if not data then return end

	local ent = data.clEnt
	if not IsValid(ent) then Error("[PhysObj2D] - Invalid client entity") end

	local x, y = obj.physbox:GetScreenHitboxPointsOrigin():Unpack()
	local objAng = math.Ang(-obj.rotation)
	local fov = data.fov
	local camPosOffset = data.camPos

	--if obj.isScreenScaled then
	--	fov = fov / GAMEMODE.UncappedScreenScale
	--end

	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local center = ent:OBBCenter()
	local camPos = center + camPosOffset * mins:Distance(maxs)
	local lookat = center
	local towards = lookat - camPos
	local ang = towards:Angle()
	ang:RotateAroundAxis(towards:GetNormalized(), objAng)

	local w, h = obj.physbox:GetSize()

	cam.Start3D(camPos, ang, fov, x, y, w, h, 8, 4096)
		render.OverrideDepthEnable(true, false)
		ent:DrawModel()
		render.OverrideDepthEnable(false)
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

function PANEL:Paint()
	for k, obj in pairs(GAMEMODE.PhysicsObjects2D) do
		self:PaintPhysObj2D(obj)
	end
end

vgui.Register("PPhysObj2DOverlay", PANEL, "DPanel")