local meta = FindMetaTable("ItemObj")

function meta:Pop()
	if self.boundTo then self.boundTo:UnbindItem(self) end

	self.isInGridInventory = false

	-- If we have no owner, then just remove the item.
	-- TODO: account for ownership of the shop owner and such to adjust pop behavior.
	if self.owner ~= MySelf then
		self:Remove()
		return
	end

	self.isBeingPopped = true

	if SERVER then return end
	self.popTo = gamemode.Call("GetNewPopTo")
	self.popDir = (self.popTo - self.position):GetNormalized()
	gamemode.Call("PlaySnd", "pop")
end