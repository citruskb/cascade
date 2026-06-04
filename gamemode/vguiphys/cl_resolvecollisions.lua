local gamemode_Call = gamemode.Call

function GM:VGUIPhysPassComplete() end

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

		gamemode_Call("VGUIPhysPassComplete")
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

	if IsValid(rootA) then
		if rootA.GetDesiredTranslation then
			local TranslateA = {x = -mtv.x * overlap / 2, y = -mtv.y * overlap / 2}
			rootA:AddDesiredTranslation(Rawget(TranslateA, "x"), Rawget(TranslateA, "y"))
		end


		if rootA.GetVel then
			local mtvy = Rawget(mtv, "y")
			local velx, vely = rootA:GetVel()
			if mtvy > 0.9 and vely >= 0 then
				rootA:SetVel(velx, 0)
				vphysA.resting = true
			else
				vphysA.resting = false
			end
		end
	end

	if IsValid(rootB) and rootB.GetDesiredTranslation then
		if rootB.GetDesiredTranslation then
			local TranslateB = {x = mtv.x * overlap / 2, y = mtv.y * overlap / 2}
			rootB:AddDesiredTranslation(Rawget(TranslateB, "x"), Rawget(TranslateB, "y"))
		end

		if rootB.GetVel then
			local mtvy = Rawget(mtv, "y")
			local velx, vely = rootB:GetVel()
			if mtvy < -0.9 and vely >= 0 then
				rootB:SetVel(velx, 0)
				vphysB.resting = true
			else
				vphysB.resting = false
			end
		end
	end
end