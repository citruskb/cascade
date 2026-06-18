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
	self.contents = {}

	self.grid = {}

	return self
end

function Backpack:ToString()
	return self.owner and self.ownerNick .. "'s Backpack" or "Backpack #" .. self.id
end

function meta:CoordsToGridIDX(x, y)
	return
		((x - 1) * GAMEMODE.BackpackGridX) +
		(x - 1) % GAMEMODE.BackpackGridX +
		1
end
function meta:GridIDXToCoords(idx)
	local x, y
	x = ((idx - 1) % GAMEMODE.BackpackGridX) + 1
	y = ((idx - x) / GAMEMODE.BackpackGridX) + 1
	return x, y
end