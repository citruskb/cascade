--[[
	The idea here is the combat log can be determined serverside almost immediately and networked to the client once.
	The client can effectively just play back this result.
	This prevents the client from determining whether they won or lost and avoids stutters due to latency.
	This has the benefit of creating the combat log too.
]]

if not CombatOrchestrator then
	CombatOrchestrator = Class:Create(nil, "CombatOrchestrator")
end

local meta = FindMetaTable("CombatOrchestrator")

function CombatOrchestrator:__Create(myBackpack, opponentBackpack)
	self.myBackpack = myBackpack
	self.opponentBackpack = opponentBackpack

	self.combatLog = CombatLog:Create(myBackpack, opponentBackpack)

	self.isCombatOrchestrator = true

	return self
end
function CombatOrchestrator:ToString() return "[CombatOrchestrator]" end