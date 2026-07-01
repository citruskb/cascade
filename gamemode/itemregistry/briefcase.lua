ITEM.sid = ITEM_BRIEFCASE
ITEM.type = ITEM_TYPE_NORMAL

ITEM.id = "briefcase"
ITEM.name = "Briefcase"
ITEM.description = "When you enter the shop: +$1"
ITEM.rarity = ITEM_RARITY_BASIC

ITEM.model = "models/props_c17/BriefCase001a.mdl"
ITEM.modelScale = Vector(1, 1, 0.7)
ITEM.fov = 50
ITEM.camPos = Vector(0, 1, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 0)
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.16
ITEM.camOrthoAdjScale = 11.5

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(43, 0),
			Vector2(77, 0),
			Vector2(77, 12),
			Vector2(43, 12)}),
	[2] = Points({	Vector2(0, 12),
		Vector2(120, 12),
		Vector2(120, 80),
		Vector2(0, 80)}),
}

ITEM.gridPoints = {
	[ITEM_ORIENTATION_0] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[ITEM_ORIENTATION_90] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[ITEM_ORIENTATION_180] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[ITEM_ORIENTATION_270] = Points({Vector2(0, 0), Vector2(0, 1)}),
}
ITEM.gridPointsOffsets = {
	[ITEM_ORIENTATION_0] = Vector2(-25, -4),
	[ITEM_ORIENTATION_90] = Vector2(18, -42),
	[ITEM_ORIENTATION_180] = Vector2(-25, -4),
	[ITEM_ORIENTATION_270] = Vector2(18, -42),
}

ITEM.gridPointsSynergies = {}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 3)
	for i = 1, 3 do
		surface.PlaySound("physics/plaster/ceiling_tile_impact_soft" .. roll .. ".wav")
	end
end

ITEM.DoActivate = function(me, other) end