-- ClientEnts never get GC'd.
if not dGridCellLoaded then
	local ent = ClientsideModel("models/props_junk/CinderBlock01a.mdl", RENDERGROUP_OTHER)
	if not IsValid(ent) then return end

	ent:SetNoDraw(true)
	GM.CellProp = ent
end

PANEL = {}

local SkyBlue = Color(0, 130, 220, 255)
function PANEL:Init()
	self.painted = false
	self:SetZPos(GM_ZPOS_PGRID)
	self.fov = 45
	self.camPosOffset = Vector(0.6, 0, 0)
	self.buffer = 8

	self.shapeImg = vgui.Create("DImage", self)
	self.shapeImg:SetImage("kite.png")
	self.shapeImg:SetImageColor(SkyBlue)
	self.shapeImg:SetVisible(false)

	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	local w, h = self:GetSize()
	self.shapeImg:SetSize(w * 0.5, h * 0.5)
	self.shapeImg:SetPos(w * 0.25 + self.buffer / 4, h * 0.25 + self.buffer / 4)
end

function PANEL:PaintCell(r, g, b, blend)
	local ent = GAMEMODE.CellProp
	if not IsValid(ent) then return end

	r = r or 1
	g = g or 1
	b = b or 1
	blend = blend or 1

	local x, y = self:GetPos()
	local siz = self:GetSize()

	-- Adjust for the buffer
	x, y = x + self.buffer, y + self.buffer
	siz = siz - 2 * self.buffer

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
		render.SetColorModulation(r, g, b)
		render.SetBlend(blend)

		GAMEMODE.CellProp:DrawModel()

		render.SetBlend(1)
		render.SetColorModulation(1, 1, 1)
		render.OverrideDepthEnable(false)
	cam.End3D()

	cam.IgnoreZ(false)
	render.SuppressEngineLighting(false)

	return true
end

function PANEL:Think()
	if not IsValid(GAMEMODE.pItemData) and self.shapeImg:IsVisible() then
		self.shapeImg:SetVisible(false)
	end

	self:EvaluateShownSynergy(IsValid(GAMEMODE.pItemData) and GAMEMODE.pItemData.item or GAMEMODE.HeldItem)
end

function PANEL:EvaluateShownSynergy(item)
	if not item then return end

	local synergyPoints = item.gridPointEvaluator.backpackSynergyPoints

	if synergyPoints.kite then
		local showSynergy = synergyPoints["kite"][self.bindPointIndex]
		if showSynergy then self.shapeImg:SetVisible(true) end
	end
end

function PANEL:PaintPlacementHints()
	local backpack = GAMEMODE.backpack
	if not backpack then return end

	local boundCell = backpack.cellsScreenIDX[self.bindPointIndex]
	if not boundCell.canPlaceDraw and not boundCell.cannotPlaceDraw then return end

	self.painted = self:PaintCell(
		-- Color modulation
		not boundCell.canPlaceDraw and boundCell.cannotPlaceDraw and 1 or 0,
		not boundCell.cannotPlaceDraw and boundCell.canPlaceDraw and 1 or 0,
		0,

		-- blend
		0.7
	)

	local held = GAMEMODE.HeldItem
	local contained = false
	if held then
		for i = 1, #held.gridPointEvaluator.backpackBindPoints do
			local idx = held.gridPointEvaluator.backpackBindPoints[i]
			if idx ~= self.bindPointIndex then continue end

			contained = true
			break
		end
	end

	if boundCell.canPlaceDraw then
		if not contained then return end
		timer.Create(ToString(self) .. "_canPlaceDraw", 0.066, 1, function() boundCell.canPlaceDraw = nil end)
	end
	if boundCell.cannotPlaceDraw then
		if not contained then return end
		timer.Create(ToString(self) .. "_cannotPlaceDraw", 0.066, 1, function() boundCell.cannotPlaceDraw = nil end)
	end
end

function PANEL:PaintHintCells()
	if self.painted then return end

	local held = GAMEMODE.HeldItem
	if not held then return end

	local backpack = GAMEMODE.backpack
	if not backpack then return end

	local boundCell = backpack.cellsScreenIDX[self.bindPointIndex]

	-- Only draw cells we care to hint about.

	if held.isContainer and boundCell.heldContainer and boundCell.heldContainer ~= held then
		return
	end
	if (held.isNormalItem or held.isAugment) and (boundCell.heldItem and boundCell.heldItem ~= held or not boundCell.heldContainer) then
		return
	end

	self:PaintCell(0.9, 0.9, 0.9, 0.6)
end

function PANEL:Paint()
	self.painted = false
	self:PaintPlacementHints()
	self:PaintHintCells()
end

vgui.Register("DGridCell", PANEL, "DPanel")