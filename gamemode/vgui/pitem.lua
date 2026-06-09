local meta = FindMetaTable("Panel")
local OldSetSize = meta.SetSize

PANEL = {}

GM.VGUIItems = {}
local itemCount = 1
function PANEL:Init()
	GAMEMODE.VGUIItems[self] = true

	local physbox = VGUIPhysbox:Create(self)
	physbox:EnablePhysics()
	self.Physbox = physbox

	self.IsItem = true

	self.ID = itemCount
	itemCount = itemCount + 1
end

function PANEL:GetPhysbox() return self.Physbox end

function PANEL:SetSize(w, h)
	OldSetSize(self, w, h)
	if IsValid(self.ModPan) then self.ModPan:SetSize(w, h) end
end

function PANEL:GetCenterPos()
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	return Vector2(x + w * 0.5, y + h * 0.5)
end

function PANEL:SetupModel(modelPath)
	local modpan = vgui.Create("DModelPanel", self)
	local w, h = self:GetSize()
	modpan:SetSize(w, h)
	modpan:SetModel(modelPath)

	

	self.ModPan = modpan
end

function PANEL:Paint() end

function PANEL:OnRemove()
	GAMEMODE.VGUIItems[self] = nil
	self.Physbox:Remove()
end

vgui.Register("PItem", PANEL, "DPanel")