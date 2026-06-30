local meta = FindMetaTable("ItemObj")

function meta:InitGridPointEvaluator()
	self.gridPointEvaluator = GridPointEvaluator:Create(
		self.itemData.gridPoints,
		self.itemData.gridPointsOffsets,
		self.itemData.gridPointsSynergies,
		self.itemData.type
	)
end

function meta:EvaluateGridInventoryPlacement()
	if not self.gridPointEvaluator:BindItem(self) then return end

	self.isPickedUp = false
	self.isInGridInventory = true

	if self.itemData.PlayPlaceSound then self.itemData.PlayPlaceSound() end
end