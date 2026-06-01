-- Used to determine physics collision.
-- These hitbox panels may be irregularly shapped (Circular? Polynomial?)

-- Pulls heavily from: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29
-- Why reinvent the wheel?

-- Controls how many segments cicular shapes should be composed of.
POLY_RESOLUTION = 8

POLY_RECTANGLE = 1
POLY_ELLIPSE = 2
--POLY_SQUARE = 3
--POLY_CIRCLE = 4

PANEL = {}

local debugMat = surface.GetTextureID("vgui/white")

local function RotateDataAroundPoint(data, ox, oy, angle)
	if angle == 0 then return data end

	local radians = math.Rad(angle)
	local cosTheta, sinTheta = math.Cos(radians), math.Sin(radians)

	local ret = {}
	for i = 1, #shape do
		local x, y = data[i].x, data[i].y
		local point = {}
		point.x = ox + cosTheta * (x-ox) - sinTheta * (y-oy)
		point.y = oy + sinTheta * (x-ox) + cosTheta * (y-oy)

		ret[i] = point
	end

	return ret
end

local PolyFuncs = {
	[POLY_RECTANGLE] = function(self)
		-- Our polynomial points needs to be defined in clockwise order.
		local halfW, halfH = self.ShapeW * 0.5, self.ShapeH * 0.5
		local points = {
			{x = halfW, y = halfH},
			{x = halfW, y = -halfH},
			{x = -halfW, y = -halfH},
			{x = -halfW, y = halfH},
		}

		local ox, oy = self:GetPos()
		return RotateDataAroundPoint(points, ox, oy, self.Angle)
	end,
	[POLY_ELLIPSE] = function(self)
		-- Defined in clockwise order?
		local ox, oy = self:GetPos()
		local rx, ry = self.ShapeRX, self.ShapeRY
		local radStep = math.Rad(360 / POLY_RESOLUTION)
		local points = {}
		for i = 0, POLY_RESOLUTION do
			local rad = i * radStep
			local point = {}
			point.x = ox + math.Cos(rad) * rx
			point.y = oy + math.Sin(rad) * ry
		end

		return RotateDataAroundPoint(points, ox, oy, self.Angle)
	end,
}

function PANEL:Init()
	-- [[ For testing ]]
	self.Shape = POLY_RECTANGULAR
	self.ShapeW = 100
	self.ShapeH = 50

	self.Angle = 0
	-- [[	]]

	-- [[ For testing ]]
	self.Shape = POLY_ELLIPSE
	self.ShapeRX = 50
	self.ShapeRY = 25

	self.Angle = 0
	-- [[	]]

	self:InvalidateLayout(true)
end

function PANEL:PerformLayout(w, h)
	self.PolyData = PolyFuncs[self.Shape](self)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(Color(255, 0, 0))
	surface.SetTexture(debugMat)
	surface.DrawPoly(self.PolyData)
end

vgui.Register("DHitbox", PANEL, "DPanel")