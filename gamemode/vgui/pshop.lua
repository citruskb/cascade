local function DockCenter(self, parent)
	local dw, dh = (parent:GetWide() / 2) - (self:GetWide() / 2), (parent:GetTall() / 2) - (self:GetTall() / 2)
	self:DockMargin(dw, dh, dw, dh)
	self:Dock(FILL)
end

PANEL = {}

function PANEL:Init()
	--local screenscale = BetterScreenScale()
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
	grid:SetBackgroundColor(Color(255, 0, 0, 50))
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
	model:SetBackgroundColor(Color(0, 0, 255, 50))
	model:Dock(LEFT)
	lab = EasyLabel(model, "Player Model", "SFontLarger")
	DockCenter(lab, model)
	--


	-- Stats & options
	local stats = vgui.Create("DPanel", botLeft)
	stats:SetSize(w * 0.2, h * 0.4)
	stats:SetBackgroundColor(Color(0, 255, 0, 50))
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

	local floorcontainer = vgui.Create("DPanel", middle)
	floorcontainer:SetSize(w * 0.25, h * 0.1)
	floorcontainer:SetBackgroundColor(Color(0, 0, 0, 0))
	floorcontainer:Dock(TOP)

	local invfloor = vgui.Create("DPhysbox", floorcontainer)
	invfloor:SetSize(w * 0.25, h * 0.1)
	invfloor:Dock(FILL)
	invfloor:AddHitbox(w * 0.25, h * 0.1)
	lab = EasyLabel(invfloor, "Floor (collisions)", "SFontLarger")
	DockCenter(lab, invfloor)
	--



	local right = vgui.Create("DPanel", self)
	right:SetSize(w * 0.35, 0)
	right:SetBackgroundColor(Color(0, 0, 0, 0))
	right:Dock(LEFT)


	-- Shop area
	local shop = vgui.Create("DPanel", right)
	shop:SetSize(0, h * 0.6)
	shop:SetBackgroundColor(Color(255, 0, 255, 50))
	shop:Dock(TOP)
	lab = EasyLabel(shop, "Shop", "SFontLarger")
	DockCenter(lab, right)
	--

	-- Shopkeep
	local shopkeep = vgui.Create("DPanel", right)
	shopkeep:SetSize(0, h * 0.4)
	shopkeep:SetBackgroundColor(Color(0, 255, 255, 50))
	shopkeep:Dock(TOP)
	lab = EasyLabel(shopkeep, "Shopkeep", "SFontLarger")
	DockCenter(lab, right)
	--

	-- Test items
	local item = vgui.Create("PItem", self)
	local size = 50
	item:SetSize(size, size)
	item:SetBackgroundColor(Color(255, 255, 0, 255))
	item:SetPos(w * 0.6, h * 0.4)
	item.physbox:AddCustomHitbox({
		{x = 10, y = 10},
		{x = size - 10, y = 10},
		{x = size - 10, y = size - 10},
		{x = 10, y = size - 10},
	})

	item:EnablePhysics()
	--item:SetVel(0, -ITEM_TERMINAL_VELOCITY)
end

function PANEL:Paint()
	Derma_DrawBackgroundBlur(self, self.Created)
end

vgui.Register("PShop", PANEL, "DPanel")

function GM:ShowHelp(pl)
	if IsValid(self.pShop) then
		self.pShop:Remove()
		return
	end

	self.pShop = vgui.Create("PShop")
end