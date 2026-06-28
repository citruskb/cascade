ITEM.id = "wooden_crate"
ITEM.name = "Wooden Crate"
ITEM.description = "Stores items: 2x2"
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.model = "models/props_junk/wood_crate001a.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.25
ITEM.camOrthoAdjScale = 29

ITEM.triggerDelay = 4
ITEM.retriggerable = true

local s = 160
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
ITEM.gridPointsOffsets = {
	[0] = Vector2(-4, -4),
	[90] = Vector2(-4, -4),
	[180] = Vector2(-4, -4),
	[270] = Vector2(-4, -4),
}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 4)
	for i = 1, 4 do
		surface.PlaySound("player/footsteps/woodpanel" .. roll .. ".wav")
	end
end

ITEM.DoActivate = function(me, other) end