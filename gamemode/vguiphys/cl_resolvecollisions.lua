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
	local tx, ty = Rawget(translationA, "x"), Rawget(translationA, "y")
	if IsValid(rootA) and rootA.GetDesiredTranslation then
		rootA:AddDesiredTranslation(tx, ty)
	end

	if IsValid(rootB) and rootB.GetDesiredTranslation then
		rootB:AddDesiredTranslation(-tx, -ty)
	end
end

function GM:ResolveVGUICollision(data)
	--local hbA, hbB = Rawget(data, "hbA"), Rawget(data, "hbB") -- TODO: Might not be needed?
	local vphysA = Rawget(data, "vphysA")
	local vphysB = Rawget(data, "vphysB")
	local overlap = Rawget(data, "overlap")
	local mtv = Rawget(data, "mtv")

	local rootA, rootB = vphysA:GetParent(), vphysB:GetParent()

	-- We desire to apply a translation to resolve the collision.
	-- The root might be invalid if we are a solid wall!

	-- Only do a corrective translation if penetration is large enough.
	if overlap <= VGUIPHYS_SLOP then return end
	local cappedOverlap = math.Min(overlap, 1)
	local translationA = {x = -mtv.x * cappedOverlap, y = -mtv.y * cappedOverlap}
	ApplyTranslations(rootA, vphysA, rootB, vphysB, translationA)
end