-- Used to determine physics collision.
-- The debug hitboxes are drawn irregularly shapped using surface.DrawPoly() since even regularly shaped objects can rotate.
-- This also means we need to update the panel every frame since thats where positional and rotational calculations come into play.

-- Pulls heavily from: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29 as a concept.

-- Controls how many segments cicular shapes should be composed of.

POLY_RECTANGLE = 1
POLY_ELLIPSE = 2
POLY_CUSTOM = 3
--POLY_SQUARE = 3
--POLY_CIRCLE = 4

if not GM.StaticHitboxes then GM.StaticHitboxes = {} end

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
	[POLY_CUSTOM] = function(self)
		local ox, oy = self:GetPos()
		return RotateDataAroundPoint(self.customPoints, ox, oy, self.Angle)
	end
}

function PANEL:Init()
	GAMEMODE.VGUIHitboxes[self] = true

	self.col = Color(math.Random(50, 200), math.Random(50, 200), math.Random(50, 200), 120)
	self.lineCol = Color(self.col.r + 50, self.col.g + 50, self.col.b + 50, 120)

	self.isHitbox = true
end

-- We invalidate our layout every frame.
function PANEL:Think()
	self.transAggroData = nil
	self.aggregateCenter = nil
	self:InvalidateLayout()
end

function PANEL:OnRemove()
	GAMEMODE.VGUIHitboxes[self] = nil
end

function PANEL:PerformLayout(w, h)
	self.polyData = PolyFuncs[self.Shape](self)
end

function PANEL:Paint(w, h)
	if not GAMEMODE.Debug then return end

	--[[
	local data = {
		{x = 0, y = 0},
		{x = 20, y = 0},
		{x = 10, y = 40},
	}
	]]

	local data = self.polyData

	-- Draw the textured shape
	surface.SetDrawColor(self.col)
	draw.NoTexture()
	surface.DrawPoly(data)

	-- Draw the lines making up said shape
	for i = 1, #data do
		local pointA = data[i]
		local pointB = i == #data and data[1] or data[i + 1]

		local xA, yA, xB, yB = pointA.x, pointA.y, pointB.x, pointB.y
		surface.SetDrawColor(self.lineCol)
		surface.DrawLine(xA, yA, xB, yB)
	end
end

-- [[ Compatability with some dphysbox functions. ]]
function PANEL:AggregatePolyData()
	return self.polyData
end
function PANEL:GetTranslatedAggregatePolyData()
	local ret = self.transAggroData

	if not ret then
		ret = self:GetParent():TranslatePointsLocalToScreen(self:AggregatePolyData())
		self.transAggroData = ret
	end

	return ret
end
function PANEL:GetAggregateCenter()
	local ret = self.aggregateCenter
	local data = self:AggregatePolyData()

	if not ret then
		local xsum, ysum = 0, 0
		for _, point in pairs(data) do
			xsum = xsum + point.x
			ysum = ysum + point.y
		end
		ret = {x = xsum / #data, y = ysum / #data}
		self.aggregateCenter = ret
	end

	return ret
end
-- [[	]]

vgui.Register("DHitbox", PANEL, "DPanel")