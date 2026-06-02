--[[
This exists so that we can store information about what happened in a collision.
At this point we already know a collision has happened. This resolves the collision.
]]--

if not VGUIColEvent then
	VGUIColEvent = Class:Create(nil, "VGUIColEvent")
end

local meta = FindMetaTable("VGUIColEvent")


-- [[ Getters and setters. ]]
function meta:GetPanA() return Rawget(self, "_pana") end
function meta:SetPanA(pan) Rawset(self, "_pana", pan) end
function meta:GetPanB() return Rawget(self, "_panb") end
function meta:SetPanB(pan) Rawset(self, "_panb", pan) end

function meta:GetOverlap() return Rawget(self, "_overlap") end
function meta:SetOverlap(f) Rawset(self, "_overlap", f) end

-- Normal is a table with and x and y value associated with the 2D direction.
function meta:GetNormal() return Rawget(self, "_normal") end
function meta:SetNormal(tab) Rawset(self, "_normal", tab) end

function meta:GetIDX() return Rawget(self, "_idx") end
function meta:SetIDX(int) Rawset(self, "_idx", int) end
-- [[	]]


function meta:ThrowError(err) Error("VGUIPhys: " .. err) end

function VGUIColEvent:__Create(panA, panB, overlap, normal)
	-- [[ Sanity checks. Probably to be removed once we're sure this works as intended. ]]
	if not IsValid(panA) then self:ThrowError("panA is invalid") end
	if not IsValid(panB) then self:ThrowError("panB is invalid") end
	if not overlap or (overlap and not isnumber(overlap)) then self:ThrowError("overlap is invalid or not a number") end
	if not normal or (normal and (not normal.x or not normal.y)) then self:ThrowError("normal is invalid or not structured properly") end
	-- [[	]]

	Rawset(self, "_pana", panA)
	Rawset(self, "_panb", panB)
	Rawset(self, "_overlap", overlap)
	Rawset(self, "_normal", normal)

	local idx = table.Insert(GAMEMODE.VGUIColEvents, self)
	Rawset(self, "_idx", idx)

	self.isVGUIColEvent = true
end

function VGUIColEvent:Call()
	local vphysA, vphysB = self:GetPanA(), self:GetPanB()
	local rootA, rootB = vphysA:GetParent(), vphysB:GetParent()
	local overlap, normal = self:GetOverlap(), self:GetNormal()

	-- Now apply the force to the root objects.
	-- The root might be invalid if we are a solid wall!
	if IsValid(rootA) and rootA.AddVel then
		-- The normal vector is always pointing AWAY from the surface of element A.
		local forceA = {x = -normal.x * overlap, y = -normal.y * overlap}
		rootA:AddVel(forceA.x, forceA.y)
	end
	if IsValid(rootB) and rootB.AddVel then
		local forceB = {x = normal.x * overlap, y = normal.y * overlap}
		rootB:AddVel(forceB.x, forceB.y)
	end

	-- Did our job.
	self:Remove()
end

function VGUIColEvent:ToString()
	local str = "[VGUIColEvent] "
	str = str .. self:GetVGUIPhysRootA() .. " x " .. self:GetVGUIPhysRootB()
	str = str .. " | overlap: " .. self:GetOverlap()

	local n = self:GetNormal()
	str = str .. " | normal: (" .. n.x .. ", " .. n.y .. ")"

	return str
end

function VGUIColEvent:Eq(other)
	if not self.isVGUIColEvent or not other.isVGUIColEvent then return false end

	local rootA, rootB = self:GetVGUIPhysRootA(), self:GetVGUIPhysRootB()
	local oRootA, oRootB = other:GetVGUIPhysRootA(), other:GetVGUIPhysRootB()

	if rootA == oRootA and rootB == oRootB then return true end
	if rootA == oRootB and rootB == oRootA then return true end

	return false
end

function meta:Remove()
	table.Remove(GAMEMODE.VGUIColEvents, self:GetIDX())
	table.Empty(self)
end