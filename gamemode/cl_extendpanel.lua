local meta = FindMetaTable("Panel")

function meta:MakePopupMouse()
	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
end