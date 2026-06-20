if not VGUIAABB then
	VGUIAABB = Class:Create(nil, "VGUIAABB")
end

local meta = FindMetaTable("VGUIAABB")

function VGUIAABB:__Create(min, max)
	self.min = min
	self.max = max
	return self
end

function meta:Expand(pointsObj)
	local points = pointsObj:GetPoints()
	for i = 1, #points do
		local point = points[i]
		self.min = self.min:GetMin(point)
		self.max = self.max:GetMax(point)
	end
end

function meta:Overlaps(other)
	return
		self.min.x <= other.max.x and
		self.max.x >= other.min.x and
		self.min.y <= other.max.y and
		self.max.y >= other.min.y
end