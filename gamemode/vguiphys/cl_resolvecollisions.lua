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
		for physbox, _ in pairs(physboxes) do physbox:SetSupported(false) end

		local collisions = {}
		for hbA, _  in pairs(hitboxes) do
			for hbB, _ in pairs(hitboxes) do
				local collision = gamemode_Call("VGUISAT", hbA, hbB)
				if not collision then
					continue
				end

				table.Insert(collisions, collision)
			end
		end

		for k, collision in pairs(collisions) do
			gamemode_Call("ResolveVGUICollision", collision)
		end

		gamemode_Call("VGUIPhysPassComplete")
	end
end

local function ApplyTranslations(physboxA, physboxB, transA)
	physboxA:AddDesiredTrans(transA)
	physboxB:AddDesiredTrans(-transA)
end

local function ResolveVelocity(physboxA, physboxB, mtv)
	local velA, velB = Rawget(physboxA, "_vel"), Rawget(physboxB, "_vel")

	-- If velocities are zero, do nothing.
	if velA:IsZero() and velB:IsZero() then return end

	-- Get the velocity relative to each other along the normal.
	local rv = velB - velA
	local rnv = rv:Dot(mtv)
	if rnv > 0 then return end -- Objects already moving apart.

	-- Calculate the impulse to apply.
	local bounce = 0.2
	local massA, massB = physboxA.mass or 1, physboxB.mass or 1 -- TODO: implement mass properly.

	local j = rnv * -(1 + bounce)
	j = j / (massA + massB)
	local impulse = mtv * j

	-- Apply the impulse.
	physboxA:AddVel(-impulse * massA)
	physboxB:AddVel(impulse * massB)
end

local function CheckSupported(physboxA, physboxB, mtv)
	-- Check if our collision normal is roughly vertical.
	local _, ny = mtv:Unpack()
	if math_Abs(ny) <= 0.7 then return end

	-- Get our center points for our objects.
	local _, cay = physboxA:GetPointsOrigin():Unpack()
	local _, cby = physboxB:GetPointsOrigin():Unpack()

	-- If one is higher than the other, the other is being supported.
	-- Remember, a more positive y value is actually lower.
	if cay < cby then
		physboxA:SetSupported(true)
	else
		physboxB:SetSupported(true)
	end
end

function GM:ResolveVGUICollision(data)
	--local hbA, hbB = Rawget(data, "hbA"), Rawget(data, "hbB") -- TODO: Might not be needed?
	local physboxA = Rawget(data, "physboxA")
	local physboxB = Rawget(data, "physboxB")
	local overlap = Rawget(data, "overlap")
	local mtv = Rawget(data, "mtv")

	local rootA, rootB = physboxA:GetParent(), physboxB:GetParent()

	-- We desire to apply a translation to resolve the collision.
	-- The root might be invalid if we are a solid wall!

	-- Only do a corrective translation if penetration is large enough.
	if overlap > VGUIPHYS_SLOP then
		local cappedOverlap = math.Min(overlap, 1)
		local translationA = -mtv * cappedOverlap
		ApplyTranslations(physboxA, physboxB, translationA)
	end

	ResolveVelocity(physboxA, physboxB, mtv)

	CheckSupported(physboxA, physboxB, mtv)
end