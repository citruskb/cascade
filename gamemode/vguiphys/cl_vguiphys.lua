print("LUA REFRESHED")

-- Handle Lua refresh.
if not vguiPhysLoaded then
	GM.VGUIPhysboxes = {}
	GM.VGUIColEvents = {}
	vguiPhysLoaded = true
end

ITEM_GRAVITY = 0.008
ITEM_TERMINAL_VELOCITY = 1.4

local function GetFaceNormals(physbox)
	local points = physbox:AggregatePolyData()
	local normals = {}
	for i = 1, #points do
		local p1 = points[i]
		local p2 = points[i == #points and 1 or i + 1]
		normals[i] = {x = p1.y - p2.y, y = p2.x - p1.x}
	end

	return normals
end

local function GetProjRange(physbox, normal)
	local points = physbox:AggregatePolyData()
	local min, max

	for i = 1, #points do
		local x, y = points[i].x, points[i].y
		local nx, ny = normal.x, normal.y
		local proj = x * nx + y * ny

		if not min or (min and proj < min) then min = proj end
		if not max or (max and proj > max) then max = proj end
	end

	return {min = min, max = max}
end

local function GetRangeOverlap(rangeA, rangeB)
	return math.Min(rangeA.max, rangeB.max) - math.Max(rangeA.min, rangeB.min)
end

local checkedCols = {}
local function AlreadyCheckedCols(physboxA, physboxB)
	return checkedCols[physboxA] and checkedCols[physboxA][physboxB] or checkedCols[physboxB] and checkedCols[physboxB][physboxA]
end

local cachedFaceNormals = {}
local cachedSelfProjections = {}
local overlapData = {}
local function ResetVGUIPhysVars()
	checkedCols = {}
	cachedFaceNormals = {}
	cachedSelfProjections = {}
	overlapData = {}
end


function GM:VGUIPhysThink()
	ResetVGUIPhysVars()

	-- SAT collisions.
	-- We need to tell if any of our physboxes are colliding.
	-- VGUIPhysboxes are collections of hitboxes tied to particular objects.
	-- While looping through all physboxes we go ahead and apply gravity too.
	for _, vphys in pairs(self.VGUIPhysboxes) do
		if not IsValid(vphys) then continue end

		-- Add our gravity up to our terminal velocity.
		local _, vy = vphys:GetVel()
		if vy < ITEM_TERMINAL_VELOCITY then
			vphys:AddVel(0, ITEM_GRAVITY)
		end

		-- SAT collisions involves stepping through each table of points ("shape") associated with a hitbox.
		-- We need the normal of each side of each shape.
		-- Then we need to project each shape against each normal.
		-- If projections of each normal of both shapes overlap, then there is a collision event.
		-- The shortest normal of all of these is the direction we should move objects to separate them.
		-- We need to know which object this normal came from so that we know which direction to apply forces.

		-- Get our face normals for each. We need to do this one way or another.
		local normals = GetFaceNormals(vphys)
		cachedFaceNormals[vphys] = normals

		-- We should go ahead and cache our projections against our own normals too.
		local tab = {}
		for i = 1, #normals do
			tab[i] = GetProjRange(vphys, normals[i])
		end
		cachedSelfProjections[vphys] = tab
	end


	-- Next we step through each collection of normals.
	for vphysA, normals in pairs(cachedFaceNormals) do

		local selfProjections = cachedSelfProjections[vphysA]

		-- Step through each normal.
		for i = 1, #normals do

			-- Load up our cached information & initialize vars.
			local fn = normals[i]
			local projRangeA = selfProjections[i]
			local smallestOverlap

			-- Now we step through every other object and their projections against our fn.
			for _, vphysB in pairs(self.VGUIPhysboxes) do

				-- Clearly the same physbox shouldn't collide with itself.
				if vphysA == vphysB then continue end

				-- We've already determined that these two aren't overlapping.
				if AlreadyCheckedCols(vphysA, vphysB) then continue end

				-- Check if there is range overlap.
				local projRangeB = GetProjRange(vphysB, fn)
				local overlap = GetRangeOverlap(projRangeA, projRangeB)

				-- Abort!! No overlap means no collision.
				if overlap < 0 then
					checkedCols[vphysA] = checkedCols[vphysA] or {}
					checkedCols[vphysA][vphysB] = true

					if overlapData[vphysA] and overlapData[vphysA][vphysB] then
						overlapData[vphysA][vphysB] = nil
					end
					break
				end

				-- We save the smallest overlap and normal.
				if not smallestOverlap or (smallestOverlap and overlap < smallestOverlap) then
					smallestOverlap = overlap

					overlapData[vphysA] = overlapData[vphysA] or {}
					overlapData[vphysA][vphysB] = {overlap = smallestOverlap, normal = fn}
				end

			end

		end

	end


	-- Put all the pieces together to determine if a collision happened
	for vphysA, others in pairs(overlapData) do

		for vphysB, overlapDataA in pairs(others) do

			-- There has to be an analog, else there was only overlap for one of the objects.
			local overlapDataB = overlapData[vphysB] and overlapData[vphysB][vphysA]
			if not overlapDataB then continue end

			local event
			if overlapDataA.overlap < overlapDataB.overlap then
				event = VGUIColEvent:Create(vphysA, vphysB, overlapDataA.overlap, overlapDataA.normal)
			else
				event = VGUIColEvent:Create(vphysB, vphysA, overlapDataB.overlap, overlapDataB.normal)
			end

			table.Insert(collisionEvents, event)
		end

	end


	-- Finally, fire off all the collision events.
	-- Firing events also clears it from the table.
	local tab = table.Copy(GAMEMODE.VGUIColEvents)
	for _, event in pairs(tab) do event() end

end