if not CombatLog then
	CombatLog = Class:Create(nil, "CombatLog")
end

local meta = FindMetaTable("CombatLog")

function CombatLog:__Create(myBackpack, opponentBackpack)
	self.myBackpack = myBackpack
	self.opponentBackpack = opponentBackpack
	self.log = {}

	self.isCombatLog = true

	return self
end
function CombatLog:ToString() return "[CombatLog]" end