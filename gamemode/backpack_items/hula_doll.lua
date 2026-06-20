ITEM.id = "hula_doll"
ITEM.name = "Hula Doll"
ITEM.description = "It's all in the hips."

ITEM.model = "models/props_lab/huladoll.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(1, 0, 0)

ITEM.triggerDelay = 0
ITEM.retriggerable = false

--[[
local shape = {
	Vector2(0, 15),
	Vector2(68, 0),
	Vector2(106, 12),
	Vector2(118, 42),
	Vector2(115, 167),
	Vector2(95, 177),
	Vector2(32, 177),
	Vector2(14, 162),
}
local tab = {}
for i = 1, #shape do
	tab[i] = shape[i] --* 0.4
end
]]



ITEM.hitboxPoints = {
	[1] = Points({	Vector2(0, 0),
			Vector2(200, 0),
			Vector2(200, 200),
			Vector2(0, 200)}),
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
	--[1] = Points(tab)
}

ITEM.gridPoints = Points({Vector2(0, 0)})

ITEM.DoActivate = function(me, other) end