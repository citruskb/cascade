if not CombatEvent then
	CombatEvent = Class:Create(nil, "CombatEvent")
end

local meta = FindMetaTable("CombatEvent")

--[[ Round win or loss screen.
Pass:
the winner.
]]
COMBAT_EVENT_ENDED = 1			-- A winner was decided.

--[[ Play visual effect of item attacking target. Damage taken by target.
Pass:
the item causing damage (if caused by an item)
damage type
damage amount
damage target
]]
COMBAT_EVENT_DAMAGE = 2			-- Damage (melee, ranged, unaspected, toxic, fatigue)

--[[ Apply healing to target.
Pass:
healing amount.
healing target.
]]
COMBAT_EVENT_HEAL = 3			-- Healing

--[[ Play the visual trigger effect. Do the "on trigger" effect.
Pass:
id of item triggered
]]
COMBAT_EVENT_ITEM_TRIGGER = 4	-- An item triggered.

function CombatEvent:__Create(timeStep, subStep, eventType, eventData)
	self.timeStep = timeStep
	self.subStep = subStep
	self.eventType = eventType

	self:SetupEvent(eventData)

	self.isCombatEvent = true

	return self
end
function CombatEvent:ToString() return "[CombatEvent]" end