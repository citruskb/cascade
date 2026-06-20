local function DockCenter(self, parent)
	local dw, dh = (parent:GetWide() / 2) - (self:GetWide() / 2), (parent:GetTall() / 2) - (self:GetTall() / 2)
	self:DockMargin(dw, dh, dw, dh)
	self:Dock(FILL)
end

PANEL = {}

function PANEL:Init()
	self:SetZPos(GM_ZPOS_PSHOP)
	local w, h = ScrW(), ScrH()

	self:SetSize(w, h)
	self:Center()
	self.Create = SysTime()

	-- Top left: inventory grid
	-- Bottom left: stats
	-- Center: storage
	-- Center top: Start button
	-- Right: Shop ui

	local left = vgui.Create("DPanel", self)
	left:SetSize(w * 0.4, h)
	left:SetBackgroundColor(Color(0, 0, 0, 0))
	left:Dock(LEFT)


	-- Inventory
	local grid = vgui.Create("DPanel", left)
	grid:SetSize(w * 0.4, h * 0.6)
	grid:SetBackgroundColor(Color(255, 0, 0, 10))
	grid:Dock(TOP)
	local lab = EasyLabel(grid, "Grid Inventory", "SFontLarger")
	DockCenter(lab, grid)
	--


	local botLeft = vgui.Create("DPanel", left)
	botLeft:SetSize(w * 0.2, h * 0.4)
	botLeft:SetBackgroundColor(Color(0, 0, 0, 0))
	botLeft:Dock(TOP)


	-- Playermodel
	local model = vgui.Create("DPanel", botLeft)
	model:SetSize(w * 0.2, h * 0.4)
	model:SetBackgroundColor(Color(0, 0, 255, 10))
	model:Dock(LEFT)
	lab = EasyLabel(model, "Player Model", "SFontLarger")
	DockCenter(lab, model)
	--


	-- Stats & options
	local stats = vgui.Create("DPanel", botLeft)
	stats:SetSize(w * 0.2, h * 0.4)
	stats:SetBackgroundColor(Color(0, 255, 0, 10))
	stats:Dock(LEFT)
	lab = EasyLabel(stats, "Stats", "SFontLarger")
	DockCenter(lab, stats)
	--


	-- Inventory
	local middle = vgui.Create("DPanel", self)
	middle:SetSize(w * 0.25, h)
	middle:SetBackgroundColor(Color(0, 0, 0, 0))
	middle:Dock(LEFT)

	local inventory = vgui.Create("DPanel", middle)
	inventory:SetSize(w * 0.25, h * 0.9)
	inventory:SetBackgroundColor(Color(255, 255, 0, 0)) --
	inventory:Dock(TOP)
	lab = EasyLabel(inventory, "Storage Inventory", "SFontLarger")
	DockCenter(lab, inventory)

	local floorcontainer = vgui.Create("DPanel", self)
	floorcontainer:SetSize(w * 0.25, h * 0.1)
	floorcontainer:SetPos(w * 0.4, h * 0.9)
	floorcontainer:SetBackgroundColor(Color(0, 67, 167, GAMEMODE.Debug and 0 or 200))

	--position, rotation, itemDataID, velocity, angularVelocity, isStatic, notScreenScaled
	local function MakeWall(screenOrigin, fW, fH)

		local actualOrigin = screenOrigin + Vector2(fW * 0.5, fH * 0.5)
		local pointsObj = Points({
				Vector2(0, 0),
				Vector2(fW, 0),
				Vector2(fW, fH),
				Vector2(0, fH),
			})

		gamemode.Call("NewPhysicsObject2D",
			actualOrigin,
			0,
			pointsObj,
			nil, nil, true, true)
	end

	MakeWall(Vector2(w * 0.4, h * 0.9), w * 0.25, h * 0.1)			-- Floor collision
	MakeWall(Vector2(w * 0.35, -h), w * 0.05, 2 * h)				-- Left side wall
	MakeWall(Vector2(w * 0.65, -h), w * 0.05, 2 * h)				-- Right side wall
	MakeWall(Vector2(w * 0.4, -h + 0.1 * h), w * 0.05, h * 0.1)		-- Cap, out of view. just in case.
	--



	local right = vgui.Create("DPanel", self)
	right:SetSize(w * 0.35, 0)
	right:SetBackgroundColor(Color(0, 0, 0, 0))
	right:Dock(LEFT)


	-- Shop area
	local shop = vgui.Create("DPanel", right)
	shop:SetSize(0, h * 0.6)
	shop:SetBackgroundColor(Color(255, 0, 255, 10))
	shop:Dock(TOP)
	lab = EasyLabel(shop, "Shop", "SFontLarger")
	DockCenter(lab, right)
	--

	-- Shopkeep
	local shopkeep = vgui.Create("DPanel", right)
	shopkeep:SetSize(0, h * 0.4)
	shopkeep:SetBackgroundColor(Color(0, 255, 255, 10))
	shopkeep:Dock(TOP)
	lab = EasyLabel(shopkeep, "Shopkeep", "SFontLarger")
	DockCenter(lab, right)
	--



	-- Test items
	local function MakeBox(origin, vel, rad)
		--GM:NewPhysicsObject2D(position, rotation, itemDataID, velocity, angularVelocity, isStatic)
		local obj = gamemode.Call("NewPhysicsObject2D", origin, rad, "wooden_crate", vel)
		obj:EnablePhysics()
	end

	local function OneBox() MakeBox(Vector2(0.5 * w, 0.5 * h)) end

	local function TossBoxes(num)
		num = math.Clamp(math.Floor(num), 1, 64)
		for i = 1, num do
			MakeBox(
			Vector2(
				w * 0.5 + math.Random(-40 * 4, 40 * 4),
				h * 0.5 + math.Random(-40 * 4, 40 * 4)
			)
			,Vector2(
				math.Rand(-VGUIPHYS_TERMINAL_VELOCITY, VGUIPHYS_TERMINAL_VELOCITY),
				-math.Rand(0, VGUIPHYS_TERMINAL_VELOCITY)
			))
		end
	end

	local function StackOfBoxes(high)
		high = math.Clamp(math.Floor(high), 1, 5)
		for i = 1, high do
			MakeBox(Vector2(w * 0.5, 0.3 + h * (0.1 * i)))
		end
	end

	local function StackOfOffsetTossedBoxes(high, offset)
		high = math.Clamp(math.Floor(high), 1, 5)
		for i = 1, high do
			MakeBox(
				Vector2(w * 0.5 + math.Random(-offset, offset), 0.3 + h * (0.1 * i)),
				Vector2(0, -math.Rand(0, VGUIPHYS_TERMINAL_VELOCITY))
			)
		end
	end

	-- /// THE TEST ZONE /// --
	OneBox()								-- Spawn a regular box.
	--StackOfBoxes(5)						-- Plain stacked boxes.
	--StackOfOffsetTossedBoxes(5, 30)		-- Offset stacked boxes.
	--TossBoxes(32)							-- Toss a load of boxes everywhere.

end

function PANEL:Paint()
end

vgui.Register("PShop", PANEL, "DPanel")

function GM:ShowHelp(pl)
	if IsValid(self.pShop) then
		self.pShop:Remove()

		for k, v in pairs(GAMEMODE.PhysicsObjects2D) do
			v:Remove()
		end

		if IsValid(self.pPhysObj2DOverlay) then self.pPhysObj2DOverlay:SetVisible(false) end

		return
	end

	if IsValid(self.pPhysObj2DOverlay) then
		self.pPhysObj2DOverlay:SetVisible(true)
	else
		self.pPhysObj2DOverlay = vgui.Create("PPhysObj2DOverlay")
	end

	self.pShop = vgui.Create("PShop")
end