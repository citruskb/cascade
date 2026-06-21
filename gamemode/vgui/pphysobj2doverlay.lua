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

	self.paintVars = {}

	self:SetVisible(true)
end

function PANEL:Think() end

function PANEL:SetupPaintVars(obj)
	local vars = {}

	local data = obj.itemData
	if not data then return end

	local ent = data.clEnt
	if not IsValid(ent) then Error("[PhysObj2D] - Invalid client entity") end

	-- Our size needs to be large enough to handle however our object is rotated. 
	-- Our X and Y originates based on this as well.
	local posVec = obj.physbox:GetCenterScreenPoint()
	local adjPos = posVec + obj.physbox.camXYOffset + data.camXYOffsetAdj
	local x, y = adjPos:Unpack()
	local w, h = obj.physbox.fDist, obj.physbox.fDist

	local objAng = math.Ang(-obj.rotation)
	local fov = data.fov
	local camPosOffset = data.camPos

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local center = ent:OBBCenter()
	local dist = mins:Distance(maxs)
	local sizeAdjust = math.Clamp(dist / 64, 0.1, 2)
	local camPos, zsqr
	center, camPos, x, y, zsqr = self:EvaluateCameraPos(center, camPosOffset, dist, x, y, data.camOffScreenAdjScale, sizeAdjust, objAng)

	local lookat = center
	local towards = lookat - camPos
	local ang = towards:Angle()
	ang:RotateAroundAxis(towards:GetNormalized(), objAng)

	vars.camPos = camPos
	vars.ang = ang
	vars.fov = fov
	vars.x = x
	vars.y = y
	vars.w = w
	vars.h = h

	vars.clEnt = ent
	vars.zsqr = zsqr
	vars.sizeAdjust = sizeAdjust

	table.insert(self.paintVars, vars)

	--[[
	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)

	cam.Start3D(camPos, ang, fov, x, y, w, h, 8, 256)
		render.OverrideDepthEnable(true, false)
		ent:DrawModel()
		render.OverrideDepthEnable(false)
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
	]]
end

function PANEL:EvaluateCameraPos(center, camPosOffset, dist, x, y, camOffScreenAdjScale, adjustSkew, objAng)

	-- Do nothing, basically
	--return center, center + camPosOffset * dist, math.Max(x, 0), math.Max(y, 0), 0


	-- Tried to adjust by angling the camera and such.

	if x >= 0 and y >= 0 then
		return center, center + camPosOffset * dist, x, y, 0
	end

	local xMag = x < 0 and -x or 0
	local yMag = y < 0 and -y or 0
	local adjustDir = Vector(0, xMag, -yMag)
	local adjust = adjustDir * (camOffScreenAdjScale or 1)
	adjust:Rotate(Angle(0, 0, -objAng))

	--[[
	local dir = adjust:Angle()
	dir:RotateAroundAxis(Vector(1, 0, 0), objAng)
	adjust = dir:Forward() * adjust:Length()
	]]

	return center + adjust, center + adjust + camPosOffset * dist, math.Max(x, 0), math.Max(y, 0), adjust:LengthSqr()


	-- Current, fly-off-the-top behavior

	--[[
	local negativeX = math.Min(x, 0)
	local negativeY = math.Min(y, 0)
	local adjust = Vector(0, -negativeX, negativeY)
	return center, center + adjust * adjustSkew + camPosOffset * dist, math.Max(x, 0), math.Max(y, 0), adjust:LengthSqr()
	]]
end

function PANEL:PaintPhysObj2D(vars)
	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)

	local camData = {
		x = vars.x,
		y = vars.y,
		w = vars.w,
		h = vars.h,
		type = "3D",
		origin = vars.camPos,
		angles = vars.ang,
		fov = vars.fov,
		aspect = vars.w / vars.h,
		zfar = 512 * vars.sizeAdjust,
		znear = 8,
		subrect = false,
		bloomtone = false,
		offcenter = {
			left = 0,
			right = 0,
			bottom = 0,
			top = 0,
		},
		ortho = {
			left = -100,
			right = 100,
			bottom = 100,
			top = -100
		},
	}
	cam.Start(camData)


	--cam.Start3D(vars.camPos, vars.ang, vars.fov, vars.x, vars.y, vars.w, vars.h, 8, 512 * vars.sizeAdjust)
		--cam.StartOrthoView(-100, 100, -100, 100)
			render.OverrideDepthEnable(true, false)
				vars.clEnt:DrawModel()
			render.OverrideDepthEnable(false)
		--cam.EndOrthoView()
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

function PANEL:Paint()
	self.paintVars = {}
	for k, obj in pairs(GAMEMODE.PhysicsObjects2D) do
		self:SetupPaintVars(obj)
	end

	table.SortByMember(self.paintVars, "zsqr")
	for k, vars in pairs(self.paintVars) do
		self:PaintPhysObj2D(vars)
	end
end

vgui.Register("PPhysObj2DOverlay", PANEL, "DPanel")