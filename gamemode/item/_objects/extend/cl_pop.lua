local meta = FindMetaTable("ItemObj")

function meta:Pop()
	self.gridPointEvaluator:RemoveFromInventoryCells()
	self.isInGridInventory = false
	self.isBeingPopped = true
	self.popTo = gamemode.Call("GetNewPopTo")
	self.popDir = (self.popTo - self.position):GetNormalized()
	gamemode.Call("PlaySnd", "pop")
end