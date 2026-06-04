--[[
A collection of "dhitbox" panels that determine if we are colliding with something or not.
Should be a collection in order to handle concave shapes more easily.
Also contains physics parameters such as center of mass, mass, interia, and if this hitbox is moveable or not.
]]--

PANEL = {}

function PANEL:Init()
	GAMEMODE.VGUIPhysboxes[self] = true
	self.hbs = {}
	self.isPhysbox = true
end

--[[ -- TODO
function PANEL:AddHitbox(parent, w, h)
	local pw, ph = parent:GetSize()
	local hb = vgui.Create("DHitbox", parent)
	hb:SetSize(pw, ph)

	hb.Shape = POLY_RECTANGLE
	hb.ShapeW, hb.ShapeH = w, h
	hb.Angle = 0
	hb:InvalidateLayout(true)
end

function PANEL:AddCircularHitbox()

end
]]

function PANEL:AddHitbox(w, h, offset)
	local mw, mh = self:GetSize()
	local hb = vgui.Create("DHitbox", self)
	hb:SetSize(mw, mh)

	offset = offset or 0

	hb.Shape = POLY_CUSTOM
	hb.customPoints = {
		{x = 0 + offset, y = 0 + offset},
		{x = w + offset, y = 0 + offset},
		{x = w + offset, y = h + offset},
		{x = 0 + offset, y = h + offset},
	}
	hb.Angle = 0
	hb:InvalidateLayout(true)

	table.Insert(self.hbs, hb)
end



function PANEL:AddCustomHitbox(data)
	local w, h = self:GetSize()
	local hb = vgui.Create("DHitbox", self)
	hb:SetSize(w, h)

	hb.Shape = POLY_CUSTOM
	hb.customPoints = data
	hb.Angle = 0
	hb:InvalidateLayout(true)

	table.Insert(self.hbs, hb)
end

function PANEL:AggregatePolyData()
	local ret = self.aggregatePolyData

	if not ret then
		ret = {}
		for k, hb in pairs(self.hbs) do
			table.Add(ret, hb.polyData)
		end
		self.aggregatePolyData = ret
	end

	return ret
end

function PANEL:TranslatePointsLocalToScreen(tab)
	local x, y = self:GetPos()
	local tx, ty = self:GetDesiredTranslation()
	local sx, sy = self:LocalToScreen(x, y)

	local trans = {}
	for i = 1, #tab do
		trans[i] = {x = tab[i].x + tx + sx, y = tab[i].y + ty + sy}
	end

	return trans
end

function PANEL:GetTranslatedAggregatePolyData()
	local ret = self.transAggroData

	if not ret then
		ret = self:TranslatePointsLocalToScreen(self:AggregatePolyData())
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

function PANEL:Paint(w, h)
	-- TODO: Draw physics info close-by center of mass.
end

function PANEL:Think()
	self.aggregatePolyData = nil
	self.aggregateCenter = nil
end

-- This var should only be cached for single physpasses
hook.Add("VGUIPhysPassComplete", "VGUIPhysPassComplete.dphysbox", function()
	for physbox, v in pairs(GAMEMODE.VGUIPhysboxes) do
		physbox.transAggroData = nil
	end
end)

function PANEL:OnRemove()
	GAMEMODE.VGUIPhysboxes[self] = nil
end


-- [[ Hookup with items & others? ]]
function PANEL:GetVel()
	local parent = self:GetParent()
	if parent.GetVel then return parent:GetVel() end
end
function PANEL:SetVel(x, y)
	local parent = self:GetParent()
	if parent.SetVel then parent:SetVel(x, y) end
end
function PANEL:AddVel(xAdd, yAdd)
	local parent = self:GetParent()
	if parent.AddVel then parent:AddVel(xAdd, yAdd) end
end
-- [[	]]


-- [[ Hookup with items & others? ]]
function PANEL:GetDesiredTranslation()
	local parent = self:GetParent()
	if parent.GetDesiredTranslation then return parent:GetDesiredTranslation() end

	return 0, 0
end
function PANEL:SetDesiredTranslation(x, y)
	local parent = self:GetParent()
	if parent.SetDesiredTranslation then parent:SetDesiredTranslation(x, y) end
end
function PANEL:AddDesiredTranslation(xAdd, yAdd)
	local parent = self:GetParent()
	if parent.AddDesiredTranslation then parent:AddDesiredTranslation(xAdd, yAdd) end
end
function PANEL:HasDesiredTranslation()
	local parent = self:GetParent()
	if parent.HasDesiredTranslation then return parent:HasDesiredTranslation() end
end
-- [[	]]

vgui.Register("DPhysbox", PANEL, "DPanel")