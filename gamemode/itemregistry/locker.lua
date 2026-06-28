ITEM.id = "locker"
ITEM.name = "Locker"
ITEM.description = "Stores items: 1x4\n\nWhen item inside triggers: +1 armor"
ITEM.type = ITEM_TYPE_CONTAINER
ITEM.rarity = ITEM_RARITY_EPIC

ITEM.model = "models/props_lab/lockerdoorsingle.mdl"
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
	[0] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)}),
	[180] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-6, -10),
	[90] = Vector2(-132, 115),
	[180] = Vector2(-6, -10),
	[270] = Vector2(-132, 115),
}

local PlaceSounds = {
	[1] = "doors/door_metal_thin_open1.wav",
	[2] = "doors/door_metal_thin_close2.wav",
	[3] = "doors/door_latch1.wav",
}
ITEM.PlayPlaceSound = function()
	surface.PlaySound(PlaceSounds[math.Random(1, 3)])
end

ITEM.DoActivate = function(me, other) end