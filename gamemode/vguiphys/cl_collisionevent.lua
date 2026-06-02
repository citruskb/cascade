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

-- This is the actual root element we want to move based on collision events of the hitbox.
function meta:GetVGUIPhysRootA() return self:GetPanA():GetVGUIPhysRoot() end
function meta:GetVGUIPhysRootB() return self:GetPanB():GetVGUIPhysRoot() end

function meta:GetOverlap() return Rawget(self, "_overlap") end
function meta:SetOverlap(f) Rawset(self, "_overlap", f) end

-- Normal is a table with and x and y value associated with the 2D direction.
function meta:GetNormal() return Rawget(self, "_normal") end
function meta:SetNormal(tab) Rawset(self, "_normal", tab) end
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
end