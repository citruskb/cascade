-- Used to determine physics collision.
-- The debug hitboxes are drawn irregularly shapped using surface.DrawPoly() since even regularly shaped objects can rotate.
-- This also means we need to update the panel every frame since thats where positional and rotational calculations come into play.

-- Pulls heavily from: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29 as a concept.

-- Controls how many segments cicular shapes should be composed of.

POLY_CUSTOM = 1

if not GM.StaticHitboxes then GM.StaticHitboxes = {} end

PANEL = {}

local debugMat = surface.GetTextureID("vgui/white")

local function RotateDataAroundPoint(data, point, angle)
	if angle == 0 then return data end

	local ox, oy = point:Unpack()

	local radians = math.Rad(angle)
	local cosTheta, sinTheta = math.Cos(radians), math.Sin(radians)

	local ret = {}
	for i = 1, #data do
		local x, y = data[i]:Unpack()
		local newX = ox + cosTheta * (x-ox) - sinTheta * (y-oy)
		local newY = oy + sinTheta * (x-ox) + cosTheta * (y-oy)

		ret[i] = Vector2(newX, newY)
	end

	return ret
end

local PolyFuncs = {
	[POLY_CUSTOM] = function(self)
		local point = self:GetVPos()
		return RotateDataAroundPoint(self.vectorPoints, point, self.Angle)
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
	self.aggregateCenter = nil
	self:InvalidateLayout()
end

function PANEL:OnRemove()
	GAMEMODE.VGUIHitboxes[self] = nil
end

function PANEL:PerformLayout(w, h)
	local manipulated = PolyFuncs[self.Shape](self)
	self.manipulatedVectorData = manipulated

	-- TODO: Check if this is only be necessary when drawing hitboxes? Probably moderate perf save.
	self.polyData = {}
	for i = 1, #manipulated do
		local x, y = manipulated[i]:Unpack()
		self.polyData[i] = {x = x, y = y}
	end
end

function PANEL:Paint(w, h)
	if not GAMEMODE.Debug then return end

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
function PANEL:AggregateVectorData()
	return self.manipulatedVectorData
end
function PANEL:GetTranslatedAggregateVectorData()
	return self:GetParent():TranslatePointsLocalToScreen(self:AggregateVectorData())
end
function PANEL:GetAggregateCenter()
	local ret = self.aggregateCenter
	local data = self:AggregateVectorData()

	if not ret then
		local xsum, ysum = 0, 0
		for _, point in pairs(data) do
			local x, y = point:Unpack()

			xsum = xsum + x
			ysum = ysum + y
		end
		ret = Vector2(xsum / #data, ysum / #data)
		self.aggregateCenter = ret
	end

	return ret
end
-- [[	]]

vgui.Register("DHitbox", PANEL, "DPanel")