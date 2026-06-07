GM.Debug = true -- TODO move to a convar.

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

local hitboxCol = Color(255, 10, 10, 200)
local hitboxTxtCol = Color(
	math.Max(physboxCol.r - 50, 0),
	math.Max(physboxCol.g - 50, 0),
	math.Max(physboxCol.b - 50, 0),
	math.Min(physboxCol.a + 50, 255))

local function DrawCross(x, y, len, col)
	if col then surface.SetDrawColor(col) end

	local x1, y1 = x - 0.5 * len, y - 0.5 * len
	local x2, y2 = x + 0.5 * len, y + 0.5 * len
	surface.DrawLine(x1, y1, x2, y2)
	surface.DrawLine(x2, y1, x1, y2)
end
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

	local txt1 = "Item #" .. pan.ID
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
	local parent = physbox:GetParent()
	local x, y = parent:GetPos()
	local w, h = parent:GetSize()

	surface.SetDrawColor(physboxCol)
	draw.NoTexture()

	DrawOutlinedBox(x, y, w, h, 4)

	-- Text
	surface.SetTextColor(physboxTxtCol)
	surface.SetFont("DFontTinier")

	local txt1 = "VPhys #" .. parent.ID
	local _, th = surface.GetTextSize(txt1)
	local txtx = x + w + 6
	surface.SetTextPos(txtx, y)
	surface.DrawText(txt1)

	if not physbox:IsPhysicsEnabled() then
		local txt2 = "Sleeping"
		surface.SetTextPos(txtx, y + th)
		surface.DrawText(txt2)
		return
	end

	local vx, vy = physbox:GetVel():Unpack()
	local txt2 = "Vel: (" .. vx .. ", " .. vy .. ")"
	surface.SetTextPos(txtx, y + th)
	surface.DrawText(txt2)
end

local function DrawHitboxDebug(hitbox)
	local physbox = hitbox:GetPhysbox()

	local points = hitbox:GetPoints()
	local origin = physbox:GetPointsOrigin()
	local screenpoints = points:Translate(origin)

	surface.SetDrawColor(hitboxCol)
	draw.NoTexture()
	surface.DrawPoly(screenpoints:ToTable())
end

local function DrawAux(pan, physbox, hitbox)
	-- Box at the center
	surface.SetDrawColor(COLOR_BLACK)
	local xp, yp = pan:GetCenterPos():Unpack()
	local s = 8
	surface.DrawRect(xp - s * 0.5, yp - s * 0.5, s, s)

	-- Box at the origin point
	xp, yp = physbox:GetPointsOrigin():Unpack()
	s = 6
	surface.DrawRect(xp - s * 0.5, yp - s * 0.5, s, s)
end


local function DrawDebug()
	if not GAMEMODE.Debug then return end

	for pan, _ in pairs(GAMEMODE.VGUIItems) do
		DrawItemDebug(pan)

		local physbox = pan.Physbox
		DrawPhysboxDebug(physbox)

		for _, hitbox in pairs(physbox:GetHitboxes()) do
			DrawHitboxDebug(hitbox)
		end

		DrawAux(pan, physbox, hitbox)
	end
end

hook.Add("DrawOverlay", "DrawOverlay.Debug", DrawDebug)