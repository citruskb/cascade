ITEM.sid = ITEM_C_WOODEN_CRATE
ITEM.type = ITEM_TYPE_CONTAINER

ITEM.id = "wooden_crate"
ITEM.name = "Wooden Crate"
ITEM.description = "Holds items: 2x2"
ITEM.rarity = ITEM_RARITY_BASIC

ITEM.model = "models/props_junk/wood_crate001a.mdl"
ITEM.modelScale = Vector(1, 1, 1)
ITEM.fov = 60
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.22
ITEM.camOrthoAdjScale = 29

ITEM.triggerDelay = 4
ITEM.retriggerable = true

local s = 180
ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(s, 0),
			Vector2(s, s),
			Vector2(0, s)}),
}

ITEM.gridPoints = {
	[ITEM_ORIENTATION_0] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
	[ITEM_ORIENTATION_90] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
	[ITEM_ORIENTATION_180] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
	[ITEM_ORIENTATION_270] = Points({Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)}),
}
ITEM.gridPointsOffsets = {
	[ITEM_ORIENTATION_0] = Vector2(2, 2),
	[ITEM_ORIENTATION_90] = Vector2(2, 2),
	[ITEM_ORIENTATION_180] = Vector2(2, 2),
	[ITEM_ORIENTATION_270] = Vector2(2, 2),
}

ITEM.gridPointsSynergies = {}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 4)
	for i = 1, 4 do
		surface.PlaySound("player/footsteps/woodpanel" .. roll .. ".wav")
	end
end

ITEM.DoActivate = function(me, other) end