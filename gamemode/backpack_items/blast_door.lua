ITEM.id = "blast_door"
ITEM.name = "Blast Door"
ITEM.description = "Imprenable."

ITEM.model = "models/props_lab/blastdoor001c.mdl"
ITEM.fov = 55
ITEM.camPos = Vector(1, 0, 0)

ITEM.triggerDelay = 0
ITEM.retriggerable = false

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(225, 0),
			Vector2(225, 142),
			Vector2(0, 142)}),
}

ITEM.gridPoints = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)})

ITEM.DoActivate = function(me, other) end