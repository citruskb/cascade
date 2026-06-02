--[[
This exists so that we can store information about what happened in a collision.
At this point we already know a collision has happened. This resolves the collision.
]]--

if not VGUIColEvent then
	VGUIColEvent = Class:Create(nil, "VGUIColEvent")
end

local meta = FindMetaTable("VGUIColEvent")


-- [[ Getters and setters. ]]
function meta:GetVPhysA() return Rawget(self, "_vphysa") end
function meta:SetVPhysA(pan) Rawset(self, "_vphysa", pan) end
function meta:GetVPhysB() return Rawget(self, "_vphysb") end
function meta:SetVPhysB(pan) Rawset(self, "_vphysb", pan) end

function meta:GetParentA()
	if not IsValid(self:GetVPhysA()) then return end
	return self:GetVPhysA():GetParent()
end
function meta:GetParentB()
	if not IsValid(self:GetVPhysB()) then return end
	return self:GetVPhysB():GetParent()
end

function meta:GetOverlap() return Rawget(self, "_overlap") end
function meta:SetOverlap(f) Rawset(self, "_overlap", f) end

-- Normal is a table with and x and y value associated with the 2D direction.
function meta:GetNormal() return Rawget(self, "_normal") end
function meta:SetNormal(tab) Rawset(self, "_normal", tab) end

function meta:GetIDX() return Rawget(self, "_idx") end
function meta:SetIDX(int) Rawset(self, "_idx", int) end
-- [[	]]


function meta:ThrowError(err) Error("VGUIPhys: " .. err) end

function VGUIColEvent:__Create(vphysA, vphysB, overlap, normal)
	-- [[ Sanity checks. Probably to be removed once we're sure this works as intended. ]]
	if not IsValid(vphysA) then self:ThrowError("vphysA is invalid") end
	if not IsValid(vphysB) then self:ThrowError("vphysB is invalid") end
	if not overlap or (overlap and not isnumber(overlap)) then self:ThrowError("overlap is invalid or not a number") end
	if not normal or (normal and (not normal.x or not normal.y)) then self:ThrowError("normal is invalid or not structured properly") end
	-- [[	]]

	Rawset(self, "_vphysa", vphysA)
	Rawset(self, "_vphysb", vphysB)
	Rawset(self, "_overlap", overlap)
	Rawset(self, "_normal", normal)

	local idx = table.Insert(GAMEMODE.VGUIColEvents, self)
	Rawset(self, "_idx", idx)

	self.isVGUIColEvent = true
end

function VGUIColEvent:Call()
	local rootA, rootB = self:GetParentA(), self:GetParentB()
	local overlap, normal = self:GetOverlap(), self:GetNormal()

	-- Now apply the force to the root objects.
	-- The root might be invalid if we are a solid wall!
	local TranslateA = {x = -normal.x * overlap / 2, y = -normal.y * overlap / 2}
	local TranslateB = {x = normal.x * overlap / 2, y = normal.y * overlap / 2}
	if IsValid(rootA) and rootA.AddMPos then
		-- The normal vector is always pointing AWAY from the surface of element A.
		--rootA:AddVel(forceA.x, forceA.y)
		rootA:AddMPos(TranslateA.x, TranslateA.y)
	end
	if IsValid(rootB) and rootB.AddMPos then
		rootB:AddMPos(TranslateB.x, TranslateB.y)
	end

	--[[
	print("DID COLLISION!!", SysTime())
	PrintTable(forceA)
	PrintTable(forceB)
	]]

	-- Did our job.
	self:Remove()
end

function VGUIColEvent:ToString()
	local str = "[VGUIColEvent] "
	str = str .. self:GetParentA() .. " x " .. self:GetParentB()
	str = str .. " | overlap: " .. self:GetOverlap()

	local n = self:GetNormal()
	str = str .. " | normal: (" .. n.x .. ", " .. n.y .. ")"

	return str
end

function VGUIColEvent:Eq(other)
	if not self.isVGUIColEvent or not other.isVGUIColEvent then return false end

	local rootA, rootB = self:GetParentA(), self:GetParentB()
	local oRootA, oRootB = other:GetParentA(), other:GetParentB()

	if rootA == oRootA and rootB == oRootB then return true end
	if rootA == oRootB and rootB == oRootA then return true end

	return false
end

function meta:Remove()
	table.Remove(GAMEMODE.VGUIColEvents, self:GetIDX())
	table.Empty(self)
end