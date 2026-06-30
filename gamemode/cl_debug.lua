--[[
refLines = {}
incLines = {}
normals = {}
]]

DEBUG_MODE_MINIMAL = 1
DEBUG_MODE_DETAILED = 2

GM.Debug = true -- TODO move to a convar.
GM.DebugMode = DEBUG_MODE_MINIMAL
GM.DebugObjects = {}

local itemCol = Color(255, 255, 0, 60)
local itemTxtCol = Color(
	math.Max(itemCol.r - 50, 0),
	math.Max(itemCol.g - 50, 0),
	math.Max(itemCol.b - 50, 0),
	math.Min(itemCol.a + 50, 255))

local physboxCol = Color(0, 200, 255, 100)
local physboxTxtCol = Color(
	math.Max(physboxCol.r - 50, 0),
	math.Max(physboxCol.g - 50, 0),
	math.Max(physboxCol.b - 50, 0),
	math.Min(physboxCol.a + 50, 255))

local hitboxCol = Color(255, 10, 10, 50)

local function DrawOutlinedBox(x, y, w, h, thickness)
	for i = 1, thickness do
		local tx = x + (i - 1)
		local ty = y + (i - 1)
		local tw = w - 2 * (i - 1)
		local th = h - 2 * (i - 1)

		local x1, y1 = tx, ty
		local x2, y2 = tx + tw, ty
		local x3, y3 = tx + tw, ty + th
		local x4, y4 = tx, ty + th
		surface.DrawLine(x1, y1, x2, y2)
		surface.DrawLine(x2, y2, x3, y3)
		surface.DrawLine(x3, y3, x4, y4)
		surface.DrawLine(x4, y4, x1, y1)
	end
end

local function DrawItemDebug(pan)
	local x, y = pan:GetPos()
	local w, h = pan:GetSize()

	-- Draw box around object
	surface.SetDrawColor(itemCol)
	draw.NoTexture()
	surface.DrawRect(x, y, w, h)

	-- Text
	surface.SetTextColor(itemTxtCol)
	surface.SetFont("DFontTinier")

	local txt1 = "Item " .. (pan.ID or "??")
	local _, th = surface.GetTextSize(txt1)
	surface.SetTextPos(x, y + h)
	surface.DrawText(txt1)

	local txt2 = "(" .. x .. ", " .. y .. ")"
	surface.SetTextPos(x, y + h + th)
	surface.DrawText(txt2)

	local txt3 = w .. " x " .. h
	surface.SetTextPos(x, y + h + th * 2)
	surface.DrawText(txt3)
end

local function DrawPhysboxDebug(physbox)
	local parent = physbox.parent
	local x, y = parent:GetPos()
	local w, h = parent:GetSize()

	surface.SetDrawColor(physboxCol)
	draw.NoTexture()

	DrawOutlinedBox(x, y, w, h, 4)

	-- Text
	surface.SetTextColor(physboxTxtCol)
	surface.SetFont("DFontTinier")

	local txt1 = "VPhys #" .. (parent.ID or "??")
	local _, th = surface.GetTextSize(txt1)
	local txtx = x + w + 6
	surface.SetTextPos(txtx, y)
	surface.DrawText(txt1)

	if not physbox.isPhysicsEnabled then
		local txt2 = "Sleeping"
		surface.SetTextPos(txtx, y + th)
		surface.DrawText(txt2)
		return
	end

	local vx, vy = physbox.velocity:Unpack()
	local txt2 = "Vel: (" .. vx .. ", " .. vy .. ")"
	surface.SetTextPos(txtx, y + th)
	surface.DrawText(txt2)
end

local function DrawHitboxDebug(hitbox)
	local screenpoints = hitbox:GetHBScreenPointsObj()
	local poly = screenpoints:ToTable()

	surface.SetDrawColor(hitboxCol)
	draw.NoTexture()
	surface.DrawPoly(poly)
end

local function DrawCollisionPoint(cpoint)
	local s = 4
	local cx, cy = cpoint:Unpack()

	surface.SetDrawColor(COLOR_BLUE)
	draw.NoTexture()
	surface.DrawRect(cx - s * 0.5, cy - s * 0.5, s, s)
end

local function DrawItemBindPoints(item)
	if not item.gridPointEvaluator.bindPoints then return end

	local s = 4
	surface.SetDrawColor(COLOR_GREEN)
	for i = 1, #item.gridPointEvaluator.bindPoints do
		local point = item.gridPointEvaluator.bindPoints[i]
		local x, y = point:Unpack()
		surface.DrawRect(x - s * 0.5, y - s * 0.5, s, s)
	end
end

local function DrawBackpackBindPoints()
	if not IsValid(GAMEMODE.pGridInventory) then return end

	local backpack = GAMEMODE.backpack
	if not backpack then return end

	local s = 6
	surface.SetDrawColor(COLOR_BLACK)
	for i = 1, #backpack.cells do
		local cell = backpack.cells[i]
		local x, y = cell:GetAssocScreenBindPoint():Unpack()
		surface.DrawRect(x - s * 0.5, y - s * 0.5, s, s)
	end
end

local function DrawAux(physbox, hitbox)
	-- Box at the center
	surface.SetDrawColor(COLOR_BLACK)
	local xp, yp = physbox:GetCenterScreenPoint():Unpack()
	local s = 8
	surface.DrawRect(xp - s * 0.5, yp - s * 0.5, s, s)

	-- Box at the hitbox array origin point
	xp, yp = physbox:GetScreenHitboxPointsOrigin():Unpack()
	s = 6
	surface.DrawRect(xp - s * 0.5, yp - s * 0.5, s, s)
end

--[[
local function DrawRefLine(line)
	local points = line:GetPoints()
	local x1, y1 = points[1].x, points[1].y
	local x2, y2 = points[2].x, points[2].y
	surface.SetDrawColor(COLOR_GREEN)
	surface.DrawLine(x1, y1, x2, y2)
end

local function DrawIncLine(line)
	local points = line:GetPoints()
	local x1, y1 = points[1].x, points[1].y
	local x2, y2 = points[2].x, points[2].y
	surface.SetDrawColor(COLOR_PURPLE)
	surface.DrawLine(x1, y1, x2, y2)
end

local function DrawNormal(data)
	local bodyA = data.bodyA
	local normal = data.normal
	local referenceLine = data.referenceLine

	local points = referenceLine:GetPoints()
	local p1, p2 = points[1], points[2]
	local dir = (p2 - p1):GetNormalized()
	local dist = p1:Distance(p2)
	local startPos = p1 + dir * dist / 2

	local endPos = startPos + normal * 12

	surface.SetDrawColor(COLOR_BLUE)
	surface.DrawLine(startPos.x, startPos.y, endPos.x, endPos.y)
end
]]


local function DrawDebug()
	if not GAMEMODE.Debug then return end

	local detailed = GAMEMODE.DebugMode == DEBUG_MODE_DETAILED

	local constraints = PhysObj2D.collisionConstraints
	local cps = {}
	for fID, cobj in pairs(constraints) do
		table.insert(cps, cobj.screenPoint)
	end

	DrawBackpackBindPoints()

	for k, cpoint in pairs(cps) do DrawCollisionPoint(cpoint) end

	for obj, _ in pairs(GAMEMODE.itemObjs) do
		--if detailed then DrawItemDebug(obj) end

		local physbox = obj.physbox
		--if detailed then DrawPhysboxDebug(physbox) end

		if physbox.isPhysicsEnabled then
			for __, hitbox in pairs(physbox.hitboxes) do
				DrawHitboxDebug(hitbox)
			end
		end

		if detailed then DrawAux(physbox, hitbox) end

		DrawItemBindPoints(obj)

		--[[
		for k, line in pairs(refLines) do DrawRefLine(line) end
		for k, line in pairs(incLines) do DrawIncLine(line) end
		for k, data in pairs(normals) do DrawNormal(data) end
		]]
	end

	for wall, _ in pairs(GAMEMODE.physObjWalls) do
		local physbox = wall.physbox

		for __, hitbox in pairs(physbox.hitboxes) do
			DrawHitboxDebug(hitbox)
		end
	end
end

hook.Add("DrawOverlay", "DrawOverlay.Debug", DrawDebug)

--[[
hook.Add("VGUIPhysDetectCollisions", "VGUIPhysDetectCollisions.Debug", function()
	refLines = {}
	incLines = {}
	normals = {}
end)
]]