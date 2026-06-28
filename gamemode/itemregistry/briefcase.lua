ITEM.id = "briefcase"
ITEM.name = "Briefcase"
ITEM.description = "When you enter the shop: +$1"
ITEM.type = ITEM_TYPE_NORMAL
ITEM.rarity = ITEM_RARITY_BASIC

ITEM.model = "models/props_c17/BriefCase001a.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(0, 0, -1)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 0)
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.15
ITEM.camOrthoAdjScale = 10.8

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(120, 0),
			Vector2(120, 60),
			Vector2(0, 60)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[90] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[180] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[270] = Points({Vector2(0, 0), Vector2(0, 1)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(0, 0),
	[90] = Vector2(0, 0),
	[180] = Vector2(0, 0),
	[270] = Vector2(0, 0),
}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("physics/metal/metal_computer_impact_soft" .. math.Random(1, 3) .. ".wav")
end

ITEM.DoActivate = function(me, other) end

--models/props_c17/BriefCase001a.mdl