local meta = FindMetaTable("Panel")
local OldSetSize = meta.SetSize

PANEL = {}

GM.VGUIItems = {}
local itemCount = 1
function PANEL:Init()
	GAMEMODE.VGUIItems[self] = true

	local physbox = vgui.Create("DPhysbox2", self)
	physbox.Item = self
	self.Physbox = physbox

	self.IsItem = true

	self.ID = itemCount
	itemCount = itemCount + 1
end

function PANEL:GetPhysbox() return self.Physbox end

function PANEL:SetSize(w, h)
	OldSetSize(self, w, h)
	if IsValid(self.Physbox) then self.Physbox:SetSize(w, h) end
end

function PANEL:Paint() end

function PANEL:OnRemove()
	GAMEMODE.VGUIItems[self] = nil
end

vgui.Register("PItem2", PANEL, "DPanel")