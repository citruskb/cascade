-- Used to determine physics collision.
-- The debug hitboxes are drawn irregularly shapped using surface.DrawPoly() since regularly drawn shapes can't rotate.
-- This also means we need to update the panel every frame since thats where positional and rotational calculations come into play.

-- Pulls heavily from: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29 as a concept.

local math_Rad = math.Rad
local math_Cos = math.Cos
local math_Sin = math.Sin

PANEL = {}

local function RotateDataAroundPoint(data, point, angle)
	if angle == 0 then return data end

	local ox, oy = point:Unpack()

	local radians = math_Rad(angle)
	local cos, sin = math_Cos(radians), math_Sin(radians)

	local ret = {}
	for i = 1, #data do
		local x, y = data[i]:Unpack()
		ret[i] = Vector2(
			ox + cos * (x - ox) - sin * (y - oy),
			oy + sin * (x - ox) + cos * (y - oy)
		)
	end

	return ret
end

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
	local manipulated = RotateDataAroundPoint(self.vectorPoints, self:GetVPos(), self.Angle)
	self.manipulatedVectorData = manipulated

	if not GAMEMODE.Debug then return end

	-- Needs to be done because surface.DrawPoly needs to be in this format to work.
	self.polyData = {}
	for i = 1, #manipulated do
		self.polyData[i] = manipulated[i]:ToTable()
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
	surface.SetDrawColor(self.lineCol)
	for i = 1, #data do
		local pointA = data[i]
		local pointB = i == #data and data[1] or data[i + 1]

		local xA, yA, xB, yB = pointA.x, pointA.y, pointB.x, pointB.y

		surface.DrawLine(xA, yA, xB, yB)
	end

	local x, y = self:GetPos()
	local siz = self:GetSize()
	local tw, th = surface.GetTextSize( self:GetID() )
	surface.SetTextPos(x + siz / 2 - tw / 2, y + siz / 2 - th / 2)
	surface.DrawText(self:GetID())
end

function PANEL:GetID()
	local parent = self:GetParent()
	if not parent then return "N/A" end
	if not parent.ID then return "N/A" end
	return parent.ID
end

-- [[ Compatability with some dphysbox functions. ]]
function PANEL:AggregateVectorData() return self.manipulatedVectorData end
function PANEL:GetTranslatedAggregateVectorData() return self:GetParent():TranslatePointsLocalToScreen(self:AggregateVectorData()) end
function PANEL:GetAggregateCenter()
	local ret = self.aggregateCenter
	local data = self:GetTranslatedAggregateVectorData()

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