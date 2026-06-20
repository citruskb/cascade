ITEM.id = "wooden_crate"
ITEM.name = "Wooden Crate"
ITEM.description = "It's just a crate."

ITEM.model = "models/props_junk/wood_crate001a.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(1, 0, 0)

ITEM.triggerDelay = 4
ITEM.retriggerable = true
ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(30, 0),
			Vector2(30, 30),
			Vector2(0, 30)}),
}

ITEM.gridPoints = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)})

ITEM.DoActivate = function(me, other) end