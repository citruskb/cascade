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
		local points = self.customPoints

		return RotateDataAroundPoint(self.customPoints, ox, oy, self.Angle)
	end
}

function PANEL:Init()
	-- [[ For testing ]]
	--[[
	self.Shape = POLY_RECTANGULAR
	self.ShapeW = 100
	self.ShapeH = 50

	self.Angle = 0
	]]
	-- [[	]]

	-- [[ For testing ]]
	--[[
	self.Shape = POLY_ELLIPSE
	self.ShapeRX = 50
	self.ShapeRY = 25

	self.Angle = 0
	]]
	-- [[	]]

	self:InvalidateLayout(true)
end

-- We invalidate our layout every frame.
function PANEL:Think() self:InvalidateLayout() end

function PANEL:PerformLayout(w, h)
	self.polyData = PolyFuncs[self.Shape](self)
end

function PANEL:Paint(w, h)
	if not self.Debug then return end
	surface.SetDrawColor(Color(255, 100, 0, 255))
	draw.NoTexture()
	surface.DrawPoly(self.polyData)
end


-- [[ Handle some static hitbox behavior.. ]]
function PANEL:EnableStaticHitbox()
	self.statichb = true
	self.idx = table.Insert(GAMEMODE.StaticHitboxes, self)
end
function PANEL:DisableStaticHitbox()
	self.statichb = nil
	table.Remove(GAMEMODE.StaticHitboxes, self.idx)
end
-- [[	]]


-- [[ The "root" element that should be impacted by collision events. ]]
function PANEL:GetVGUIPhysRoot() return self.vguiPhysRoot end
function PANEL:SetVGUIPhysRoot(pan) self.vguiPhysRoot = pan end
-- [[	]]


function PANEL:OnRemove()
	if self.statichb then self:DisableStaticHitbox() end
end

vgui.Register("DHitbox", PANEL, "DPanel")