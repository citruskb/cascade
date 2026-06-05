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
	self:SetMPos(Vector2(0, 0))
	self:SetDesiredTranslation(Vector2(0, 0))

	local physbox = vgui.Create("DPhysbox", self)
	self.physbox = physbox
end

function PANEL:Paint() end

function PANEL:Think()
	if not self.Physics then return end

	-- Update position based on velocity and desired translations.
	-- The reason we use "mpos" as a medium is because panels don't track fractional position

	local t = self:GetDesiredTranslation()
	local v = self:GetVel()
	local mpos = self:GetMPos()

	mpos:DoAdd(t + v)
	t:Zero()

	local mx, my = mpos:Unpack()
	local rmx, rmy = math.Round(mx, 0), math.Round(my, 0)
	local dx, dy = math.Abs(mx) >= 1 and rmx or 0, math.Abs(my) >= 1 and rmy or 0
	local delta = Vector2(dx, dy)

	if not delta:IsZero() then
		local pos = self:GetVPos()
		pos:DoAdd(delta)

		self:SetPos(pos:Unpack())
		mpos:DoSub(delta)
	end

	self:InvalidateLayout(true)
end


-- [[ Define velocity ]]
function PANEL:GetVel() return self.vel end
function PANEL:SetVel(vec2) self.vel = vec2 end
function PANEL:AddVel(vec2) self:GetVel():DoAdd(vec2) end
-- [[	]]


-- [[ Define fractional movement ]]
function PANEL:GetMPos() return self.mpos end
function PANEL:SetMPos(vec2) self.mpos = vec2 end
function PANEL:AddMPos(vec2) self:GetMPos():DoAdd(vec2) end
-- [[	]]


-- [[ Define desired movement (used for collision resolution passes) ]]
function PANEL:GetDesiredTranslation() return self.translation end
function PANEL:SetDesiredTranslation(vec2) self.translation = vec2 end
function PANEL:AddDesiredTranslation(vec2)
	print("adding the translation:", self:GetDesiredTranslation(), vec2)
	self:GetDesiredTranslation():DoAdd(vec2)
	print("our translation is now:", self:GetDesiredTranslation())
end
function PANEL:HasDesiredTranslation() return not self:GetDesiredTranslation():IsZero() end
-- [[	]]


-- [[ Define physics enable ]]
function PANEL:EnablePhysics()
	self.Physics = true
	if not self.vel then self:SetVel(Vector2()) end
	self:GetVel():Zero()
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