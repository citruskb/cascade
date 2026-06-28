ITEM.id = "harddrive"
ITEM.name = "Harddrive"
ITEM.description = "Stores items: 1x2\n\nOn combat start: items inside trigger +10% faster"
ITEM.type = ITEM_TYPE_CONTAINER
ITEM.rarity = ITEM_RARITY_UNCOMMON

ITEM.model = "models/props_lab/harddrive02.mdl"
ITEM.fov = 56
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, -2)
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.123
ITEM.camOrthoAdjScale = 10.8

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(60, 0),
			Vector2(60, 165),
			Vector2(0, 165)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[180] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-13, -2),
	[90] = Vector2(-55, 38),
	[180] = Vector2(-13, -2),
	[270] = Vector2(-55, 38),
}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("physics/metal/metal_computer_impact_soft" .. math.Random(1, 3) .. ".wav")
end

ITEM.DoActivate = function(me, other) end