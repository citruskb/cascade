--[[
A collection of "dhitbox" panels that determine if we are colliding with something or not.
Should be a collection in order to handle concave shapes more easily.
Also will eventually contain physics parameters such as center of mass, mass, interia, and if this hitbox is moveable or not.
]]--

PANEL = {}

function PANEL:Init()
	GAMEMODE.VGUIPhysboxes[self] = true
	self.ID = table.Count(GAMEMODE.VGUIPhysboxes)
	self.hbs = {}
	self.isPhysbox = true
end

function PANEL:AddHitbox(w, h, offset)
	local mw, mh = self:GetSize()
	local hb = vgui.Create("DHitbox", self)
	hb:SetSize(mw, mh)

	offset = offset or 0
	hb.vectorPoints = {
		Vector2(0 + offset, 0 + offset),
		Vector2(w + offset, 0 + offset),
		Vector2(w + offset, h + offset),
		Vector2(0 + offset, h + offset),
	}

	hb.Angle = 0
	hb:InvalidateLayout(true)

	table.Insert(self.hbs, hb)
end

function PANEL:AddCustomHitbox(data)
	local w, h = self:GetSize()
	local hb = vgui.Create("DHitbox", self)
	hb:SetSize(w, h)

	hb.vectorPoints = data
	hb.Angle = 0
	hb:InvalidateLayout(true)

	table.Insert(self.hbs, hb)
end

function PANEL:AggregateVectorData()
	local ret = self.aggregateVectorData

	if not ret then
		ret = {}
		for k, hb in pairs(self.hbs) do
			table.Add(ret, hb.manipulatedVectorData)
		end
		self.aggregateVectorData = ret
	end

	return ret
end

function PANEL:TranslatePointsLocalToScreen(points)
	local t = self:GetDesiredTranslation()

	local x, y = self:GetVPos():Unpack()
	local xs, xy = self:LocalToScreen(x, y)
	local s = Vector2(xs, xy)

	local trans = {}
	for i = 1, #points do
		trans[i] = points[i] + t + s
	end

	return trans
end

function PANEL:GetTranslatedAggregateVectorData()
	local ret = self.transAggroData

	if not ret then
		ret = self:TranslatePointsLocalToScreen(self:AggregateVectorData())
		self.transAggroData = ret
	end

	return ret
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

function PANEL:Paint(w, h)
	-- TODO: Draw physics info close-by center of mass.
end

function PANEL:Think()
	self.aggregateVectorData = nil
	self.aggregateCenter = nil
end

-- This var should only be cached for single physpasses
local function ClearAllTransAggroCachedData()
	for physbox, _ in pairs(GAMEMODE.VGUIPhysboxes) do
		physbox.transAggroData = nil
	end
end
hook.Add("VGUIPhysPassComplete", "VGUIPhysPassComplete.dphysbox", ClearAllTransAggroCachedData)

function PANEL:OnRemove()
	GAMEMODE.VGUIPhysboxes[self] = nil
end


-- [[ Hookup with items & others? ]]
function PANEL:GetVel()
	local parent = self:GetParent()
	if parent.GetVel then return parent:GetVel() end
end
function PANEL:SetVel(vec2)
	local parent = self:GetParent()
	if parent.SetVel then parent:SetVel(vec2) end
end
function PANEL:AddVel(vec2)
	local parent = self:GetParent()
	if parent.AddVel then parent:AddVel(vec2) end
end
-- [[	]]


-- [[ Hookup with items & others? ]]
function PANEL:GetDesiredTranslation()
	local parent = self:GetParent()
	if parent.GetDesiredTranslation then return parent:GetDesiredTranslation() end

	return VECTOR2_ZERO
end
function PANEL:SetDesiredTranslation(vec2)
	local parent = self:GetParent()
	if parent.SetDesiredTranslation then parent:SetDesiredTranslation(vec2) end
end
function PANEL:AddDesiredTranslation(vec2)
	local parent = self:GetParent()
	if parent.AddDesiredTranslation then parent:AddDesiredTranslation(vec2) end
end
function PANEL:HasDesiredTranslation()
	local parent = self:GetParent()
	if parent.HasDesiredTranslation then return parent:HasDesiredTranslation() end
end
-- [[	]]

vgui.Register("DPhysbox", PANEL, "DPanel")