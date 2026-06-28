ITEM.id = "pocket_dimension"
ITEM.name = "Pocket Dimension"
ITEM.description = "Stores items: 1x1\n\nEvery 12 seconds: cleanse 1 random debuff and gain 1 random buff"
ITEM.type = ITEM_TYPE_CONTAINER
ITEM.rarity = ITEM_RARITY_LEGENDARY

ITEM.model = "models/props_combine/breentp_rings.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(0.5, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 4)
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 1.68
ITEM.camOrthoAdjScale = 76

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 45),
			Vector2(16.5, 12),
			Vector2(45, 0),
			Vector2(73.5, 12),
			Vector2(90, 45),
			Vector2(73.5, 78),
			Vector2(45, 90),
			Vector2(16.5, 78)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0)}),
	[90] = Points({Vector2(0, 0)}),
	[180] = Points({Vector2(0, 0)}),
	[270] = Points({Vector2(0, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(4, 4),
	[90] = Vector2(4, 4),
	[180] = Vector2(4, 4),
	[270] = Vector2(4, 4),
}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("weapons/physcannon/energy_bounce" .. math.Random(1, 2) .. ".wav")
end

ITEM.DoActivate = function(me, other) end