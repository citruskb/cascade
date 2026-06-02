--[[
A collection of "dhitbox" panels that determine if we are colliding with something or not.
Should be a collection in order to handle concave shapes more easily.
Also contains physics parameters such as center of mass, mass, interia, and if this hitbox is moveable or not.
]]--

PANEL = {}

function PANEL:Init()
	self.idx = table.Insert(GAMEMODE.VGUIPhysboxes, self)
	self.hbs = {}
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
	local parent = self:GetParent()
	local pw, ph = parent:GetSize()
	local hb = vgui.Create("DHitbox", parent)
	hb:SetSize(pw, ph)

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
	local parent = self:GetParent()
	local pw, ph = parent:GetSize()
	local hb = vgui.Create("DHitbox", parent)
	hb:SetSize(pw, ph)

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
	end

	return ret
end

function PANEL:Paint(w, h)
	-- TODO: Draw physics info close-by center of mass.
end

function PANEL:Think() self.aggregatePolyData = nil end

function PANEL:Remove()
	table.Remove(GAMEMODE.VGUIPhysboxes, self.idx)
end

vgui.Register("DCollision", PANEL, "DPanel")