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

function PANEL:AddHitbox(w, h, origin, angle)
	local hb = vgui.Create("DHitbox", self)
	local points = Points({
		Vector2(0, 0),
		Vector2(w, 0),
		Vector2(w, h),
		Vector2(0, h),
	})

	hb:SetSize(points:GetMinX() + points:GetMaxX(), points:GetMinY() + points:GetMaxY())
	hb:SetOrigin(origin)

	hb.vectorPoints = points
	hb.angle = angle or 0

	table.Insert(self.hbs, hb)
	hb:InvalidateLayout(true)
	self:CenterHitboxes()

	--[[
	local mw, mh = self:GetSize()
	local hb = vgui.Create("DHitbox", self)
	hb:SetSize(mw, mh)

	offset = offset or 0
	hb.vectorPoints = Points({
			Vector2(0 + offset, 0 + offset),
			Vector2(w + offset, 0 + offset),
			Vector2(w + offset, h + offset),
			Vector2(0 + offset, h + offset),
		})

	hb.angle = angle or 0
	hb:InvalidateLayout(true)

	table.Insert(self.hbs, hb)
	]]
end

function PANEL:CenterHitboxes()
	local points = self:AggregateVectorData()

	-- Get the center of all our hitboxes.
	-- 0, 0 here is relative to the top left corner of the parent physbox.

	local groupCenter = points:GetCenter()
	local groupCenterX, groupCenterY = groupCenter:Unpack()
	local physboxCenterX, physboxCenterY = self:GetCPos():Unpack()
	local offsetX, offsetY = physboxCenterX - groupCenterX, physboxCenterY - groupCenterY

	local parent = self:GetParent()
	for _, hb in pairs(self.hbs) do
		local ox, oy = hb:GetOrigin():Unpack()
		local x, y = parent:GetPos()
		parent:SetPos(x + ox, y + oy)
		hb:SetPos(offsetX, offsetY)
	end
end

function PANEL:AddCustomHitbox(points, origin, angle)
	-- Goal:
	-- Set item size and physbox size to screenw and screenh
	-- This allows plenty of space for item rotation and effects to play

	-- 1. Create the hitbox. Insert vectors.
	-- 2. Get all the vectors of all the hitboxes in the coordinate plane
	-- 3. Find the center X (minx + maxx / 2) and center Y (miny + maxy / 2) of these vectors 
	-- 4. Adjust offsets of existing hitboxes such that the centerX and centerY corresponds to the centerX and centerY of the item/physbox
	-- 5. Reposition hitboxes inside the physbox based on this change in offset

	-- This will make sure that whenever we add a hitbox to an item the item automatically resizes to fit any rotational orientation of these hitboxes.

	local hb = vgui.Create("DHitbox", self)
	hb:SetSize(points:GetMinX() + points:GetMaxX(), points:GetMinY() + points:GetMaxY())
	hb:SetOrigin(origin)

	hb.vectorPoints = points
	hb.angle = angle or 0

	table.Insert(self.hbs, hb)
	hb:InvalidateLayout(true)
	self:CenterHitboxes()
end

function PANEL:AggregateVectorData()
	local ret = self.aggregateVectorData

	if not ret then
		for k, hb in pairs(self.hbs) do
			if not ret then
				ret = hb.vectorPoints
				continue
			end

			ret = ret + hb.vectorPoints
		end
		self.aggregateVectorData = ret
	end

	return ret
end

function PANEL:RotatedAggregateVectorData()
	local ret = self.rotatedAggregateVectorData

	if not ret then
		for k, hb in pairs(self.hbs) do
			if not ret then
				ret = hb.manipulatedVectorData
				continue
			end

			ret = ret + hb.manipulatedVectorData
		end

		self.roatatedAggregrateVectorData = ret
	end

	return ret
end

function PANEL:TranslatePointsLocalToScreen(points)
	local t = self:GetDesiredTranslation()

	local x, y = self:GetVPos():Unpack()
	local xs, xy = self:LocalToScreen(x, y)
	local s = Vector2(xs, xy)

	local trans = {}
	local pointstab = points:GetPoints()
	for i = 1, #pointstab do
		trans[i] = pointstab[i] + t + s
	end

	return Points(trans)
end

function PANEL:GetTranslatedAggregateVectorData()
	local ret = self.transAggroData

	if not ret then
		ret = self:TranslatePointsLocalToScreen(self:AggregateVectorData())
		self.transAggroData = ret
	end

	return ret
end

function PANEL:GetTranslatedRotatedAggregateVectorData()
	local ret = self.transAggroData

	if not ret then
		ret = self:TranslatePointsLocalToScreen(self:RotatedAggregateVectorData())
		self.transAggroData = ret
	end

	return ret
end

function PANEL:GetAggregateCenter()
	local ret = self.aggregateCenter
	local pointdata = self:GetTranslatedAggregateVectorData()
	local points = pointdata:GetPoints()

	if not ret then
		local xsum, ysum = 0, 0
		for _, point in pairs(points) do
			local x, y = point:Unpack()
			xsum = xsum + x
			ysum = ysum + y
		end
		ret = Vector2(xsum / #points, ysum / #points)
		self.aggregateCenter = ret
	end

	return ret
end

function PANEL:Paint(w, h)
	-- TODO: Draw physics info close-by center of mass.
end

function PANEL:Think()
	self.aggregateVectorData = nil
	self.rotatedAggregateVectorData = nil
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

vgui.Register("DPhysbox1", PANEL, "DPanel")