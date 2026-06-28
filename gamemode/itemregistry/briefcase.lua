ITEM.id = "briefcase"
ITEM.name = "Briefcase"
ITEM.description = "When you enter the shop: +$1"
ITEM.type = ITEM_TYPE_NORMAL
ITEM.rarity = ITEM_RARITY_BASIC

ITEM.model = "models/props_c17/BriefCase001a.mdl"
ITEM.fov = 56
ITEM.camPos = Vector(0, 1, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 0)
ITEM.camAngleOffsetAdj = 0
ITEM.camOffScreenAdjScale = 0.15
ITEM.camOrthoAdjScale = 13.4

ITEM.triggerDelay = 4
ITEM.retriggerable = true

ITEM.hitboxPoints = {
	[1] = Points({	Vector2(31.5, 0),
			Vector2(63, 0),
			Vector2(63, 15.75),
			Vector2(31.5, 15.75)}),
	[2] = Points({	Vector2(0, 15.75),
		Vector2(94.5, 15.75),
		Vector2(94.5, 84),
		Vector2(0, 84)}),
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[90] = Points({Vector2(0, 0), Vector2(0, 1)}),
	[180] = Points({Vector2(0, 0), Vector2(1, 0)}),
	[270] = Points({Vector2(0, 0), Vector2(0, 1)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-36, -1),
	[90] = Vector2(4, -42),
	[180] = Vector2(-36, -1),
	[270] = Vector2(4, -42),
}

ITEM.PlayPlaceSound = function()
	local roll = math.Random(1, 3)
	for i = 1, 3 do
		surface.PlaySound("physics/plaster/ceiling_tile_impact_soft" .. roll .. ".wav")
	end
end

ITEM.DoActivate = function(me, other) end