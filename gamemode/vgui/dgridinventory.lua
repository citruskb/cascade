PANEL = {}

function PANEL:Init()
	self.bindPoints = {}
	self.grid = vgui.Create("DGrid", self)

	local gridCountWide, gridCountHigh = GAMEMODE.BackpackGridX, GAMEMODE.BackpackGridY
	local w, h = ScrW() * 0.4, ScrH() * 0.6

	--self.grid:SetSize(w, h)
	--self.grid:SetPos(0, 0)

	local colWide = math.Floor(w / gridCountWide)
	local rowHigh = math.Floor(h / gridCountHigh)
	local cellSiz = colWide

	self.grid:SetCols(GAMEMODE.BackpackGridX)
	self.grid:SetColWide(cellSiz)
	self.grid:SetRowHeight(cellSiz)

	for row = 1, gridCountHigh do
		for col = 1, gridCountWide do
			local cell = vgui.Create("DGridCell")
			cell:SetSize(cellSiz, cellSiz)

			-- DGrid:AddItem() doesn't update the cached item position from LocalToScreen for some reason.
			cell:SetPos((col - 1) * cellSiz, (row - 1) * cellSiz)

			cell.row = row
			cell.col = col

			self.grid:AddItem(cell)
		end
	end

	local cells = self.grid:GetItems()
	for i = 1, #cells do
		local x, y = cells[i]:GetPos()
		self.bindPoints[i] = Vector2(x + cellSiz / 2, y + cellSiz / 2)
	end
end

function PANEL:PerformLayout()
end

function PANEL:Paint() end


vgui.Register("DGridInventory", PANEL, "DPanel")