local meta = FindMetaTable("ItemObj")

function meta:Pop()
	--self:RemoveFromInventoryCells()
	--self.isInGridInventory = false
	self.isBeingPopped = true
	self.popDir = (gamemode.Call("GetPopTo") - self.position):GetNormalized()
	gamemode.Call("PlaySnd", "pop")
end