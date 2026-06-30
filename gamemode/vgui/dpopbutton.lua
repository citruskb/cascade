PANEL = {}

function PANEL:Init()
	self:SetText("")
	--self:SetMouseInputEnabled(true)
	self.holdMinimum = 0.2
	self.delta = 0
	self.lerpDelta = 0
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

function PANEL:Think()
	self:CalculateDelta()

	local ct = CurTime()
	if not self:IsDown() then
		if self.lastPressed and self.lastPressed + self.holdMinimum < ct and self.delta == 1 then
			self:ButtonActivate()
		end

		self.lastPressed = nil
		return
	elseif self:IsDown() and not self.lastPressed then
		self.lastPressed = ct
	end
end

function PANEL:ButtonActivate()
	local backpack = GAMEMODE.backpack
	local items = {}
	for i = 1, #backpack.cells do
		local cell = backpack.cells[i]
		if not cell.heldItem then continue end
		items[cell.heldItem] = true
	end

	for item in pairs(items) do item:Pop() end
end

function PANEL:CalculateDelta()
	if not self.lastPressed then
		self.delta = 0
		return
	end

	local w, h = self:GetSize()
	local pos = Vector2(self:GetPos()) + Vector2(w * 0.5, h * 0.5)
	local dir = GAMEMODE.CachedMousePos - pos
	if pos:Dot(dir) <= 0 then
		self.delta = 0
		return
	end

	self.delta = math.Clamp(math.Remap(dir:Length(), 0, 120, 0, 1), 0, 1)
end

function PANEL:Paint()
	local x, y = 0, 0
	local w, h = self:GetSize()

	surface.SetDrawColor(COLOR_WHITE)
	draw.NoTexture()

	local buffer = 2
	local b2 = buffer * 2
	local b3 = buffer * 3

	DrawOutlinedBox(x + buffer, y + buffer, w - b2, h - b2, 2)

	self.lerpDelta = Lerp(0.33, self.lerpDelta, self.delta)

	surface.DrawPoly({
		{x = math.Min(b3 + self.lerpDelta * (w - b3 * 2), w - b3), y = h - b3},
		{x = w - b3, y = math.Min(b3 + self.lerpDelta * (w - b3 * 2), h - b3)},
		{x = w - b3, y = h - b3}
	})
end

vgui.Register("DPopButton", PANEL, "DButton")