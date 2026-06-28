ITEM.id = "nightstand"
ITEM.name = "Nightstand"
ITEM.description = "Stores items: 1x3\n\n-1 fatigue damage taken"
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.model = "models/props_c17/FurnitureDrawer003a.mdl"
ITEM.fov = 57
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.18
ITEM.camOrthoAdjScale = 23.5

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(70, 0),
			Vector2(70, 249),
			Vector2(0, 249)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)}),
	[90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)}),
	[180] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)}),
	[270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-8, -4),
	[90] = Vector2(-93, 83),
	[180] = Vector2(-8, -4),
	[270] = Vector2(-93, 83),
}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 4)
	for i = 1, 2 do
		surface.PlaySound("player/footsteps/woodpanel" .. roll .. ".wav")
	end
	surface.PlaySound("ambient/materials/wood_creak" .. (roll + 1) .. ".wav")
end

ITEM.DoActivate = function(me, other) end