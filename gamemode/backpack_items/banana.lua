ITEM.id = "banana"
ITEM.name = "Banana"
ITEM.description = "Go bananas."

ITEM.massMult = 1
ITEM.inertiaMult = 1

ITEM.model = "models/props/cs_italy/bananna.mdl"
ITEM.fov = 60
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = VECTOR2_ZERO

ITEM.triggerDelay = 0
ITEM.retriggerable = false


--[[
local adjust = Vector2(shape:GetMinX(), shape:GetMinY())
local new = {}
for i = 1, #shape:GetPoints() do
	local point = shape:GetPoints()[i]
	new[i] = point - adjust
end
print(Points(new))
]]






--[[ Template
[1] = Points({	Vector2(0, 0),
			Vector2(500, 0),
			Vector2(500, 500),
			Vector2(0, 500)}),
[2] = Points({	Vector2(65, 355),
	Vector2(20, 245),
	Vector2(30, 55),
	Vector2(70, 55),
	Vector2(70, 165),
	Vector2(150, 280),
	Vector2(215, 315),
	Vector2(305, 335),
	Vector2(440, 325),
	Vector2(485, 360),
	Vector2(470, 405),
	Vector2(325, 435),
	Vector2(190, 425)}),
]]

ITEM.hitboxPoints = {
	[1] = Points({ Vector2(0, 0),
			Vector2(400, 0),
			Vector2(400, 400),
			Vector2(0, 400)}),
	[2] = Points({ Vector2(52, 284),
		Vector2(16, 196),
		Vector2(24, 132),
		Vector2(56, 132),
		Vector2(115, 220),
	}),
	[3] = Points({ Vector2(24, 132),
		Vector2(24, 44),
		Vector2(56, 44),
		Vector2(56, 132),
	}),
	[4] = Points({ Vector2(52, 284),
		Vector2(115, 220),
		Vector2(172, 252),
		Vector2(148, 339),
	}),
	[5] = Points({ Vector2(148, 339),
		Vector2(172, 252),
		Vector2(245, 265),
		Vector2(248, 350),
	}),
	[6] = Points({ Vector2(248, 350),
		Vector2(245, 265),
		Vector2(350, 260),
		Vector2(372, 272),
		Vector2(385, 292),
		Vector2(373, 322)
	})
}

ITEM.gridPoints = Points({Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)})

ITEM.DoActivate = function(me, other) end


--[[
local rescale = 0.2

local shape = Points({	Vector2(45, 300),
	Vector2(0, 190),
	Vector2(10, 0),
	Vector2(50, 0),
	Vector2(50, 110),
	Vector2(130, 225),
	Vector2(195, 260),
	Vector2(285, 280),
	Vector2(420, 270),
	Vector2(465, 305),
	Vector2(450, 350),
	Vector2(305, 380),
	Vector2(170, 370)}):GetPoints()

local tab = {}
for i = 1, #shape do
	tab[i] = shape[i] * rescale
end

ITEM.camXYOffsetAdj = ITEM.camXYOffsetAdj * rescale
]]