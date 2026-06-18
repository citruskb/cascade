if not Combat then
	GM.Combats = {}
	Combat = Class:Create(nil, "Combat")
end

function Combat:__Create(plA, plB)
	self.plA = plA
	self.plB = plB
	self.backpackA = nil -- TODO
	self.backpackB = nil -- TODO

	self.healthA = GAMEMODE.starting_health
	self.healthB = GAMEMODE.starting_health

	self.resolved = false
end

function meta:Tick()

end

