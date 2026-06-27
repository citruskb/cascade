if not GridInventoryCell then
	GridInventoryCell = Class:Create(nil, "GridInventoryCell")
end

local meta = FindMetaTable("GridInventoryCell")

function GridInventoryCell:__Create()
	return self
end

function meta:IsCompletelyEmpty()
	return not self.heldBag and not self.heldItem
end

function meta:IsBagButEmpty()
	return self.heldBag and not self.heldItem
end