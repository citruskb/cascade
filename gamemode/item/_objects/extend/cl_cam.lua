local meta = FindMetaTable("ItemObj")

function meta:GetAdjCamPosition()
	local offsetAdj0 = self.itemData.camXYOffsetAdj
	local offsetAdj = offsetAdj0:IsZero() and offsetAdj0 or offsetAdj0:GetRotated(math.Ang(self.rotation))

	return self.position + self.physbox.camXYOffset + offsetAdj
end