PANEL = {}

function PANEL:Init()
	self.lastRefresh = CurTime()

	self.frame = vgui.Create("DFrame", self)
	self.title = vgui.Create("DLabel", self.frame)
	self.richText = vgui.Create("RichText", self.frame)

	self:InvalidateLayout()
end

function PANEL:SetPlayer(pl)
	if pl == MySelf then
		self.pl = pl
		self.nick = pl:Nick()
	else
		-- TODO
	end

	self:InvalidateLayout()
end

function PANEL:Think()
	-- Refresh periodically.
	if not self.pl then return end

	local ct = CurTime()
	if self.lastRefresh + 2 < ct then return end

	self:SetPlayer(self.pl)
	self.lastRefresh = ct
end

function PANEL:PerformLayout()
	local cellSize = gamemode.Call("GetInventoryGridSize")
	local w, h = ScrW(), ScrH()
	self:SetPos(cellSize * 4, h - cellSize * 4.5)
	self:SetSize(cellSize * 5, cellSize * 4.5)

	self.frame:SetTitle("")
	self.frame:SetSize(self:GetSize())
	self.frame:ShowCloseButton(false)
	self.frame:DockPadding(5, 5, 5, 5)

	self.title:SetFont("FontPlayerStatsName")
	self.title:SetText(self.nick)
	self.title:SizeToContents()
	self.title:Dock(TOP)

	local rt = self.richText
	rt:Dock(FILL)
	rt:SetVerticalScrollbarEnabled(false)
	rt:SetSize(self:GetSize())
	rt:SetText("")

	-- Gold.
	rt:InsertColorChange(255, 255, 255, 255)
	rt:AppendText("Money:\t")
	rt:InsertColorChange(255, 215, 0, 255)
	rt:AppendText("$11\n")

	-- Health.
	rt:InsertColorChange(255, 255, 255, 255)
	rt:AppendText("Health:\t")
	rt:InsertColorChange(20, 255, 20, 255)
	rt:AppendText("25\n")

	-- Stamina.
	rt:InsertColorChange(255, 255, 255, 255)
	rt:AppendText("Stamina:\t")
	rt:InsertColorChange(255, 165, 0, 255)
	rt:AppendText("5\n")

	rt:AppendText("\n\n\n")

	-- Rounds
	rt:InsertColorChange(255, 255, 255, 255)
	rt:AppendText("Round:\t1\n")

	-- Wins
	rt:InsertColorChange(255, 255, 255, 255)
	rt:AppendText("Wins:\t0\n")

	-- Lives
	rt:InsertColorChange(255, 255, 255, 255)
	rt:AppendText("Lives:\t5\n")

	rt.PerformLayout = function(pan)
		if pan:GetFont() ~= "FontPlayerStats" then pan:SetFontInternal("FontPlayerStats") end
	end
end

local colBackground = Color(22, 22, 22, 120)
function PANEL:Paint()
	local w, h = self:GetSize()

	surface.SetDrawColor(colBackground)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("DPlayerStats", PANEL, "DPanel")

