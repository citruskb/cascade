function GM:StepItems()
	for item, _ in pairs(self.itemObjs) do
		item:StepItem()
	end
end