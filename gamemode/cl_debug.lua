GM.Debug = true -- TODO move to a convar.

local itemCol = Color(255, 255, 0, 60)
local itemTxtCol = Color(
	math.Max(itemCol.r - 50, 0),
	math.Max(itemCol.g - 50, 0),
	math.Max(itemCol.b - 50, 0),
	math.Min(itemCol.a + 50, 255))
local function DrawItemDebug(pan)
	local x, y = pan:GetPos()
	local w, h = pan:GetSize()

	surface.SetDrawColor(itemCol)
	draw.NoTexture()
	surface.DrawRect(x, y, w, h)

	print("item w h", w, h)

	surface.SetTextColor(itemTxtCol)
	surface.SetFont("DFontTinier")

	local txt1 = "Item #" .. pan.ID
	local _, th = surface.GetTextSize(txt1)
	surface.SetTextPos(x, y + h)
	surface.DrawText(txt1)

	local txt2 = "(" .. x .. "," .. y .. ")"
	surface.SetTextPos(x, y + h + th)
	surface.DrawText(txt2)

	local txt3 = w .. " x " .. h
	surface.SetTextPos(x, y + h + th * 2)
	surface.DrawText(txt3)
end

local physboxCol = Color(0, 200, 255, 100)
local itemPhysboxCol = Color(
	math.Max(physboxCol.r - 50, 0),
	math.Max(physboxCol.g - 50, 0),
	math.Max(physboxCol.b - 50, 0),
	math.Min(physboxCol.a + 50, 255))

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
local function DrawPhysboxDebug(pan)
	local x, y = pan:GetPos()
	x, y = pan:LocalToScreen(x, y)
	local w, h = pan:GetSize()

	print("physbox w h", w, h)

	surface.SetDrawColor(physboxCol)
	draw.NoTexture()

	DrawOutlinedBox(x, y, w, h, 4)

	surface.SetTextColor(itemPhysboxCol)
	surface.SetFont("DFontTinier")

	local txt1 = "Phys #" .. pan.ID
	local _, th = surface.GetTextSize(txt1)
	surface.SetTextPos(x + w + 6, y)
	surface.DrawText(txt1)

	if not pan.Physics then
		local txt2 = "Sleeping"
		surface.SetTextPos(x + w + 6, y + th)
		surface.DrawText(txt2)
		return
	end

	local vx, vy = pan:GetVel()
	local txt2 = "Vel: (" .. vx .. "," .. vy .. ")"
	surface.SetTextPos(x, y + h + th)
	surface.DrawText(txt2)
end


local function DrawDebug()
	if not GAMEMODE.Debug then return end

	for pan, _ in pairs(GAMEMODE.VGUIItems) do DrawItemDebug(pan) end
	for pan, _ in pairs(GAMEMODE.VGUIPhysboxes) do DrawPhysboxDebug(pan) end
end

hook.Add("DrawOverlay", "DrawOverlay.Debug", DrawDebug)