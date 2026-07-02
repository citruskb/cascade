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
	GAMEMODE.backpack:BindItemObj(self:GetBackpackInputVars())
end

function meta:OnBackpackBind(originIDX, rotIDX)
	local wasPickedUp = self.isPickedUp

	self.isBound = true
	self.bindOriginIDX = originIDX
	self.desiredRotation = self:GetNearestAng(ITEM_ORIENTATION_TO_ANGLE[rotIDX])
	self.isPickedUp = false
	self.isInGridInventory = true

	if wasPickedUp and self.itemData.PlayPlaceSound then self.itemData.PlayPlaceSound() end
end