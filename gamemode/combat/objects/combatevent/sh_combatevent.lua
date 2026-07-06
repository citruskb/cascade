if not CombatEvent then
	CombatEvent = Class:Create(nil, "CombatEvent")
end

local meta = FindMetaTable("CombatEvent")

--[[ Round win or loss screen.
Pass:
the winner.
]]
CE_ENDED = 1			-- A winner was decided.

--[[ Play visual effect of item attacking target. Damage taken by target.
Pass:
the item causing damage (if caused by an item)
damage type
damage amount
damage target
]]
CE_DAMAGE = 2			-- Damage (melee, ranged, unaspected, toxic, fatigue)

--[[ Apply healing to target.
Pass:
healing amount.
healing target.
]]
CE_HEAL = 3			-- Healing

--[[ Play the visual trigger effect. Do the "on trigger" effect.
Pass:
The board. (either 1 or 2, 1 = mine, 2 = opponent's)
The backpack grid location of the itemObj triggered.
The itemObj type.
]]
CE_ITEM_TRIGGER = 4	-- An item triggered.

CE_TO_NAME = {
	[CE_ENDED] = "round_ended",
	[CE_DAMAGE] = "damage",
	[CE_HEAL] = "heal",
	[CE_ITEM_TRIGGER] = "item_trigger"
}

function CombatEvent:__Create()
	Error("[CE] - you should never be creating this base class directly.")
end

function CombatEvent:ToString()
	local suffix = ToString(CE_TO_NAME[self.eventType])
	if not suffix then Error("[CE] - invalid ToString().") end

	return "[CE_" .. suffix .. "]"
end

function meta:Init(timeStep, subStep)
	self.timeStep = timeStep
	self.subStep = subStep
end