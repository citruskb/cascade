ITEM.id = "blast_door"
ITEM.name = "Blast Door"
ITEM.description = "Imprenable."
ITEM.type = ITEM_TYPE_NORMAL

ITEM.model = "models/props_lab/blastdoor001c.mdl"
ITEM.fov = 55
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camOffScreenAdjScale = 0.75
ITEM.camOrthoAdjScale = 102

ITEM.triggerDelay = 0
ITEM.retriggerable = false

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(225, 0),
			Vector2(225, 142),
			Vector2(0, 142)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2), Vector2(1, 2)}),
	[180] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2), Vector2(1, 2)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-18, -16),
	[90] = Vector2(25, -56),
	[180] = Vector2(-18, -16),
	[270] = Vector2(25, -56),
}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("doors/door_metal_large_chamber_close1.wav")
	surface.PlaySound("player/footsteps/metalgrate" .. math.Random(1, 4) .. ".wav")
end

ITEM.DoActivate = function(me, other) end