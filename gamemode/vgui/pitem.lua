-- Representative of an underlying game object.
-- Need to pull said data from that registered object and display it here.


-- [[ Step 1 ]]
-- Need to define collection of "hitbox" panels for physics collision
-- dCollisionPanel?
-- These hitbox panels may be irregularly shapped (Circular? Polynomial?)
-- example: https://gist.github.com/meepen/4b591bf1e26ec9ad97df244a6f265d29


-- [[ Step 2 ]]
-- Physics can be on or off
	-- Collides & bounces against other objects while physics is on

-- Can be frozen or unfrozen
	-- Frozen (physics disabled): in shop, or set in grid inventory, or preview
	-- Unfrozen (physics enabled): in inventory


-- [[ Step 3 ]]
-- Snap into and out of inventory grid
-- Optionally can be placed tangental to the existing grid


-- [[ Step 4 ]]
-- Displays object through a 3d model projected on 2d surface
	-- Define details like item size, rotation, color, etc from registered object data?

-- Specific animation sequence that plays when item activates
-- Could spin, flash, grow and shrink in size, shake, wobble, etc

-- Add noises to pick up/dropping and to collision bounce
if not GM.PhysicsItems then GM.PhysicsItems = {} end

ITEM_GRAVITY = 2

PANEL = {}

function PANEL:Init()
	self:DisablePhysics()

	local hb = vgui.Create("DHitbox")
	hb.Shape = POLY_RECTANGULAR
	hb.ShapeW = 100
	hb.ShapeH = 50
	hb.Angle = 0
	hb:InvalidateLayout(true)
	self.hb = hb
end

function PANEL:Paint() end

function PANEL:Think()
	if not self.Physics then return end

	-- Update position based on gravity.
	local x, y = self:GetPos()
	local vx, vy = self:GetVelocity()

	-- Update postion based on velocity.
	self:SetPos(x + vx, y + vy)

	-- If our colliders are overlapping with any other colliders, then
end

function PANEL:SetVelocity(x, y)
	self.VX = x
	self.VY = y
end
function PANEL:AddVelocity(xAdd, yAdd)
	self.VX = x + xAdd
	self.VY = y + yAdd
end
function PANEL:GetVelocity() return self.VX, self.VY end
function PANEL:EnablePhysics()
	self.Physics = true
	self.vx, self.vy = 0, 0

	-- Add to global tab to receive physics updates.
	self.idx = table.Insert(GM.PhysicsItems, self)
end
function PANEL:DisablePhysics()
	self.Physics = false
	self.vx, self.vy = nil, nil

	-- Remove from global tab to stop receiving physics updates.
	table.Remove(GM.PhysicsItems, self.idx)
	self.idx = nil
end
function PANEL:GetHitbox() return self.hb end

vgui.Register("PItem", PANEL, "DPanel")

local function GetProjectedRange(points, normal)
	local min, max
	for j = 1, #points do
		local x, y = points[j].x, points[j].y
		local nx, ny = normal.x, normal.y
		local proj = x * nx + y * ny

		if not min or (min and proj < min) then min = proj end
		if not max or (max and proj > max) then max = proj end
	end

	return min, max
end

local function GetRangeOverlap(minA, maxA, minB, maxB)
	return math.Min(maxA, maxB) - math.Max(minA, minB)
end

local normals = {}
local collisions = {}
local colHandled = {}
local noCol = {}
local polydata = {}

function GM:ItemPhysicsThink()
	-- SAT collisions

	-- Step through the points of each phys item
	-- Get the normal to each side
	for i = 1, #GM.PhysicsItems do
		local nv = {}

		local points = polydata[i]
		if not points then
			polydata[i] = GM.PhysicsItems[i]:GetHitbox().PolyData
			points = polydata[i]
		end

		for j = 1, #points do
			local p1 = points[j]
			local p2 = points[j == #points and 1 or j + 1]
			nv[j] = {x = p1.y - p2.y, y = p2.x - p1.x}
		end

		normals[i] = nv
	end

	-- Now that we have all the normals, we need the projection of each edge vs that normal.
	for i = 1, normals do
		local nv = normals[i]
		for j = 1, nv do
			local normal = nv[j]

			-- First get the range for the shape we are focusing on...
			local minA, maxA = GetProjectedRange(polydata[i], normal)

			-- Now we need the range for the shape we are considering..
			-- For every shape..

			for o = 1, #GM.PhysicsItems do
				if i == o then continue end -- Skip our current item.

				-- Aready checked and determined no collision!
				if noCol[i] and noCol[i][o] then continue end
				if noCol[o] and noCol[o][i] then continue end

				local minB, maxB = GetProjectedRange(polydata[o], normal)
				local overlap = GetRangeOverlap(minA, maxA, minB, maxB)

				-- No collision!!
				if overlap < 0  then
					noCol[i] = noCol[i] or {}
					noCol[i][o] = true
					if collisions[i] and collisions[i][o] then collisions[i][o] = nil end

					noCol[o] = noCol[o] or {}
					noCol[o][i] = true
					if collisions[o] and collisions[o][i] then collisions[o][i] = nil end

					continue
				end

				-- Select existing collision data, if it exists.
				local colData = collisions[i] and collisions[i][o]
				if not colData then
					colData = collisions[o] and collisions[o][i]
				end

				-- We do this so we know whether to save to tab[o][i] vs tab[i][o]
				local alt
				if colData then alt = true end

				-- Parse new data.
				local newData = {overlap = overlap, normal = normal}

				if not colData then
					-- No collision data exists! Write it.
					colData[i] = colData[i] or {}
					colData[i][o] = newData
				elseif colData and colData.overlap > overlap then
					-- Collision data exists. Override it if our overlap is smaller.
					if alt then
						colData[o][i] = {overlap = overlap, normal = normal}
					else
						colData[i][o] = {overlap = overlap, normal = normal}
					end
				end
			end
		end
	end

	-- We have all our collision data now. Apply it.
	for i = 1, collisions do
		local objA = GM.PhysicsItems[i]
		for j = 1, collisions[i] do
			local objB = GM.PhysicsItems[j]
			local data = collisions[i][j]
			local overlap, normal = data.overlap, data.normal

			-- TODO

		end
	end

	--[[
	for i = 1, #GM.PhysicsItems do
		local min1, max1 = GetProjectedRange(polydata[i], normals[i])

		for j = 1, #GM.PhysicsItems do
			if i == j then continue end

			local min2, max2 = GetProjectedRange(polydata[j], normals[i])
			local overlapping = max1 > min2 and max2 > min1
			if not overlapping then
				-- No collision!
				continue
			else
				-- Maybe collision.
			end
		end
	end
	]]
end