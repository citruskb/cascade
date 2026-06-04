local math_Sqrt = math.Sqrt
local math_Atan2 = math.Atan2
local math_Rand = math.Rand
local math_Cos = math.Cos
local math_Sin = math.Sin
local math_PI = math.PI

VECTOR2_ZERO = Vector2(0, 0)

local function GetNormalVars(vector2)
	local len = vector2:Length()
	local nx = Rawget(vector2, "x") / len
	local ny = Rawget(vector2, "y") / len

	return nx, ny
end

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
	local x = Rawget(self, "x") + Rawget(other, "x")
	local y = Rawget(self, "y") + Rawget(other, "y")
	return Vector2(x, y)
end

function v2:Div(other)
	local x = Rawget(self, "x") / other
	local y = Rawget(self, "y") / other
	return Vector2(x, y)
end

function v2:Eq(other)
	if not other.IsVector2 then return false end
	return Rawget(self, "x") == Rawget(other, "x") and Rawget(self, "y") == Rawget(other, "y")
end

function v2:Mul(other)
	local x = Rawget(self, "x") * other
	local y = Rawget(self, "y") * other
	return Vector2(x, y)
end

function v2:Sub(other)
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

-- Adds vectors without making a new object.
function meta:Add(vec)
	Rawset(self, "x", Rawget(self, "x") + Rawget(vec, "x"))
	Rawset(self, "y", Rawget(self, "y") + Rawget(vec, "y"))
	Rawset(self, "_length", nil)
end

-- Get the angle of our vector relative to the positive x axis.
function meta:Angle()
	local nx, ny = GetNormalVars(self)
	local rad = math_Atan2(ny, nx)
	return rad * 180 / math_PI
end

-- TODO: meta:AngleEx(vec)

-- Cross product of two vectors.
function meta:Cross(other)
	local x, y = Rawget(self, "x"), Rawget(self, "y")
	local ox, oy = Rawget(other, "x"), Rawget(other, "y")
	return x * oy - y * ox
end

-- The squared distance between two vectors.
function meta:DistanceSqr(other)
	local dx = Rawget(self, "x") - Rawget(other, "x")
	local dy = Rawget(self, "y") - Rawget(other, "y")
	return dx^2 + dy^2
end

-- The distance between two vectors. Warning. This is expensive.
function meta:Distance(other)
	return math_Sqrt(self:DistanceSqr(other))
end

-- Divides, changing this vector instead of making an entirely new one.
function meta:Div(divisor)
	Rawset(self, "x", Rawget(self, "x") / divisor)
	Rawset(self, "y", Rawget(self, "y") / divisor)

	local cachedLen = Rawget(self, "_length")
	if cachedLen then Rawset(self, "_length", cachedLen / divisor) end
end

-- Dot product of two vectors.
function meta:Dot(other)
	local x, y = Rawget(self, "x"), Rawget(self, "y")
	local ox, oy = Rawget(other, "x"), Rawget(other, "y")
	return x * ox + y * oy
end

-- Return a new vector that's a normalized version of this vector.
function meta:GetNormalized()
	local nx, ny = GetNormalVars(self)
	return Vector2(nx, ny)
end

-- Returns if a vector is equal within a given tolerance
function meta:IsEqualTol(compare, tol)
	local x, y = Rawget(self, "x"), Rawget(self, "y")
	local cx, cy = Rawget(compare, "x"), Rawget(compare, "y")

	local lx, hx = x - tol, x + tol
	local ly, hy = y - yol, y + tol

	return cx >= lx and cx <= hx and cy >= ly and cy <= hy
end

-- Checks if all vector fields are zero.
function meta:IsZero()
	return Rawget(self, "x") == 0 and Rawget(self, "y") == 0
end

-- Since finding the length is such an expensive operation and it normally doesn't change we cache the result.
function meta:Length()
	local len = Rawget(self, "_length")
	if not len then
		len = math_Sqrt(self:LengthSqr())
		Rawset(self, "_length", len)
	end

	return len
end

-- Finds the square of the length.
function meta:LengthSqr()
	return Rawget(self, "x") ^ 2 + Rawget(self, "y") ^ 2
end

-- The same as Mul above, but modifies this vector.
function meta:Mul(num)
	Rawset(self, "x", Rawget(self, "x") * num)
	Rawset(self, "y", Rawget(self, "y") * num)

	local cachedLen = Rawget(self, "_length")
	if cachedLen then Rawset(self, "_length", cachedLen * num) end
end

-- Inverts signs of this vector. The same as Unm except modifies this vector.
function meta:Negate()
	Rawset(self, "x", -Rawget(self, "x"))
	Rawset(self, "y", -Rawget(self, "y"))
end

-- Change this vector to be length of 1 in the same direction.
function meta:Normalize()
	local nx, ny = GetNormalVars(self)
	Rawset(self, "x", nx)
	Rawset(self, "y", ny)
	Rawset(self, "_length", 1)
end

-- Randomizes the x and y values of this vector.
function meta:Random(min, max)
	min = min or -1
	max = max or 1

	Rawset(self, "x", math_Rand(min, max))
	Rawset(self, "y", math_Rand(min, max))
end

-- Rotates this vector counterclockwise by the given angle
function meta:Rotate(angle)
	local rad = angle * math_PI / 180
	local cos = math_Cos(rad)
	local sin = math_Sin(rad)

	local x, y = Rawget(self, "x"), Rawget(self, "y")

	Rawset(self, "x", x * cos - y * sin)
	Rawset(self, "y", x * sin + y * cos)
end

-- Copies values from the second vector to this one.
function meta:Set(other)
	Rawset(self, "x", Rawget(other, "x"))
	Rawset(self, "y", Rawget(other, "y"))
end

-- Sets the x and y of the vector.
function meta:SetUnpacked(x, y)
	Rawset(self, "x", x)
	Rawset(self, "y", y)
end

-- The same as Sub above but modifies this vector.
function meta:Sub(other)
	Rawset(self, "x", Rawget(self, "x") - Rawget(other, "x"))
	Rawset(self, "y", Rawget(self, "y") - Rawget(other, "y"))
end

-- Returns this vector as a table.
function meta:ToTable()
	return {x = Rawget(self, "x"), y = Rawget(self, "y")}
end

-- Returns the x and y of this vector.
function meta:Unpack()
	return Rawget(self, "x"), Rawget(self, "y")
end

-- TODO meta:WithinAABox

-- Sets vector values to zero.
function meta:Zero()
	Rawset(self, "x", 0)
	Rawset(self, "y", 0)
end

-- [[	]]