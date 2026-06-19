local meta = FindMetaTable("Panel")
local OldSetSize = meta.SetSize

PANEL = {}

GM.VGUIItems = {}
local itemCount = 1
function PANEL:Init()
	GAMEMODE.VGUIItems[self] = true

	self.isItem = true

	self.ID = itemCount
	itemCount = itemCount + 1

	self:NoClipping(true)
end

function PANEL:InitPhysbox()
	local physbox = VGUIPhysbox:Create(self)
	physbox:EnablePhysics()
	self.Physbox = physbox
end

function PANEL:GetPhysbox() return self.Physbox end

function PANEL:SetSize(w, h)
	OldSetSize(self, w, h)
	if IsValid(self.ModPan) then self.ModPan:SetSize(w, h) end
end

function PANEL:SetupModel(modelPath)
	local modpan = vgui.Create("DItemModel", self)
	local w, h = self:GetSize()
	modpan:SetSize(w, h)
	modpan:SetModel(modelPath)

	self.ModPan = modpan
end

function PANEL:Think()
	if not self:IsVisible() then print("Parent invisible.") end
end
function PANEL:Paint() end

function PANEL:OnRemove()
	GAMEMODE.VGUIItems[self] = nil
	self.Physbox:Remove()
end

vgui.Register("PItem", PANEL, "DPanel")