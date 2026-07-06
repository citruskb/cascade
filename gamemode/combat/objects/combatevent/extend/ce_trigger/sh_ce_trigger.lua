if not CombatEventItemTrigger then
	local super = FindMetaTable("CombatEvent")
	CombatEventItemTrigger = Class:Create(super, "CombatEventItemTrigger")
end

local meta = FindMetaTable("CombatEventItemTrigger")

function CombatEventItemTrigger:__Create(timeStep, subStep, ownerEnum, backpackIDX, itemType)
	self:Init(timeStep, subStep)
	self.type = CE_ITEM_TRIGGER
end