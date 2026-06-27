if not GridInventoryCell then
	GridInventoryCell = Class:Create(nil, "GridInventoryCell")
end

local meta = FindMetaTable("GridInventoryCell")

function GridInventoryCell:__Create(id_or_x, y)
	if id_or_x and y then
		self.x, self.y = id_or_x, y
		self.id = self:EvaluateID(self.x, self.y)
	else
		self.id = id_or_x
		self.x, self.y = self:EvaluateCoords(self.id)
	end

	return self
end

function meta:EvaluateID() return gamemode.Call("GridInventoryCoordsToCellID", self.x, self.y) end
function meta:EvaluateCoords() return gamemode.Call("GridInventoryCellIDToCoords", self.id) end

function meta:IsCompletelyEmpty() return not self.heldContainer and not self.heldItem end
function meta:IsContainerButEmpty() return self.heldContainer and not self.heldItem end
function meta:IsFilled() return self.heldContainer and self.heldItem end
function meta:IsFilledButShouldntBe() return not self.heldContainer and self.heldItem end

function meta:GetAssocScreenBindPoint()
	if not self.bindPointIndex then Error("[GridInventoryCell] - Unbound cell.") end
	return GAMEMODE.screenBindPointsByID[self.bindPointIndex]
end