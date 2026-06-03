-- Representative of an underlying game object.
-- Need to pull said data from that registered object and display it here.


-- [[ Step 1 ]]
-- Need to define collection of "hitbox" panels for physics collision
-- dCollisionPanel?
-- These hitbox panels may be irregularly shapped (Circular? Polynomial?)
-- example: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29


-- [[ Step 2 ]]
-- Physics can be on or off
	-- Collides & bounces against other objects while physics is on

-- Can be frozen or unfrozen
	-- Frozen (physics disabled): in shop, or set in grid inventory, or preview
	-- Unfrozen (physics enabled): in inventory


-- [[ Step 3 ]]
-- Snap into and out of inventory grid
-- Optionally can be placed tangental to the existing grid


-- [[ Step 4 ]]
-- Displays object through a 3d model projected on 2d surface
	-- Define details like item size, rotation, color, etc from registered object data?

-- Specific animation sequence that plays when item activates
-- Could spin, flash, grow and shrink in size, shake, wobble, etc

-- Add noises to pick up/dropping and to collision bounce

PANEL = {}

function PANEL:Init()
	self:DisablePhysics()

	self:SetMPos(0, 0)
	self:SetDesiredTranslation(0, 0)

	local physbox = vgui.Create("DPhysbox", self)
	self.physbox = physbox
end

function PANEL:Paint() end

function PANEL:Think()
	if not self.Physics then return end

	--print("Pos:", self:GetPos(), "Vel:", self:GetVel())

	-- Update position based on velocity.
	-- The reason we use "mx" "my" as a medium is because panels don't track fractional position.
	local mx, my = self:GetMPos()
	local tx, ty = self:GetDesiredTranslation()
	local vx, vy = self:GetVel()

	self:SetMPos(mx + tx + vx, my + ty + vy)
	mx, my = self:GetMPos()
	local rmx, rmy = math.Round(mx, 0), math.Round(my, 0)

	local dx, dy = math.Abs(mx) >= 1 and rmx or 0, math.Abs(my) >= 1 and rmy or 0

	if dx ~= 0 or dy ~= 0 then
		local x, y = self:GetPos()
		self:SetPos(x + dx, y + dy)
		self:AddMPos(-dx, -dy)
	end

	self:InvalidateLayout(true)
end


-- [[ Define velocity ]]
function PANEL:GetVel()
	local tab = self.vel
	return tab.x, tab.y
end
function PANEL:SetVel(x, y) self.vel = {x = x, y = y} end
function PANEL:AddVel(xAdd, yAdd)
	local vx, vy = self:GetVel()
	self:SetVel(vx + xAdd, vy + yAdd)
end
-- [[	]]


-- [[ Define fractional movement ]]
function PANEL:GetMPos()
	local tab = self.mpos
	return tab.x, tab.y
end
function PANEL:SetMPos(x, y) self.mpos = {x = x, y = y} end
function PANEL:AddMPos(xAdd, yAdd)
	local mx, my = self:GetMPos()
	self:SetMPos(mx + xAdd, my + yAdd)
end
-- [[	]]


-- [[ Define desired movement (used for collision resolution passes) ]]
function PANEL:GetDesiredTranslation()
	local tab = self.translation
	return Rawget(tab, "x"), Rawget(tab, "y")
end
function PANEL:SetDesiredTranslation(x, y)
	local tab = self.translation or {}
	Rawset(tab, "x", x)
	Rawset(tab, "y", y)
end
function PANEL:AddDesiredTranslation(xAdd, yAdd)
	local x, y = self:GetDesiredTranslation()
	self:SetDesiredTranslation(x + xAdd, y + yAdd)
end
function PANEL:HasDesiredTranslation()
	local x, y = self:GetDesiredTranslation()
	return x ~= 0 or y ~= 0
end

function PANEL:GetDesiredPosition()
	local x, y = self:GetPos()
	local tx, ty = self:GetDesiredTranslation()
	return x + tx, y + ty
end
-- [[	]]


-- [[ Define physics enable ]]
function PANEL:EnablePhysics()
	self.Physics = true
	self:SetVel(0, 0)
end
function PANEL:DisablePhysics()
	self.Physics = false
	self.vel = nil
end
-- [[	]]


function PANEL:GetPhysbox() return self.physbox end

function PANEL:OnRemove()
	if self.Physics then self:DisablePhysics() end
end

vgui.Register("PItem", PANEL, "DPanel")