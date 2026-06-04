GM.VGUIPhysPassCount = 0
local gamemode_Call = gamemode.Call

function GM:VGUIPhysPassComplete() end
function GM:VGUIPhysCollisionsResolved() return self.VGUIPhysPassCount == VGUIPHYS_PASSES end

function GM:ResolveAllVGUICollisions()
	local hitboxes = GAMEMODE.VGUIHitboxes
	for i = 1, VGUIPHYS_PASSES do
		GAMEMODE.VGUIPhysPassCount = i

		for hbA, _  in pairs(hitboxes) do
			for hbB, _ in pairs(hitboxes) do
				local collision = gamemode_Call("VGUISAT", hbA, hbB)
				if not collision then continue end

				gamemode_Call("ResolveVGUICollision", collision)
			end
		end

		gamemode_Call("VGUIPhysPassComplete")
	end
end

local function ApplyTranslations(rootA, vphysA, rootB, vphysB, translationA)
	if IsValid(rootA) and rootA.GetDesiredTranslation then rootA:AddDesiredTranslation(translationA) end
	if IsValid(rootB) and rootB.GetDesiredTranslation then rootB:AddDesiredTranslation(-translationA) end
end
local function ResolveVelocity(rootA, vphysA, rootB, vphysB, mtv)
	local velA = rootA.GetVel and rootA:GetVel()
	if velA then
		print("velA")
		print(velA)
		local dot = velA:Dot(mtv)

		print("dot", dot)
		if dot > 0 then
			velA:DoSub(mtv * dot)
		end
	end

	local velB = rootB.GetVel and rootB:GetVel()
	if velB then
		print("velB")
		print(velB)
		local dot = velB:Dot(mtv)

		print("dot", dot)
		if dot > 0 then
			velB:DoSub(mtv * dot)
		end
	end
end

function GM:ResolveVGUICollision(data)
	print("resolving collision!")
	--local hbA, hbB = Rawget(data, "hbA"), Rawget(data, "hbB") -- TODO: Might not be needed?
	local vphysA = Rawget(data, "vphysA")
	local vphysB = Rawget(data, "vphysB")
	local overlap = Rawget(data, "overlap")
	local mtv = Rawget(data, "mtv")

	local rootA, rootB = vphysA:GetParent(), vphysB:GetParent()

	-- We desire to apply a translation to resolve the collision.
	-- The root might be invalid if we are a solid wall!

	-- Only do a corrective translation if penetration is large enough.
	if overlap > VGUIPHYS_SLOP then 
		local cappedOverlap = math.Min(overlap, 1)
		local translationA = -mtv * cappedOverlap
		ApplyTranslations(rootA, vphysA, rootB, vphysB, translationA)
	end

	ResolveVelocity(rootA, vphysA, rootB, vphysB, mtv)
end