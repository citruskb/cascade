ITEM.id = "hula_doll"
ITEM.name = "Hula Doll"
ITEM.description = "It's all in the hips."
ITEM.type = ITEM_TYPE_NORMAL

ITEM.model = "models/props_lab/huladoll.mdl"
ITEM.fov = 47
ITEM.camPos = Vector(1, 0, 0)
ITEM.camXYOffsetAdj = Vector2(0, -10)
ITEM.camOffScreenAdjScale = 0.1
ITEM.camOrthoAdjScale = 3.95

ITEM.triggerDelay = 0
ITEM.retriggerable = false

local rescale = 0.4

local shape = {
	Vector2(0, 10),
	Vector2(68, 0),
	Vector2(108, 7),
	Vector2(120, 42),
	Vector2(115, 162),
	Vector2(95, 177),
	Vector2(32, 177),
	Vector2(14, 162),
}
local tab = {}
for i = 1, #shape do
	tab[i] = shape[i] * rescale
end

ITEM.camXYOffsetAdj = ITEM.camXYOffsetAdj * rescale



ITEM.hitboxPoints = {
	--[[
	[1] = Points({	Vector2(0, 0),
			Vector2(200, 0),
			Vector2(200, 200),
			Vector2(0, 200)}),
	]]
	--[[
	[2] = Points({	Vector2(40, 28),
			Vector2(108, 18),
			Vector2(148, 25),
			Vector2(160, 60),
			Vector2(155, 180),
			Vector2(135, 195),
			Vector2(72, 195),
			Vector2(54, 180),
	}),]]
	[1] = Points(tab)
}

ITEM.gridPoints = {
	[0] = Points({Vector2(0, 0)}),
	[90] = Points({Vector2(0, 0)}),
	[180] = Points({Vector2(0, 0)}),
	[270] = Points({Vector2(0, 0)}),
}
ITEM.gridPointsOffsets = {
	[0] = Vector2(-15, -11),
	[90] = Vector2(-15, -11),
	[180] = Vector2(-15, -11),
	[270] = Vector2(-15, -11),
}

ITEM.PlayPlaceSound = function()
	surface.PlaySound("physics/glass/glass_impact_soft" .. math.Random(1, 3) .. ".wav")
end

ITEM.DoActivate = function(me, other) end