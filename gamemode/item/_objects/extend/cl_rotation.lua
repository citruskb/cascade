local meta = FindMetaTable("ItemObj")

local ROT_STEP_90_DEGREES = math.PI * 0.5
function meta:GetNearestAng(degrees)
	local rotStep = degrees * math.PI / 180

	local rot = math.Abs(self.rotation)
	while rot > rotStep do rot = rot - rotStep end

	-- Are we closer to zero degrees or 90?
	local closerToZero = rot - rotStep * 0.5 < 0

	local rotCloserToZero = rot
	local rotFurtherFromZero = rotStep - rot

	-- Turn the opposite way if we are negative.
	if self.rotation > 0 then
		return self.rotation + (closerToZero and -rotCloserToZero or rotFurtherFromZero)
	else
		return self.rotation - (closerToZero and -rotCloserToZero or rotFurtherFromZero)
	end
end

function meta:SnapToNearestAng(degrees)
	self.desiredRotation = self:GetNearestAng(degrees)
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
	return ITEM_ANGLE_TO_ORIENTATION[self:GetNearestAng(90)]
end