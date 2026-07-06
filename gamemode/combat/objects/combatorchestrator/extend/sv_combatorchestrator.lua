local meta = FindMetaTable("CombatOrchestrator")


function meta:Start()
	-- Validate both backpacks.

	-- Initialize time.
	self.startTime = CurTime()
	self.curStep = 0
	self.fatigueStartTime = self.startTime + 45
	self.elapsedTime = 0

	-- Go through backpacks. Initialize item trigger timers.

	-- Do all "on combat start" calls.
	-- TODO: Need a way to prioritize on combat start calls.
	-- ie. "On combat start: Reflect 3 debuffs." should happen before "On combat start: Apply 6 toxic to your opponent."
end

-- Step combat by dt.
-- This should be networked back to the player.
function meta:Step(dt)
	local ct = CurTime()
	if self.startTime > ct then return end

	self.curStep = self.curStep + 1

	-- Advance elapsed time by that much. 

	-- After each evaluation here we need to check if the combat has ended.

	-- Advance item trigger timers. If items should trigger, then trigger them!
	-- Priority goes to the "most negative" trigger, and carry-over is handled. Then check if combat has ended.
	-- Items set to trigger at the same time, trigger in parallel and check if combat has ended after both trigger.

	-- Need to advance regen, debuffs, and fatigue too.
end

-- Checks if either opponent's health has reached zero (or lower)
-- In the event both are zero or lower simultaneously, whoever has the "least negative" health is the winner.
-- In the event of a tie, the player wins.
function meta:EvaluateCombatEnd()
end