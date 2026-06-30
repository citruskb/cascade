--[[
	The point of this is a single screen-wide panel to handle drawing anything needed for our 2d physics objects.
	Be it the objects themselves, effects, whatever.
	We don't do this on the shop or battle screens directly because we may want to be hiding those panels while displaying this one. 
]]--

-- lower = drawn later.
DRAW_LAYER_HELD_ITEM = 1
DRAW_LAYER_POPPED = 2
DRAW_LAYER_PLACED_ITEM = 3
DRAW_LAYER_PLACED_CONTAINER = 4
DRAW_LAYER_PHYSICS_INVENTORY = 5


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
	local x, y = obj:GetAdjCamPosition():Unpack()
	local w, h = obj.physbox.fDist, obj.physbox.fDist

	local objAng = math.Ang(-obj.rotation) + data.camAngleOffsetAdj
	local fov = data.fov
	local camPosOffset = data.camPos

	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local center = ent:OBBCenter()
	local dist = mins:Distance(maxs)
	local sizeAdjust = 1 --math.Clamp(dist / 64, 0.1, 4)
	local camPos, zsqr

	self:EvaluateOrthoLock(x, y, obj.physbox)
	local isOrtho = obj.physbox.isCamOrthoLocked
	if not isOrtho then
		local inBounds = obj.physbox:IsInsideInventoryBounds()
		isOrtho = not inBounds or inBounds and (obj.isPickedUp or obj.physbox.isBeingPushed)
	end

	center, camPos, x, y, zsqr = self:EvaluateCameraPos(center, camPosOffset, dist, x, y, data.camOffScreenAdjScale, sizeAdjust, objAng, isOrtho)

	local lookat = center
	local towards = lookat - camPos
	local ang = towards:Angle()
	ang:RotateAroundAxis(towards:GetNormalized(), objAng)

	vars.isOrtho = isOrtho

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
	vars.camOrthoAdjScale = data.camOrthoAdjScale

	vars.drawLayer = self:EvaluateDrawLayer(obj.physbox, isOrtho)

	table.insert(self.paintVars, vars)
end

-- idea of this is to lock ourselves into ortho view  if we are dropped near the top of the screen in inventory until we fall to normal drawing range.
function PANEL:EvaluateOrthoLock(x, y, physbox)
	if not physbox.isCamOrthoLocked then return end
	if y < 0 then return end
	physbox.isCamOrthoLocked = false
end

function PANEL:EvaluateDrawLayer(physbox, isOrtho)
	if physbox.isInGridInventory and (physbox.parent.isNormalItem or physbox.parent.isAugment) then return DRAW_LAYER_PLACED_ITEM end
	if physbox.isInGridInventory and physbox.parent.isContainer then return DRAW_LAYER_PLACED_CONTAINER end
	if GAMEMODE.HeldItem and GAMEMODE.HeldItem.physbox == physbox then return physbox.parent.isContainer and DRAW_LAYER_PLACED_CONTAINER or DRAW_LAYER_HELD_ITEM end
	if physbox.isBeingPopped then return DRAW_LAYER_POPPED end
	if not isOrtho then return DRAW_LAYER_PHYSICS_INVENTORY end

	return DRAW_LAYER_PHYSICS_INVENTORY
end

local POSITIVE_X = 1
local NEGATIVE_X = 2
local POSITIVE_Y = 3
local NEGATIVE_Y = 4
local POSITIVE_Z = 5
local NEGATIVE_Z = 6
local adjustDirs = {
	[POSITIVE_X] = {xDir = Vector(0, 1, 0), yDir = Vector(0, 0, -1)},
	[NEGATIVE_X] = {xDir = Vector(0, -1, 0), yDir = Vector(0, 0, -1)},
	[POSITIVE_Y] = {xDir = Vector(-1, 0, 0), yDir = Vector(0, 0, -1)},
	[NEGATIVE_Y] = {xDir = Vector(1, 0, 0), yDir = Vector(0, 0, -1)},
	[POSITIVE_Z] = {xDir = Vector(0, -1, 0), yDir = Vector(-1, 0, 0)},
	[NEGATIVE_Z] = {xDir = Vector(0, -1, 0), yDir = Vector(1, 0, 0)},
}

function PANEL:GetOrthoAdjustDir(camPosOffset, xMag, yMag)
	local idx =
		camPosOffset.x > 0 and POSITIVE_X or
		camPosOffset.x < 0 and NEGATIVE_X or
		camPosOffset.y > 0 and POSITIVE_Y or
		camPosOffset.y < 0 and NEGATIVE_Y or
		camPosOffset.z > 0 and POSITIVE_Z or
		camPosOffset.z < 0 and NEGATIVE_Z

	if not idx then Error("[pPhysObj2DOverlay] - cam offset shouldn't be origin!") end

	return adjustDirs[idx].xDir * xMag + adjustDirs[idx].yDir * yMag
end

function PANEL:EvaluateCameraPos(center, camPosOffset, dist, x, y, camOffScreenAdjScale, adjustSkew, objAng, isOrtho, physbox)

	-- Do nothing, basically
	--return center, center + camPosOffset * dist, math.Max(x, 0), math.Max(y, 0), 0

	if not isOrtho then
		local negativeX = math.Min(x, 0)
		local negativeY = math.Min(y, 0)
		local adjust = Vector(0, -negativeX, negativeY)
		return center, center + adjust * adjustSkew + camPosOffset * dist, math.Max(x, 0), math.Max(y, 0), adjust:LengthSqr()
	else
		if x >= 0 and y >= 0 then
			return center, center + camPosOffset * dist, x, y, 0
		end

		local xMag = x < 0 and -x or 0
		local yMag = y < 0 and -y or 0
		local adjustDir = self:GetOrthoAdjustDir(camPosOffset, xMag, yMag) --Vector(0, xMag, -yMag)
		local adjust = adjustDir * (camOffScreenAdjScale or 1)
		adjust:Rotate(Angle(0, 0, -objAng))

		return center + adjust, center + adjust + camPosOffset * dist, math.Max(x, 0), math.Max(y, 0), 0 --adjust:LengthSqr()
	end
end

function PANEL:PaintPhysObj2D(vars)
	cam.Start3D(vars.camPos, vars.ang, vars.fov, vars.x, vars.y, vars.w, vars.h, 8, 512 * vars.sizeAdjust)
		render.OverrideDepthEnable(true, false)
			vars.clEnt:DrawModel()
		render.OverrideDepthEnable(false)
	cam.End3D()
end

function PANEL:PaintOrthoPhysObj2D(vars)
	local orthoAdj = vars.camOrthoAdjScale

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
		offcenter = nil,
		ortho = {
			left = -1 * orthoAdj,
			right = 1 * orthoAdj,
			bottom = 1 * orthoAdj,
			top = -1 * orthoAdj,
		},
	}
	cam.Start(camData)
		render.OverrideDepthEnable(true, false)

			-- TODO - might be able to use cam.ApplyShake() to do some interesting effects..
			-- Say when items activate?

			-- TODO - might be able to mess with the FOV to affect perceived object size.

			vars.clEnt:DrawModel()
		render.OverrideDepthEnable(false)
	cam.End3D()
end

function PANEL:Paint()
	self.paintVars = {}
	for obj, _ in pairs(GAMEMODE.itemObjs) do
		self:SetupPaintVars(obj)
	end

	table.SortByMember(self.paintVars, "zsqr")
	table.SortByMember(self.paintVars, "drawLayer")

	render.SuppressEngineLighting(true)
	cam.IgnoreZ(true)


	for k, vars in ipairs(self.paintVars) do
		if vars.isOrtho then
			self:PaintOrthoPhysObj2D(vars)
		else
			self:PaintPhysObj2D(vars)
		end
	end

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)
end

vgui.Register("PPhysObj2DOverlay", PANEL, "DPanel")