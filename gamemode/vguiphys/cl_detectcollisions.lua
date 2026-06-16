

local AABB

local function CheckCollision(bodyA, bodyB)
	if bodyA.isStatic and bodyB.isStatic then return {} end
	if not bodyA:GetAABB():Overlaps(bodyB:GetAABB()) then return {} end

	local contactConstraints = {}
	for idxA = 1, #bodyA.hitboxes do
		local hitboxA = bodyA.hitboxes[idxA]

		for idxB = 1, #bodyB.hitboxes do
			local hitboxB = bodyB.hitboxes[idxB]

			local collision = gamemode.Call("VGUISAT", hitboxA, hitboxB)
			if not collision then continue end

			local clippedPoints = gamemode.Call("VGUIGetContactPoints", bodyA, bodyB, hitboxA, hitboxB, collision.normal)
		end

	end

end



function GM:VGUIPhysDetectCollisions()
	local objects = {}
	for physbox, _ in pairs(self.VGUIPhysboxes) do
		table.Insert(objects, physbox)
	end

	local results = {}
	for i = 1, #objects do
		for j = i + 1, #objects do
			local bodyA = objects[i]
			local bodyB = objects[j]
			table.Add(results, CheckCollision(bodyA, bodyB))
		end
	end


end