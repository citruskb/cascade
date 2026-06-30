local meta = FindMetaTable("ItemObj")

local ROT_STEP = math.PI * 0.5 -- 90 degrees in radians
function meta:GetNearest90()
	local rot = math.Abs(self.rotation)
	while rot > ROT_STEP do rot = rot - ROT_STEP end

	-- Are we closer to zero degrees or 90?
	local closerToZero = rot - ROT_STEP * 0.5 < 0

	local rotCloserToZero = rot
	local rotFurtherFromZero = ROT_STEP - rot

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
	gamemode.Call("PlaySnd", "rotate", 0.16, math.Random(100, 105))
	self.desiredRotation = (self.desiredRotation or 0) + ROT_STEP
end

function meta:Rotate90CCW()
	gamemode.Call("PlaySnd", "rotate", 0.16, math.Random(80, 85))
	self.desiredRotation = (self.desiredRotation or 0) - ROT_STEP
end