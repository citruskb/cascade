local gamemode_Call = gamemode.Call

function GM:ResolveAllVGUICollisions()
	local hitboxes = GAMEMODE.VGUIHitboxes
	for i = 1, VGUIPHYS_PASSES do
		for hbA, _  in pairs(hitboxes) do
			for hbB, _ in pairs(hitboxes) do
				local collision = gamemode_Call("VGUISAT", hbA, hbB)
				if not collision then continue end

				gamemode_Call("ResolveVGUICollision", collision)
			end
		end
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
	if IsValid(rootA) and rootA.AddDesiredPos then
		local TranslateA = {x = -mtv.x * overlap / 2, y = -mtv.y * overlap / 2}
		rootA:GetDesiredTranslation(Rawget(TranslateA, "x"), Rawget(TranslateA, "y"))
	end

	if IsValid(rootB) and rootB.AddDesiredPos then
		local TranslateB = {x = mtv.x * overlap / 2, y = mtv.y * overlap / 2}
		rootB:GetDesiredTranslation(Rawget(TranslateB, "x"), Rawget(TranslateB, "y"))
	end

	-- Detect resting collisions.
	-- Hopefully stop resting jittering on the ground.
	local mtvy = Rawget(mtv, "y")
	local velx, vely = rootA:GetVel()
	if mtvy > 0.9 and vely < 0 then
		rootA:SetVel(velx, 0)
	end
end