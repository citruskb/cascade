PANEL = {}

function PANEL:Init()
	self:SetZPos(GM_ZPOS_ITEM_DESC)
end

function PANEL:SetItemData(itemData)
	self.data = itemData
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	-- Update information, resize.
	local name = self.data.name
	local description = self.data.description

	local w, h = ScrW(), ScrH()

	self.frame = vgui.Create("DFrame")
	self.frame:SetSize(w * 0.2, h * 0.4)
	self.frame:SetPos(w * 0.2, h * 0.6)
	self.frame:SetTitle("")
	self.frame:ShowCloseButton(false)
	self.frame:DockPadding(5, 5, 5, 5)
	self.frame:SetZPos(GM_ZPOS_ITEM_DESC)

	local frameTitle = vgui.Create("DLabel", self.frame)
	frameTitle:SetText(name)
	frameTitle:SetFont("SFontHuge")
	frameTitle:SizeToContents()
	frameTitle:Dock(TOP)
	frameTitle:SetZPos(GM_ZPOS_ITEM_DESC)

	self.richtxt = vgui.Create("RichText", self.frame)
	self.richtxt:Dock(FILL)
	self.richtxt:SetVerticalScrollbarEnabled(false)
	self.richtxt:SetText(description)
	self.richtxt.PerformLayout = function(pan)
		if pan:GetFont() ~= "DFontRegular" then pan:SetFontInternal("DFontRegular") end
	end
	self.richtxt:SetZPos(GM_ZPOS_ITEM_DESC)
end

function PANEL:Paint()
end

vgui.Register("PItemInfo", PANEL, "DPanel")