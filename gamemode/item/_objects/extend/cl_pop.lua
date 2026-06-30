local meta = FindMetaTable("ItemObj")

function meta:Pop()
	self.gridPointEvaluator:RemoveFromInventoryCells()
	self.isInGridInventory = false
	self.isBeingPopped = true
	self.popDir = (gamemode.Call("GetPopTo") - self.position):GetNormalized()
	gamemode.Call("PlaySnd", "pop")
end