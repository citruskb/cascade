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

-- Build our cells. Used only during init.
function meta:SetupCells()
	for row = 1, self.h do
		for col = 1, self.w do
			local cell = GridInventoryCell:Create(col, row)
			self.cells[cell.id] = cell
		end
	end
end

-- Synchronize a backpack obj with a vgui panel representing said object.
function meta:BindToPanel(pan)
	for i = 1, #pan.grid:GetItems() do
		self.cells[i].bindPointIndex = pan.bindPointIndexes[i]
		self.cellsScreenIDX[pan.bindPointIndexes[i]] = self.cells[i]
	end
end

-- Return the item held in a specific cell.
function meta:GetItemAt(idx)
	if not self.cells[idx] then return end
	return self.cells[idx].heldItem
end

-- Return an iterable list of all containers we hold.
function meta:GetHeldContainers()
	local tab = {}
	for i = 1, #self.cells do
		local cell = self.cells[i]
		if not cell.heldContainer then continue end

		tab[cell.heldContainer] = true
	end

	return table.ToKeyValues(tab)
end

-- Return an iterable list of all items (not including containers) we hold
function meta:GetHeldItems()
	local tab = {}
	for i = 1, #self.cells do
		local cell = self.cells[i]
		if not cell.heldItem then continue end

		tab[cell.heldItem] = true
	end

	return table.ToKeyValues(tab)
end

-- Clear red/green highlight draws on all our cells.
function meta:ClearGridDraw()
	for i = 1, #self.cells do
		local cell = self.cells[i]
		cell.canPlaceDraw = nil
		cell.cannotPlaceDraw = nil
	end
end

-- Delete all items inside ourself.
function meta:Clear()
	local allContainers = self:GetHeldContainers()
	for i = 1, #allContainers do allContainers[i]:Remove() end

	local allItems = self:GetHeldItems()
	for i = 1, #allItems do allItems[i]:Remove() end
end

-- Return items that are contained inside our cells but outside of containers to the physics inventory.
-- Doubles to make sure that serverside what is contained is legal.
function meta:Validate()
	for i = 1, #self.cells do
		local cell = self.cells[i]

		if not cell:IsFilledButShouldntBe() then continue end
		cell.heldItem:Pop()
	end
end
