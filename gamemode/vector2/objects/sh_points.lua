-- This does assume that vectors within this object aren't directly changed. 
-- Doing so would break this collection. Instead, copy the points to table, make your change, and set the new array to this object. 

if not __points then
	__points = Class:Create(nil, "__points")
end

local meta = FindMetaTable("__points")
function meta:ThrowError(msg) Error("[Points] - " .. msg) end

function meta:GetPoints() return Rawget(self, "_points") end
function meta:SetPoints(tab) Rawset(self, "_points", tab) end

function __points:__Create(tab)
	if not IsTable(tab) then self:ThrowError("Points must be in table form!") end

	Rawset(self, "_points", tab)
	Rawset(self, "_center", Vector2())
	Rawset(self, "IsPoints", true)

	return self
end

function __points:ToString()
	local str = "[Points]\n"
	local pointstab = self:GetPoints()
	for i = 1, #pointstab do
		str = str .. "[#" .. i .. "] " .. ToString(pointstab[i])

		if i ~= #pointstab then str = str .. "\n" end
	end
	return str
end

function __points:Add(other)
	local pointstab = Rawget(self, "_points")

	if other.IsVector2 then
		table.Insert(pointstab, other)
		return self
	elseif other.IsPoints then
		local ret = {}
		table.Add(ret, pointstab)

		local otherPointstab = Rawget(other, "_points")
		table.Add(ret, otherPointstab)

		return Points(ret)
	end
end

function meta:GetCenter() return Vector2(self:GetMinX() + self:GetMaxX() * 0.5, self:GetMinY() + self:GetMaxY() * 0.5) end

function meta:GetTable()
	local tab = {}
	local p = Rawget(self, "_points")
	for i = 1, #p do
		tab[i] = p[i]:ToTable()
	end

	return tab
end

function meta:GetMinX()
	local minX
	local points = self:GetPoints()
	for i = 1, #points do
		local x, _ = points[i]:Unpack()
		if not minX or minX and x < minX then minX = x end
	end

	return minX
end

function meta:GetMaxX()
	local maxX
	local points = self:GetPoints()
	for i = 1, #points do
		local x, _ = points[i]:Unpack()
		if not maxX or maxX and x > maxX then maxX = x end
	end

	return maxX
end

function meta:GetMinY()
	local minY
	local points = self:GetPoints()
	for i = 1, #points do
		local _, y = points[i]:Unpack()
		if not minY or minY and y < minY then minY = y end
	end

	return minY
end

function meta:GetMaxY()
	local maxY
	local points = self:GetPoints()
	for i = 1, #points do
		local _, y = points[i]:Unpack()
		if not maxY or maxY and y > maxY then maxY = y end
	end

	return maxY
end

function meta:Count() return #Rawget(self, "_points") end

function meta:ToTable()
	local tab = self:GetTable()
	local copy = {}
	for i = 1, #tab do
		copy[i] = {x = Rawget(Rawget(tab, i), "x"), y = Rawget(Rawget(tab, i), "y")}
	end

	return copy
end

function meta:Copy()
	local points = self:GetPoints()
	local tab = {}
	for i = 1, #points do
		tab[i] = Vector2(points[i]:Unpack())
	end

	return Points(tab)
end

function meta:Translate(vec2)
	local copy = self:Copy()
	local points = copy:GetPoints()
	for i = 1, #points do
		points[i]:DoAdd(vec2)
	end

	return copy
end

function meta:IntersectAABB(other)
	local minX, minY, maxX, maxY = self:GetMinX(), self:GetMinY(), self:GetMaxX(), self:GetMaxY()
	local oMinX, oMinY, oMaxX, oMaxY = other:GetMinX(), other:GetMinY(), other:GetMaxX(), other:GetMaxY()

	if
		maxX <= oMinX or
		oMaxX <= minX or
		maxY <= oMinY or
		oMaxY <= minY then
			return false
	end

	return true
end


function Points(tab) return __points:Create(tab) end