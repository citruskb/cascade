local math_Sqrt = math.Sqrt
local math_Atan2 = math.Atan2
local math_Rand = math.Rand
local math_Cos = math.Cos
local math_Sin = math.Sin
local math_Min = math.Min
local math_Max = math.Max
local math_PI = math.PI

local function GetNormalVars(vector2)
	local len = vector2:Length()
	local nx = Rawget(vector2, "x") / len
	local ny = Rawget(vector2, "y") / len

	return nx, ny
end

if not v2 then
	v2 = Class:Create(nil, "v2")
end

local meta = FindMetaTable("v2")
function meta:ThrowError(msg) Error("[Vector2] - " .. msg) end

function v2:__Create(x, y)
	if not IsNumber(x) or not IsNumber(y) then self:ThrowError("Tried to insert a non number into a vector!") end

	Rawset(self, "x", x)
	Rawset(self, "y", y)
	Rawset(self, "IsVector2", true)

	return self
end
function v2:Add(other)		return Vector2(Rawget(self, "x") + Rawget(other, "x"), Rawget(self, "y") + Rawget(other, "y")) end
function v2:Div(other)		return Vector2(Rawget(self, "x") / other, Rawget(self, "y") / other) end
function v2:Eq(other)		return other.IsVector2 and Rawget(self, "x") == Rawget(other, "x") and Rawget(self, "y") == Rawget(other, "y") end
function v2:Mul(other)		return Vector2(Rawget(self, "x") * other, Rawget(self, "y") * other) end
function v2:Sub(other)		return Vector2(Rawget(self, "x") - Rawget(other, "x"), Rawget(self, "y") - Rawget(other, "y")) end
function v2:Unm()			return Vector2(-Rawget(self, "x"), -Rawget(self, "y")) end
function v2:ToString()		return ToString(Rawget(self, "x")) .. " " .. ToString(Rawget(self, "y")) end


-- [[ Other meta functions. ]]

-- Adds vector without making a new object.
function meta:DoAdd(other)
	Rawset(self, "x", Rawget(self, "x") + Rawget(other, "x"))
	Rawset(self, "y", Rawget(self, "y") + Rawget(other, "y"))
	Rawset(self, "_length", nil)
end

-- Get the angle of our vector relative to the positive x axis.
function meta:Angle()
	local nx, ny = GetNormalVars(self)
	local rad = math_Atan2(ny, nx)
	return rad * 180 / math_PI
end

-- Cross product of two vectors.
function meta:Cross(other)
	local x, y = Rawget(self, "x"), Rawget(self, "y")
	local ox, oy = Rawget(other, "x"), Rawget(other, "y")
	return x * oy - y * ox
end

-- Cross product of vector and a scalar
function meta:CrossS(scalar)
	return Vector2(-scalar * Rawget(self, "y"), scalar * Rawget(self, "x"))
end

-- The squared distance between two vectors.
function meta:DistanceSqr(other)
	local dx = Rawget(self, "x") - Rawget(other, "x")
	local dy = Rawget(self, "y") - Rawget(other, "y")
	return dx ^ 2 + dy ^ 2
end

-- The distance between two vectors. Warning. This is expensive.
function meta:Distance(other) return math_Sqrt(self:DistanceSqr(other)) end

-- Divides, changing this vector instead of making an entirely new one.
function meta:DoDiv(divisor)
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

-- Return the vector normal to the vector that connects two vectors.
function meta:GetConnectingNormal(other)
	local normal = Vector2(Rawget(other, "y") - Rawget(self, "y"), Rawget(self, "x") - Rawget(other, "x"))
	normal:Normalize()
	return normal
end

-- Returns if a vector is equal within a given tolerance
function meta:IsEqualTol(compare, tol)
	local x, y = Rawget(self, "x"), Rawget(self, "y")
	local cx, cy = Rawget(compare, "x"), Rawget(compare, "y")

	local lx, hx = x - tol, x + tol
	local ly, hy = y - tol, y + tol

	return cx >= lx and cx <= hx and cy >= ly and cy <= hy
end

-- Checks if all vector fields are zero.
function meta:IsZero() return Rawget(self, "x") == 0 and Rawget(self, "y") == 0 end

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
function meta:LengthSqr() return Rawget(self, "x") ^ 2 + Rawget(self, "y") ^ 2 end

-- The same as Mul above, but modifies this vector.
function meta:DoMul(num)
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
function meta:DoSub(other)
	Rawset(self, "x", Rawget(self, "x") - Rawget(other, "x"))
	Rawset(self, "y", Rawget(self, "y") - Rawget(other, "y"))
end

-- Returns this vector as a table.
function meta:ToTable() return {x = Rawget(self, "x"), y = Rawget(self, "y")} end

-- Returns the x and y of this vector.
function meta:Unpack() return Rawget(self, "x"), Rawget(self, "y") end

-- Returns if this vector is inside the AABox formed by the two given vectors.
function meta:WithinAABox(vectorB, vectorC)
	local xA, yA = self:Unpack()
	local xB, yB = vectorB:Unpack()
	local xC, yC = vectorB:Unpack()

	local minX = math_Min(xB, xC)
	local maxX = math_Max(xB, xC)
	local minY = math_Min(yB, yC)
	local maxY = math_Max(yB, yC)

	return xA >= minX and xA <= maxX and yA >= minY and yA <= maxY
end

-- Sets vector values to zero.
function meta:Zero() Rawset(self, "x", 0) Rawset(self, "y", 0) end

-- [[	]]


function Vector2(x, y) return v2:Create(x or 0, y or 0) end
VECTOR2_ZERO = Vector2()
