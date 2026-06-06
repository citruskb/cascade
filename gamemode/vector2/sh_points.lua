-- This does assume that vectors within this object aren't directly changed. 
-- Doing so would break this collection. Instead, copy the points to table, make your change, and set the new array to this object. 

if not __points then
	__points = Class:Create(nil, "__points")
end

local meta = FindMetaTable("__points")
function meta:ThrowError(msg) Error("[Points] - " .. msg) end

function meta:GetPoints() return Rawget(self, "_points") end
function meta:SetPoints(tab)
	Rawset(self, "_points", tab)
	self:MarkAllDirty()
end

function meta:GetCenter()
	if Rawget(self, "_centerdirty") then self:RecacheCenter() end
	return Rawget(self, "_center")
end
function meta:SetCenter(x, y)
	Rawget(self, "_center"):SetUnpacked(x, y)
	self:MarkCenterUpdated()
end
function meta:SetCenterV(vec2)
	Rawget(self, "_center"):Set(vec2)
	self:MarkCenterUpdated()
end

function meta:GetTable()
	if Rawget(self, "_tabledirty") then self:RecacheTable() end
	return Rawget(self, "_table")
end
function meta:SetTable(tab)
	Rawset(self, "_table", tab)
	self:MarkTableUpdated()
end

function meta:GetCenterDirty() return Rawget(self, "_centerdirty") end
function meta:MarkCenterDirty() Rawset(self, "_centerdirty", true) end
function meta:MarkCenterUpdated() Rawset(self, "_centerdirty", false) end

function meta:GetTableDirty() return Rawget(self, "_tabledirty") end
function meta:MarkTableDirty() Rawset(self, "_tabledirty", true) end
function meta:MarkTableUpdated() Rawset(self, "_tabledirty", false) end

function meta:MarkAllDirty()
	self:MarkCenterDirty()
	self:MarkTableDirty()
end

function __points:__Create(tab)
	if not IsTable(tab) then self:ThrowError("Points must be in table form!") end

	Rawset(self, "_points", tab)
	Rawset(self, "_center", Vector2())
	Rawset(self, "_table", {})
	Rawset(self, "IsPoints", true)
	self:MarkAllDirty()

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
		self:MarkAllDirty()
		return self
	elseif other.IsPoints then
		local ret = {}
		table.Add(ret, pointstab)

		local otherPointstab = Rawget(other, "_points")
		table.Add(ret, otherPointstab)

		return ret
	end
end

function meta:RecacheCenter()
	local p = Rawget(self, "_points")
	local minX, maxX, minY, maxY
	for i = 1, #p do
		local x, y = p[i]:Unpack()

		if not minX or minX and x < minX then minX = x end
		if not maxX or maxX and x > maxX then maxX = x end
		if not minY or minY and y < minY then minY = y end
		if not maxY or maxY and y > maxY then maxY = y end
	end

	self:SetCenter(minX + maxX / 2, minY + maxY / 2)
end

function meta:RecacheTable()
	local tab = {}
	local p = Rawget(self, "_points")
	for i = 1, #p do
		tab[i] = p[i]:ToTable()
	end

	self:SetTable(tab)
end

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
		local newVec = Vector2()
		tab[i] = newVec:Set(points[i])
	end

	return Points(tab)
end

function Points(tab) return __points:Create(tab) end