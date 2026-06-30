function GM:StepItems()
	for item, _ in pairs(self.itemObjs) do
		item:StepItem()
	end
end

function GM:GetPopTo()
	if GM_PopTo then return GM_PopTo end

	local w, h = ScrW(), ScrH()
	GM_PopTo = Vector2(w * 0.55, h * 0.5)

	return GM_PopTo
end

-- Recache our PopTo location if we resize our screen.
hook.Add("ScreenScaleChanged", "ScreenScaleChanged.GetPopTo", function() GM_PopTo = nil end)