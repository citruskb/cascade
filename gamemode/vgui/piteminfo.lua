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
	if not itemData then return end

	local oldID = self.itemID
	self.itemID = itemData.id
	if oldID == self.itemID then return end

	self.data = itemData
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	if not self.data then return end

	-- Update information, resize.
	local name = self.data.name
	local description = self.data.description
	local txtCol = ItemRarityTxtColors[self.data.rarity]

	self.frame:SetTitle("")
	self.frame:SetSize(self:GetSize())
	self.frame:ShowCloseButton(false)
	self.frame:DockPadding(5, 5, 5, 5)
	self.frame:SetZPos(GM_ZPOS_ITEM_DESC)

	self.frameTitle:SetText(name)
	self.frameTitle:SetFont("FontItemName")
	self.frameTitle:SizeToContents()
	self.frameTitle:Dock(TOP)
	self.frameTitle:SetZPos(GM_ZPOS_ITEM_DESC)
	self.frameTitle:SetTextColor(txtCol)

	self.richtxt:Dock(FILL)
	self.richtxt:SetVerticalScrollbarEnabled(false)
	self.richtxt:SetText("")
	self.richtxt:InsertColorChange( txtCol.r, txtCol.g, txtCol.b, txtCol.a )
	self.richtxt:AppendText(description)
	self.richtxt.PerformLayout = function(pan)
		if pan:GetFont() ~= "FontItemDescription" then pan:SetFontInternal("FontItemDescription") end
	end
	self.richtxt:SetZPos(GM_ZPOS_ITEM_DESC)
end

function PANEL:Paint()
	if not self.data then return end
	local w, h = self:GetSize()
	local col = ItemRarityColors[self.data.rarity]

	surface.SetDrawColor(col)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("PItemInfo", PANEL, "DPanel")