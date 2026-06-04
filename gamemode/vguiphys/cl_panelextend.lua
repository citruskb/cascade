local meta = FindMetaTable("Panel")

local OldSetPos = meta.SetPos
function meta:SetPos(x, y)
	local vec2 = self.vpos
	if not vec2 then
		self.vpos = Vector2(x, y)
	else
		vec2:SetUnpacked(x, y)
	end

	OldSetPos(self, x, y)
end

function meta:GetVPos()
	local vec2 = self.vpos
	if not vec2 then -- Just in case.
		vec2 = Vector2(self:GetPos())
		self.vpos = vec2
	end

	return vec2
end