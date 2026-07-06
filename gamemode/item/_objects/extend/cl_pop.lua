local meta = FindMetaTable("ItemObj")

function meta:Pop()
	if self.boundTo then self.boundTo:UnbindItem(self) end

	self.isInGridInventory = false
	self.isBeingPopped = true

	if SERVER then return end
	self.popTo = gamemode.Call("GetNewPopTo")
	self.popDir = (self.popTo - self.position):GetNormalized()
	gamemode.Call("PlaySnd", "pop")
end