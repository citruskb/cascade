
local function CheckCollision(bodyA, bodyB)
	if bodyA.isStatic and bodyB.isStatic then return {} end
	if not bodyA:GetAABB():Overlaps(bodyB:GetAABB()) then return {} end

	for idxA = 1, #bodyA.hitboxes do
		local hitboxA = bodyA.hitboxes[idxA]

		for idxB = 1, #bodyB.hitboxes do
			local hitboxB = bodyB.hitboxes[idxB]

			local collision = gamemode.Call("VGUISAT", hitboxA, hitboxB)
			if not collision then continue end

			local contactPoints = gamemode.Call("VGUIGetContactPoints", bodyA, bodyB, hitboxA, hitboxB, collision.normal)

			-- Create contact constraints
			for ptIdx = 0, #contactPoints.points do
				local screenP = contactPoints.points[ptIdx]
				local fID = contactPoints.fIDs[ptIdx]

				-- To to re-use existing contact
				local existingContact = GAMEMODE.VGUICollisionConstraints[fID]
				if existingContact then
					existingContact.isReused = true
					existingContact:SetCollisionData(screenP, collision.normal, collision.penetration)
				else
					-- But if not found, make a new one!
					VGUICollisionConstraint:Create(bodyA, bodyB, screenP, collision.normal, collision.penetration, fID)
				end

			end

		end

	end

end


function GM:VGUIPhysDetectCollisions()
	local objects = {}
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		table.Insert(objects, physbox)
	end

	for i = 1, #objects do
		for j = i + 1, #objects do
			CheckCollision(objects[i], objects[j])
		end
	end
end