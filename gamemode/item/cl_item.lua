function GM:StepItems()
	for item, _ in pairs(self.itemObjs) do
		item:StepItem()
	end
end

function GM:GetNewPopTo()
	local w, h = ScrW(), ScrH()
	return Vector2(w * 0.55, h * (0.5 + 0.3 * math.Rand(-1, 1)))
end