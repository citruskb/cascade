ITEM.id = "test_wooden_crate"
ITEM.name = "Wooden Crate"
ITEM.description = "It's just a crate."
ITEM.type = ITEM_TYPE_NORMAL

ITEM.model = "models/props_junk/wood_crate001a.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camOffScreenAdjScale = 0.6
ITEM.camOrthoAdjScale = 29

ITEM.triggerDelay = 4
ITEM.retriggerable = true

local s = 60
ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(s, 0),
			Vector2(s, s),
			Vector2(0, s)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
	[180] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
}

ITEM.DoActivate = function(me, other) end