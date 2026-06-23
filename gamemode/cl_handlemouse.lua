if not handleMouseLoaded then
	GM.LeftMouseBeingHeld = false
	GM.RightMouseBeingHeld = false
	GM.CachedMousePos = Vector2(input.GetCursorPos())
	GM.CachedMouseVelocity = Vector2()
	handleMouseLoaded = true
end

ITEM_PICKUP_DIST_SQR = 4096 -- 64^2

function GM:GetItemPickupRangeSqr()
	return ITEM_PICKUP_DIST_SQR * ScreenScale() * ScreenScale()
end

function LookForClosestPickup()
	local mousePos = GAMEMODE.CachedMousePos

	local closestDist = math.HUGE
	local rangeLimit = gamemode.Call("GetItemPickupRangeSqr")
	local closest
	for hitbox, _ in pairs(PhysObj2D.hitboxes) do
		local physbox = hitbox.physbox
		if not physbox:MouseCanGrab() then continue end

		local pointsObj = hitbox:GetHBScreenPointsObj()
		local center = pointsObj:GetCenter()
		local distSqr = mousePos:DistanceSqr(center)

		if distSqr > rangeLimit then continue end
		if distSqr >= closestDist then continue end

		closest = physbox
		closestDist = distSqr
	end

	return closest
end

local numSteps = 6
local positions = {}
local function EvaluateAverageMouseVelocity()
	if not GAMEMODE.LeftMouseBeingHeld then positions = {} return end

	table.Insert(positions, 1, GAMEMODE.CachedMousePos)

	if #positions > numSteps then positions[#positions] = nil end
	if #positions == 1 then return Vector2() end

	local count = 1
	local sumX, sumY = 0, 0
	for i = 1, #positions do
		if i == 1 then continue end
		local x1, y1 = positions[i - 1]:Unpack()
		local x2, y2 = positions[i]:Unpack()
		sumX = sumX + x1 - x2
		sumY = sumY + y1 - y2
		count = i
	end

	local vec = Vector2(sumX / count / 0.033, sumY / count / 0.033)
	GAMEMODE.CachedMouseVelocity = vec
end

function GM:HandleMousePress()
	local newState = input.IsMouseDown(MOUSE_FIRST)
	local oldState = self.LeftMouseBeingHeld
	self.LeftMouseBeingHeld = newState

	if self.LeftMouseBeingHeld then
		self.CachedMousePos = Vector2(input.GetCursorPos())
	end
	EvaluateAverageMouseVelocity()

	if oldState ~= newState then
		local pressed = self.LeftMouseBeingHeld
		if pressed then
			gamemode.Call("LeftMouseClick")
		else
			gamemode.Call("LeftMouseRelease")
		end
	end

	newState = input.IsMouseDown(MOUSE_RIGHT)
	oldState = self.RightMouseBeingHeld
	self.RightMouseBeingHeld = newState

	if oldState ~= newState then
		local pressed = self.RightMouseBeingHeld
		if pressed then
			gamemode.Call("RightMouseClick")
		else
			gamemode.Call("RightMouseRelease")
		end
	end
end

function GM:LeftMouseClick()
	-- Assume we only care our mouse is pressed if it's free and moving around.
	if not vgui.CursorVisible() then return end

	self.HeldItem = LookForClosestPickup()
	if not self.HeldItem then return end

	local insideBounds = self.HeldItem:IsInsideInventoryBounds()
	self.HeldItem:MousePickup(insideBounds)
	gamemode.Call("InventoryItemPickedUp", self.HeldItem.parent, insideBounds)
end

function GM:LeftMouseRelease()
	if not self.HeldItem then return end

	local insideBounds = self.HeldItem:IsInsideInventoryBounds()
	self.HeldItem:MouseDrop(insideBounds)
	gamemode.Call("InventoryItemDropped", self.HeldItem.parent, insideBounds)

	self.HeldItem = nil
end

function GM:RightMouseClick()
	if not self.HeldItem then return end
	self.HeldItem:Rotate90CW()
end

function GM:RightMouseRelease()
end

function GM:InventoryItemDropped(obj, isInInventoryBounds)
	-- TODO drop effect?
end
function GM:InventoryItemPickedUp(obj, isInInventoryBounds)
	-- TODO pickup effect?
end