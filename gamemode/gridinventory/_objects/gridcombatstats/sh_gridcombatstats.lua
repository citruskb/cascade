if not GridCombatStats then
	GridCombatStats = Class:Create(nil, "GridCombatStats")
end

local meta = FindMetaTable("GridCombatStats")

function GridCombatStats:__Create(roundNumber)
	self.health = 

	return self
end
function GridCombatStats:ToString()	return "[GridCombatStats]" end