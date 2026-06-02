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

function PANEL:AddHitbox(parent, w, h)
	local pw, ph = parent:GetSize()
	local hb = vgui.Create("DHitbox", parent)
	hb:SetSize(pw, ph)

	hb.Shape = POLY_RECTANGLE
	hb.ShapeW, hb.ShapeH = w, h
	hb.Angle = 0
	--hb.Debug = true
	hb:InvalidateLayout(true)
end

--[[ -- TODO
function PANEL:AddCircularHitbox()

end
]]

function PANEL:AddCustomHitbox(parent, data)
	local pw, ph = parent:GetSize()
	local hb = vgui.Create("DHitbox", parent)
	hb:SetSize(pw, ph)

	hb.Shape = POLY_CUSTOM
	hb.customPoints = data
	hb.Angle = 0
	hb.Debug = true
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