--[[
The point of this is to cache our Vector2-based panel position and center everytime a panel position or size changes.
Since normally panels don't change their size or position frequently, I figure this is probably OK to tack onto every existing panel.
]]--

local meta = FindMetaTable("Panel")

local function InitVector2(self) self.vpos = Vector2() self.cpos = Vector2() end

local function HandleVector2(self)
	if not self.initv2 then
		InitVector2(self)
		self.initv2 = true
	end

	local x, y = self:GetPos()
	self.vpos:SetUnpacked(x, y)

	local w, h = self:GetSize()
	self.cpos = self.vpos + Vector2(w * 0.5, h * 0.5)
end

local OldInit = meta.Init
function meta:Init()
	OldInit(self)
	HandleVector2(self)
end

local OldSetPos = meta.SetPos
function meta:SetPos(x, y)
	OldSetPos(self, x, y)
	HandleVector2(self)
end

local OldSetSize = meta.SetSize
function meta:SetSize(w, h)
	OldSetSize(self, w, h)
	HandleVector2(self)
end

function meta:GetVPos() return self.vpos end
function meta:GetCPos() return self.cpos end