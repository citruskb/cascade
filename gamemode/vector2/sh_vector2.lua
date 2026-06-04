local math_Sqrt = math.Sqrt

if not vec2 then
	vec2 = Class:Create(nil, "v2")
end

function Vector2(x, y) return v2:Create(x, y) end

local meta = FindMetaTable("vec2")
function meta:ThrowError(msg) Error("[Vector2] - " .. msg) end

function v2:__Create(x, y)
	if not IsNumber(x) or not IsNumber(y) then self:ThrowError("Tried to insert a non number into a vector!") end

	Rawset(self, "x", x)
	Rawset(self, "y", y)
	Rawset(self, "IsVector2", true)

	return self
end

function v2:Add(other)
	if not Rawget(other, "IsVector2") then self:ThrowError("The value being added needs to be a Vector2.") end

	local x = Rawget(self, "x") + Rawget(other, "x")
	local y = Rawget(self, "y") + Rawget(other, "y")
	return Vector2(x, y)
end

function v2:Div(other)
	if not IsNumber(other) then self:ThrowError("The divisor needs to be a number.") end

	local x = Rawget(self, "x") / other
	local y = Rawget(self, "y") / other
	return Vector2(x, y)
end

function v2:Eq(other)
	if not other.IsVector2 then return false end
	return Rawget(self, "x") == Rawget(other, "x") and Rawget(self, "y") == Rawget(other, "y")
end

function v2:Mul(other)
	if not IsNumber(other) then self:ThrowError("Can only multiply by a scalar value.") end

	local x = Rawget(self, "x") * other
	local y = Rawget(self, "y") * other
	return Vector2(x, y)
end

function v2:Sub(other)
	if not other.IsVector2 then self:ThrowError("The value being added needs to be a Vector2.") end

	local x = Rawget(self, "x") - Rawget(other, "x")
	local y = Rawget(self, "y") - Rawget(other, "y")
	return Vector2(x, y)
end

function v2:Unm()
	return Vector2(-Rawget(self, "x"), -Rawget(self, "y"))
end

function v2:ToString()
	return ToString(Rawget(self, "x")) .. " " .. ToString(Rawget(self, "y"))
end


-- [[ Other meta functions. ]]
function meta:Add(vec)
end
function meta:Length() return math_Sqrt(Rawget(self, "x") ^ 2 + Rawget(self, "y") ^ 2) end
-- [[	]]