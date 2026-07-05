ITEM.sid = ITEM_C_NIGHTSTAND
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.id = "nightstand"
ITEM.name = "Nightstand"
ITEM.description = "Holds items: 1x3\n\n-1 fatigue damage taken"
ITEM.rarity = ITEM_RARITY_RARE

ITEM.model = "models/props_c17/FurnitureDrawer003a.mdl"
ITEM.modelScale = Vector(1, 1, 0.83)
ITEM.fov = 50
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.138
ITEM.camOrthoAdjScale = 20

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(93, 0),
			Vector2(93, 271),
			Vector2(0, 271)}),
}

ITEM.gridPoints = {
	[ITEM_ORIENTATION_0] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)}),
	[ITEM_ORIENTATION_90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)}),
	[ITEM_ORIENTATION_180] = Points({Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)}),
	[ITEM_ORIENTATION_270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)}),
}
ITEM.gridPointsOffsets = {
	[ITEM_ORIENTATION_0] = Vector2(4, 6),
	[ITEM_ORIENTATION_90] = Vector2(-84, 91),
	[ITEM_ORIENTATION_180] = Vector2(4, 6),
	[ITEM_ORIENTATION_270] = Vector2(-84, 91),
}

ITEM.gridPointsSynergies = {}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 4)
	for i = 1, 2 do
		surface.PlaySound("player/footsteps/woodpanel" .. roll .. ".wav")
	end
	surface.PlaySound("ambient/materials/wood_creak" .. (roll + 1) .. ".wav")
end

ITEM.DoActivate = function(me, other) end