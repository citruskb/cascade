ITEM.sid = ITEM_C_LOCKER
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.id = "locker"
ITEM.name = "Locker"
ITEM.description = "Holds items: 1x4\n\nWhen item inside triggers: +1 armor"
ITEM.rarity = ITEM_RARITY_EPIC

ITEM.model = "models/props_lab/lockerdoorsingle.mdl"
ITEM.modelScale = Vector(1, 1, 1)
ITEM.fov = 53
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.194
ITEM.camOrthoAdjScale = 32

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(75, 0),
			Vector2(75, 320),
			Vector2(0, 320)}),
}

ITEM.gridPoints = {
	[ITEM_ORIENTATION_0] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)}),
	[ITEM_ORIENTATION_90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)}),
	[ITEM_ORIENTATION_180] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)}),
	[ITEM_ORIENTATION_270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)}),
}
ITEM.gridPointsOffsets = {
	[ITEM_ORIENTATION_0] = Vector2(-6, -10),
	[ITEM_ORIENTATION_90] = Vector2(-132, 115),
	[ITEM_ORIENTATION_180] = Vector2(-6, -10),
	[ITEM_ORIENTATION_270] = Vector2(-132, 115),
}

ITEM.gridPointsSynergies = {}

local PlaceSounds = {
	[1] = "doors/door_metal_thin_open1.wav",
	[2] = "doors/door_metal_thin_close2.wav",
	[3] = "doors/door_latch1.wav",
}
ITEM.PlayPlaceSound = function()
	surface.PlaySound(PlaceSounds[math.Random(1, 3)])
end

ITEM.DoActivate = function(me, other) end