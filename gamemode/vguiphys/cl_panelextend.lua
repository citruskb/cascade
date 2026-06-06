local meta = FindMetaTable("Panel")

local function InitVector2(self) self.vpos = Vector2() self.svpos = Vector2() self.cpos = Vector2() self.scpos = Vector2() end

local function UpdateVector2(self)
	-- Top left corner. These will always be whole numbers.		
	self.vpos:SetUnpacked(self:GetPos())

	-- Top left corner, relative to the entire screen.
	self.svpos:SetUnpacked(self:LocalToScreen(self.vpos:Unpack()))

	local w, h = self:GetSize()

	-- Center of the panel. Remember, postive x is right, positive y is down.
	self.cpos = self.vpos + Vector2(math.Round(w / 2, 0), math.Round(h / 2, 0))

	-- Center of the panel relative to the entire screen.
	self.scpos:SetUnpacked(self:LocalToScreen(self.cpos:Unpack()))
end

local OldInit = meta.Init
function meta:Init()
	InitVector2(self)
	UpdateVector2(self)
	OldInit(self)
end

local OldSetPos = meta.SetPos
function meta:SetPos(x, y)
	OldSetPos(self, x, y)
	UpdateVector2(self)
end

local OldSetSize = meta.SetSize
function meta:SetSize(w, h)
	OldSetSize(self, w, h)
	UpdateVector2(self)
end

function meta:GetVPos() return self.vpos end
function meta:GetSVPos() return self.svpos end
function meta:GetCPos() return self.cpos end
function meta:GetSCPos() return self.scpos end