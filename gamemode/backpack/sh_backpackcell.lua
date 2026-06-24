if not BackpackCell then
	GM.BackpackCells = {}
	BackpackCell = Class:Create(nil, "BackpackCell")
end

local meta = FindMetaTable("BackpackCell")

function BackpackCell:__Create(backpack, id_or_x, y)
	self.backpack = backpack

	if not IsNumber(id_or_x) then
		self.x, self.y = id_or_x, y
		self.id = self:CoordsToGridID(self.x, self.y)
	else
		self.id = id_or_x
		self.x, self.y = self:GridIDToCoors(self.id)
	end
end

function meta:CoordsToCellID(x, y)
	return
		((x - 1) * GAMEMODE.BackpackGridX) +
		(x - 1) % GAMEMODE.BackpackGridX +
		1
end
function meta:CellIDToCoords(id)
	local x, y
	x = ((idx - 1) % GAMEMODE.BackpackGridX) + 1
	y = ((idx - x) / GAMEMODE.BackpackGridX) + 1
	return x, y
end