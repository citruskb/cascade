PANEL = {}

function PANEL:Init()
	self:SetZPos(GM_ZPOS_ITEM_DESC)

	local w, h = ScrW(), ScrH()
	self:SetSize(w * 0.2, h * 0.4)
	self:SetPos(w * 0.2, h * 0.6)

	self.frame = vgui.Create("DFrame", self)
	self.frameTitle = vgui.Create("DLabel", self.frame)
	self.richtxt = vgui.Create("RichText", self.frame)
end

function PANEL:SetItemData(itemData)
	self.itemID = itemData.id
	self.data = itemData
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	-- Update information, resize.
	local name = self.data.name
	local description = self.data.description

	self.frame:SetTitle("")
	self.frame:SetSize(self:GetSize())
	self.frame:ShowCloseButton(false)
	self.frame:DockPadding(5, 5, 5, 5)
	self.frame:SetZPos(GM_ZPOS_ITEM_DESC)

	self.frameTitle:SetText(name)
	self.frameTitle:SetFont("SFontLarge")
	self.frameTitle:SizeToContents()
	self.frameTitle:Dock(TOP)
	self.frameTitle:SetZPos(GM_ZPOS_ITEM_DESC)

	self.richtxt:Dock(FILL)
	self.richtxt:SetVerticalScrollbarEnabled(false)
	self.richtxt:SetText(description)
	self.richtxt.PerformLayout = function(pan)
		if pan:GetFont() ~= "DFontSmall" then pan:SetFontInternal("DFontSmall") end
	end
	self.richtxt:SetZPos(GM_ZPOS_ITEM_DESC)
end

function PANEL:Paint()
end

vgui.Register("PItemInfo", PANEL, "DPanel")