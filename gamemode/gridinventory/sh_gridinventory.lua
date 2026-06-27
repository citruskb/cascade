if not GridInventory then
	GridInventory = Class:Create(nil, "GridInventory")
end

local meta = FindMetaTable("GridInventory")

function GridInventory:__Create(w, h)
	self.w = w
	self.h = h

	self.cells = {}
	self:SetupCells()

	return self
end