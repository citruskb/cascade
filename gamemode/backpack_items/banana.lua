ITEM.id = "banana"
ITEM.name = "Banana"
ITEM.description = "Go bananas."

ITEM.model = "models/props/cs_italy/bananna.mdl"
ITEM.fov = 51
ITEM.camPos = Vector(1, 0, 0)
ITEM.camScale = 1
ITEM.camXYOffsetAdj = Vector2(0, 3)
ITEM.camOffScreenAdjScale = 1

ITEM.triggerDelay = 0
ITEM.retriggerable = false


--[[
local adjust = Vector2(shape:GetMinX(), shape:GetMinY())
local new = {}
for i = 1, #shape:GetPoints() do
	local point = shape:GetPoints()[i]
	new[i] = point - adjust
end
]]

local rescale = 0.35

local shape = {
	[1] = Points({ Vector2(36, 240),
		Vector2(0, 152),
		Vector2(8, 88),
		Vector2(40, 88),
		Vector2(99, 176),
	}),
	[2] = Points({ Vector2(8, 88),
		Vector2(8, 0),
		Vector2(40, 0),
		Vector2(40, 88),
	}),
	[3] = Points({ Vector2(36, 240),
		Vector2(99, 176),
		Vector2(156, 208),
		Vector2(132, 295),
	}),
	[4] = Points({ Vector2(132, 295),
		Vector2(156, 208),
		Vector2(229, 221),
		Vector2(232, 306),
	}),
	[5] = Points({ Vector2(232, 306),
		Vector2(229, 221),
		Vector2(334, 216),
		Vector2(356, 228),
		Vector2(369, 248),
		Vector2(357, 278)
	})
}

--[[
local all
for i = 1, #shape do
	local points = shape[i]
	all = not all and points or all + points
end

local adjust = Vector2(all:GetMinX(), all:GetMinY())
for i = 1, #shape do
	local points = shape[i]:GetPoints()

	local temp = {}
	for j = 1, #points do
		temp[j] = points[j] - adjust
	end
end
]]

local newShape = {}
for i = 1, #shape do
	local points = shape[i]:GetPoints()
	local newPoints = {}
	for j = 1, #points do
		newPoints[j] = points[j] * rescale
	end

	newShape[i] = Points(newPoints)
end

ITEM.camXYOffsetAdj = ITEM.camXYOffsetAdj * rescale


--[[ Template
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
]]

ITEM.hitboxPoints = newShape

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

--[[
local all
for i = 1, #shape do
	local points = shape[i]
	all = not all and points or all + points
end

local adjust = Vector2(all:GetMinX(), all:GetMinY())
for i = 1, #shape do
	local points = shape[i]:GetPoints()

	local temp = {}
	for j = 1, #points do
		temp[j] = points[j] - adjust
	end
end
]]