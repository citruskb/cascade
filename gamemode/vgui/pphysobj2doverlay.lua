--[[
	The point of this is a single screen-wide panel to handle drawing anything needed for our 2d physics objects.
	Be it the objects themselves, effects, whatever.
	We don't do this on the shop or battle screens directly because we may want to be hiding those panels while displaying this one. 
]]--

PANEL = {}

function PANEL:Init()
	self.SetZPos(GM_ZPOS_POVERLAY)
	self:SetPos(0, 0)

	local w, h = ScrW(), ScrH()
	self:SetSize(w, h)
	self:Center()

	self:SetVisible(true)
end

function PANEL:Think() end

function PANEL:Paint()
	-- TODO: Paint all the 2d phys objs using clientside models

end

vgui.Register("PPhysObj2DOverlay", PANEL, "DPanel")