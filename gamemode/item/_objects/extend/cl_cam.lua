local meta = FindMetaTable("ItemObj")

function meta:GetAdjCamPosition()
	return self.position + self.physbox.camXYOffset + self.itemData.camXYOffsetAdj
end