PANEL = {}

GM.VGUIPhysboxes = {}
local countPhysboxes = 1
function PANEL:Init()
	self:SetPos(0, 0)

	GAMEMODE.VGUIPhysboxes[self] = true

	self.Hitboxes = {}

	self.IsPhysbox = true

	self.ID = countPhysboxes
	countPhysboxes = countPhysboxes + 1
end

function PANEL:Think()
	if not self.Item then return end
	if not self.Physics then return end

	-- Determine where we need to move our parent based on physics parameters.
	local trans = self:GetDesiredTranslation()
	local vel = self:GetVelocity()
	local partial = self:GetPartialPos()

	-- Apply our translation and velocity to our partial pos.
	partial:DoAdd(trans + vel)
	trans:Zero()

	-- To get our whole number movement, round partial to the nearest.
	local mx, my = partial:Unpack()
	local delta = Vector2(math.Round(mx, 0), math.Round(my, 0))

	if not delta:IsZero() and self.Item then
		local parentvpos = parent:GetVPos()
		parentvpos:DoAdd(delta)
		parent:SetPos(parentvpos:Unpack())

		partial:DoSub(delta)
	end
end

function PANEL:Paint(w, h) end

function PANEL:OnRemove()
	GAMEMODE.VGUIPhysboxes[self] = nil
end

function PANEL:EnablePhysics()
	self.Vel = Vector2()
	self.PartialPos = Vector2()
	self.DesiredTrans = Vector2()

	self.Physics = true
end

function PANEL:DisablePhysics()
	self.Vel = nil
	self.PartialPos = nil
	self.DesiredTrans = nil

	self.Physics = nil
end

-- These are used to control the physics steps and item movement.
function PANEL:GetVel() return self.Vel end
function PANEL:SetVel(vect2) self.Vel:Set(vect2) end
function PANEL:AddVel(toAdd) self.Vel:DoAdd(toAdd) end

function PANEL:GetPartialPos() return self.PartialPos end
function PANEL:SetPartialPos(vect2) self.PartialPos:Set(vect2) end
function PANEL:AddPartialPos(toAdd) self.PartialPos:DoAdd(toAdd) end

function PANEL:GetDesiredTrans() return self.DesiredTrans end
function PANEL:SetDesiredTrans(vect2) self.DesiredTrans:Set(vect2) end
function PANEL:AddDesiredTrans(toAdd) self.DesiredTrans:DoAdd(toAdd) end



vgui.Register("DPhysbox2", PANEL, "DPanel")