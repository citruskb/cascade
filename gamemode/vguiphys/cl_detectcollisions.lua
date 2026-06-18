
local function CheckCollision(bodyA, bodyB)
	if bodyA.isStatic and bodyB.isStatic then return {} end
	if not bodyA:GetAABB():Overlaps(bodyB:GetAABB()) then return {} end

	local constr = {}
	for idxA = 1, #bodyA.hitboxes do
		local hitboxA = bodyA.hitboxes[idxA]

		for idxB = 1, #bodyB.hitboxes do
			local hitboxB = bodyB.hitboxes[idxB]

			local collision = gamemode.Call("VGUISAT", hitboxA, hitboxB)
			if not collision then continue end

			hitboxA = collision.hbA
			hitboxB = collision.hbB
			bodyA = hitboxA.physbox
			bodyB = hitboxB.physbox

			local contactPoints = gamemode.Call("ClipPolyToPoly", bodyA, hitboxA, bodyB, hitboxB, collision)

			-- Create contact constraints
			for ptIdx = 1, #contactPoints.points do
				local screenP = contactPoints.points[ptIdx]
				local fID = contactPoints.fIDs[ptIdx]

				-- Try to re-use existing contact
				local existingContact = GAMEMODE.VGUICollisionConstraints[fID]
				if existingContact then
					existingContact.reusedCount = existingContact.reusedCount + 1
					existingContact:SetCollisionData(screenP, collision.normal, collision.penetration)
					bodyA.persistentContacts[fID] = existingContact
					bodyB.persistentContacts[fID] = existingContact

					table.Insert(constr, fID, existingContact)
				else
					-- But if not found, make a new one!
					local newC = VGUICollisionConstraint:Create(bodyA, bodyB, screenP, collision.normal, collision.penetration, fID)
					table.Insert(constr, fID, newC)
				end

			end

		end

	end

	return constr

end


function GM:VGUIPhysDetectCollisions()
	local objects = {}
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		table.Insert(objects, physbox)
	end

	local rebuildCollisionConstraints = {}
	for i = 1, #objects do
		for j = i + 1, #objects do
			local tab = CheckCollision(objects[i], objects[j])
			for fID, const in pairs(tab) do
				rebuildCollisionConstraints[fID] = const
			end
		end
	end

	self.VGUICollisionConstraints = rebuildCollisionConstraints
end