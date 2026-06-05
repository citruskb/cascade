GM.VGUIPhysPassCount = 0
local gamemode_Call = gamemode.Call
local math_Abs = math.Abs

function GM:VGUIPhysPassComplete() end
function GM:VGUIPhysCollisionsResolved() return self.VGUIPhysPassCount == VGUIPHYS_PASSES end

function GM:ResolveAllVGUICollisions()
	local physboxes = GAMEMODE.VGUIPhysboxes
	local hitboxes = GAMEMODE.VGUIHitboxes
	for i = 1, VGUIPHYS_PASSES do
		GAMEMODE.VGUIPhysPassCount = i

		-- Assume no support. Support toggled in collision resolution if appropriate.
		for vphys, _ in pairs(physboxes) do vphys.supported = false end

		local collisions = {}
		for hbA, _  in pairs(hitboxes) do
			for hbB, _ in pairs(hitboxes) do
				local collision = gamemode_Call("VGUISAT", hbA, hbB)
				if not collision then continue end

				table.Insert(collisions, collision)
			end
		end

		for k, collision in pairs(collisions) do
			print("Collision: ", k)
			gamemode_Call("ResolveVGUICollision", collision)
		end

		gamemode_Call("VGUIPhysPassComplete")
	end
end

local function ApplyTranslations(rootA, vphysA, rootB, vphysB, translationA)
	if IsValid(rootA) and rootA.AddDesiredTranslation then rootA:AddDesiredTranslation(translationA) end
	if IsValid(rootB) and rootB.AddDesiredTranslation then rootB:AddDesiredTranslation(-translationA) end
end
local function ResolveVelocity1(rootA, vphysA, rootB, vphysB, mtv)
	-- Step 1 Determine if objects are moving away from eachother already
	-- If so, do nothing.

	-- Step 2 Find the impluse magnitude

	-- Step 3 Apply the impulse magnitude

	local velA = rootA.GetVel and rootA:GetVel()
	if velA then
		local dot = velA:Dot(mtv)

		if dot > 0 then
			velA:DoSub(mtv * dot)
		end
	end

	local velB = rootB.GetVel and rootB:GetVel()
	if velB then
		local dot = velB:Dot(mtv)

		if dot > 0 then
			velB:DoSub(mtv * dot)
		end
	end
end

local function ResolveVelocity2(rootA, vphysA, rootB, vphysB, mtv)
	local velA = rootA.GetVel and rootA:GetVel() or Vector2()
	local velB = rootB.GetVel and rootB:GetVel() or Vector2()
	if velA:IsZero() and velB:IsZero() then return end

	-- Get the velocity relative to each other along the normal.
	local rv = velB - velA
	local rnv = rv:Dot(mtv)
	if rnv > 0 then return end -- Objects already moving apart.

	-- Calculate the impulse to apply.
	local bounce = 0.2
	local massA, massB = rootA.mass or 1, rootB.mass or 1

	local j = rnv * -(1 + bounce)
	j = j / (massA + massB)
	local impulse = mtv * j

	-- Apply the impulse.
	velA:DoSub(impulse * massA)
	velB:DoAdd(impulse * massB)
end

local function CheckSupported(rootA, vphysA, rootB, vphysB, mtv)
	-- Check if our collision normal is roughly vertical.
	local _, ny = mtv:Unpack()
	if math_Abs(ny) <= 0.7 then return end

	-- Get our center points for our objects.
	local _, cay = vphysA:GetAggregateCenter():Unpack()
	local _, cby = vphysB:GetAggregateCenter():Unpack()

	-- If one is higher than the other, the other is being supported.
	if cay > cby then
		rootA.supported = true
	else
		rootB.supported = true
	end
end

function GM:ResolveVGUICollision(data)
	--local hbA, hbB = Rawget(data, "hbA"), Rawget(data, "hbB") -- TODO: Might not be needed?
	local vphysA = Rawget(data, "vphysA")
	local vphysB = Rawget(data, "vphysB")
	local overlap = Rawget(data, "overlap")
	local mtv = Rawget(data, "mtv")

	local rootA, rootB = vphysA:GetParent(), vphysB:GetParent()

	print("///")
	print("collision!", "(#" .. vphysA.ID .. ")", vphysA, " x ", "(#" .. vphysB.ID .. ")", vphysB)
	print("overlap", overlap)
	print("MTV", mtv)
	print("///")

	-- We desire to apply a translation to resolve the collision.
	-- The root might be invalid if we are a solid wall!

	-- Only do a corrective translation if penetration is large enough.
	if overlap > VGUIPHYS_SLOP then
		local cappedOverlap = math.Min(overlap, 2)
		local translationA = -mtv * cappedOverlap
		ApplyTranslations(rootA, vphysA, rootB, vphysB, translationA)
	end

	--ResolveVelocity1(rootA, vphysA, rootB, vphysB, mtv)
	ResolveVelocity2(rootA, vphysA, rootB, vphysB, mtv)

	CheckSupported(rootA, vphysA, rootB, vphysB, mtv)
end