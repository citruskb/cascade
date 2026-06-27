if not GridInventory then
	GridInventory = Class:Create(nil, "GridInventory")
end

local meta = FindMetaTable("GridInventory")

function GridInventory:__Create(w, h)
	self.w = w or GAMEMODE.BackpackGridX
	self.h = h or GAMEMODE.BackpackGridY

	self.cells = {}
	self.cellsScreenIDX = {}
	self:SetupCells()

	return self
end

function meta:SetupCells()
	for row = 1, self.h do
		for col = 1, self.w do
			local cell = GridInventoryCell:Create(col, row)
			self.cells[cell.id] = cell
		end
	end
end

function meta:BindToPanel(pan)
	for i = 1, #pan.grid:GetItems() do
		self.cells[i].bindPointIndex = pan.bindPointIndexes[i]
		self.cellsScreenIDX[pan.bindPointIndexes[i]] = self.cells[i]
	end
end