ITEM.id = "nightstand"
ITEM.name = "Nightstand"
ITEM.description = "-2 fatigue damage taken."
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.model = "models/props_c17/FurnitureDrawer003a.mdl"
ITEM.fov = 57
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camOffScreenAdjScale = 0.14
ITEM.camOrthoAdjScale = 23.5

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(90, 0),
			Vector2(90, 320),
			Vector2(0, 320)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)}),
	[180] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(2, -10),
	[90] = Vector2(-127, 115),
	[180] = Vector2(2, -10),
	[270] = Vector2(-127, 115),
}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 4)
	for i = 1, 2 do
		surface.PlaySound("player/footsteps/woodpanel" .. roll .. ".wav")
	end
	surface.PlaySound("ambient/materials/wood_creak" .. (roll + 1) .. ".wav")
end

ITEM.DoActivate = function(me, other) end