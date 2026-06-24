-- 9 x 7 = 63
GM.BackpackGridX = 9
GM.BackpackGridY = 7

if not Backpack then
	GM.Backpacks = {}
	Backpack = Class:Create(nil, "Backpack")
end

local meta = FindMetaTable("Backpack")

function Backpack:__Create(owner)
	self.id = #GAMEMODE.Backpacks + 1
	GAMEMODE.Backpacks[self.id] = self

	self.owner = owner
	self.ownerNick = owner and owner:Nick()
	self.ownerSteamID = owner and owner:SteamID64()

	self.cells = {}
	self:SetupCells()

	return self
end

function Backpack:ToString()
	return self.owner and self.ownerNick .. "'s Backpack" or "Backpack #" .. self.id
end

function meta:SetupCells()
	for row = 1, GAMEMODE.BackpackGridY do
		for col = 1, GAMEMODE.BackpackGridX do
			local cell = BackpackCell:Create(self, col, row)
			self.cells[cell.id] = cell
		end
	end
end