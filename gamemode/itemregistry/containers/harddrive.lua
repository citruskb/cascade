ITEM.sid = ITEM_C_HARDDRIVE
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.id = "harddrive"
ITEM.name = "Harddrive"
ITEM.description = "Holds items: 1x2\n\nOn combat start: items inside trigger +10% faster"
ITEM.rarity = ITEM_RARITY_UNCOMMON

ITEM.model = "models/props_lab/harddrive02.mdl"
ITEM.modelScale = Vector(1, 1.2, 0.85)
ITEM.fov = 50
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 0)
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.098
ITEM.camOrthoAdjScale = 10

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(96, 0),
			Vector2(96, 183),
			Vector2(0, 183)}),
}

ITEM.gridPoints = {
	[ITEM_ORIENTATION_0] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[ITEM_ORIENTATION_90] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[ITEM_ORIENTATION_180] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[ITEM_ORIENTATION_270] = Points({Vector2(0, 0), Vector2(1, 0)}),
}
ITEM.gridPointsOffsets = {
	[ITEM_ORIENTATION_0] = Vector2(4, 6),
	[ITEM_ORIENTATION_90] = Vector2(-44, 48),
	[ITEM_ORIENTATION_180] = Vector2(4, 2),
	[ITEM_ORIENTATION_270] = Vector2(-40, 48),
}

ITEM.gridPointsSynergies = {}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("physics/metal/metal_computer_impact_soft" .. math.Random(1, 3) .. ".wav")
end

ITEM.DoActivate = function(me, other) end