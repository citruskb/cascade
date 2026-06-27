PANEL = {}

function PANEL:Init()
	self.bindPointIndexes = {}
	self.grid = vgui.Create("DGrid", self)

	local gridCountWide, gridCountHigh = GAMEMODE.BackpackGridX, GAMEMODE.BackpackGridY
	local cellSiz = gamemode.Call("GetInventoryGridSize")

	self.grid:SetCols(gridCountWide)
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
		self.bindPointIndexes[i] = GAMEMODE:GetNearestScreenBindPointIndex(Vector2(cells[i]:GetPos()))
	end

	local backpack = GridInventory:Create()
	backpack:BindToPanel(self)
	GAMEMODE.backpack = backpack
end

function PANEL:PerformLayout()
end

function PANEL:Paint() end


vgui.Register("DGridInventory", PANEL, "DPanel")