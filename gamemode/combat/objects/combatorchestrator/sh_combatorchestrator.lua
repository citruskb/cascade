--[[
	The idea here is the combat log can be determined serverside almost immediately and networked to the client once.
	The client can just play back this result.
	This keeps winning and losing server authoritating and avoids stutters due to latency.
	This has the benefit of creating a combat log too. (far future TODO)

	However, when saving match history, we want to take a different approach. The full combat log can get loooooong.
	So instead we save our board, our opponent's board, and if we won or lost.
	We can also run quick simulations to see what the odds of beating their board are.
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