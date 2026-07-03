local meta = FindMetaTable("ItemObj")

local ROT_STEP_90_DEGREES = math.PI * 0.5
function meta:GetNearest90()
	local rot = math.Abs(self.rotation)
	while rot > ROT_STEP_90_DEGREES do rot = rot - ROT_STEP_90_DEGREES end

	-- Are we closer to zero degrees or 90?
	local closerToZero = rot - ROT_STEP_90_DEGREES * 0.5 < 0

	local rotCloserToZero = rot
	local rotFurtherFromZero = ROT_STEP_90_DEGREES - rot

	-- Turn the opposite way if we are negative.
	if self.rotation > 0 then
		return self.rotation + (closerToZero and -rotCloserToZero or rotFurtherFromZero)
	else
		return self.rotation - (closerToZero and -rotCloserToZero or rotFurtherFromZero)
	end
end

function meta:SnapToNearest90()
	self.desiredRotation = self:GetNearest90()
end

function meta:Rotate90CW()
	gamemode.Call("PlaySnd", "rotate", 0.7)
	self.desiredRotation = (self.desiredRotation or 0) + ROT_STEP_90_DEGREES
end

function meta:Rotate90CCW()
	gamemode.Call("PlaySnd", "rotate", 0.7, 80)
	self.desiredRotation = (self.desiredRotation or 0) - ROT_STEP_90_DEGREES
end

function meta:GetRotIDX()
	local ang = math.Ang(self:GetNearest90())
	return ITEM_ANGLE_TO_ORIENTATION[math.Round(ang, 0) % 360]
end