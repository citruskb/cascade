ITEM.id = "plank"
ITEM.name = "Plank"
ITEM.description = "1-2 damage.\n\nOn hit: triggers 4% faster until you miss"
ITEM.type = ITEM_TYPE_NORMAL
ITEM.rarity = ITEM_RARITY_BASIC

ITEM.model = "models/props_debris/wood_chunk04b.mdl"
ITEM.modelScale = Vector(1, 1.4, 1)
ITEM.fov = 45
ITEM.camPos = Vector(1.2, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 0)
ITEM.camAngleOffsetAdj = 180
ITEM.camOffScreenAdjScale = 0.354
ITEM.camOrthoAdjScale = 26

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
		Vector2(38, 0),
		Vector2(38, 80),
		Vector2(0, 80)}),
	[2] = Points({	Vector2(0, 80),
		Vector2(38, 80),
		Vector2(26, 140)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[180] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-23, -20),
	[90] = Vector2(-66, 28),
	[180] = Vector2(-23, -20),
	[270] = Vector2(-66, 28),
}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("physics/wood/wood_box_impact_bullet" .. math.Random(1, 3) .. ".wav")
end

ITEM.DoActivate = function(me, other) end