-- Used to determine physics collision.
-- The debug hitboxes are drawn irregularly shapped using surface.DrawPoly() since regularly drawn shapes can't rotate.
-- This also means we need to update the panel every frame since thats where positional and rotational calculations come into play.

-- Pulls heavily from: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29 as a concept.

local math_Rad = math.Rad
local math_Cos = math.Cos
local math_Sin = math.Sin

PANEL = {}

local function RotateDataAroundPoint(pointdata, point, angle)
	if angle == 0 then return pointdata end

	local ox, oy = point:Unpack()

	local radians = math_Rad(angle)
	local cos, sin = math_Cos(radians), math_Sin(radians)

	local ret = {}
	local pointtab = pointdata:GetPoints()
	for i = 1, #pointtab do
		local x, y = pointtab[i]:Unpack()
		ret[i] = Vector2(
			ox + cos * (x - ox) - sin * (y - oy),
			oy + sin * (x - ox) + cos * (y - oy)
		)

	end

	return Points(ret)
end

function PANEL:Init()
	GAMEMODE.VGUIHitboxes[self] = true

	self.col = Color(math.Random(50, 200), math.Random(50, 200), math.Random(50, 200), 120)
	self.lineCol = Color(self.col.r + 50, self.col.g + 50, self.col.b + 50, 120)

	self.origin = Vector2()

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
	local manipulated = RotateDataAroundPoint(self.vectorPoints, self:GetVPos(), self.angle)
	self.manipulatedVectorData = manipulated

	if not GAMEMODE.Debug then return end

	-- Needs to be done because surface.DrawPoly needs to be in this format to work.
	self.polyData = manipulated:ToTable()
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
function PANEL:GetTranslatedAggregateVectorData()
	local parent = self:GetParent()
	local t = IsValid(parent) and parent.GetDesiredTranslation and self:GetParent():GetDesiredTranslation() or Vector2()

	local x, y = self:GetPos()
	local sx, sy
	if IsValid(parent) then
		sx, sy = parent:LocalToScreen(x, y)
	else
		sx, sy = self:LocalToScreen(x, y)
	end
	local s = Vector2(sx, sy)

	local trans = {}
	local pointstab = self:AggregateVectorData():GetPoints()
	for i = 1, #pointstab do
		trans[i] = pointstab[i] + t + s
	end

	return Points(trans)
end
function PANEL:GetAggregateCenter()
	local ret = self.aggregateCenter
	local points = self:GetTranslatedAggregateVectorData()

	if not ret then
		ret = points:GetCenter()
		self.aggregateCenter = ret
	end

	return ret
end
-- [[	]]

function PANEL:SetOrigin(vec2) self.origin:Set(vec2) end
function PANEL:GetOrigin() return self.origin end

vgui.Register("DHitbox", PANEL, "DPanel")