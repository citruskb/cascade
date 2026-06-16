--[[

This looks like it was coded by an alien. I know. Sorry.
Doing everything possible to save frames with localization and sidestepping indexing overhead.
Some funcs here are potentially called thousands of times per second due to moving physics panels in the UI.

The point of this is to cache our panel position, screen-based position, center, and screen-based center everytime a panel position or size changes.
Since normally panels don't change their size or position frequently, I figure this is probably OK to tack onto every existing panel.

]]--

local meta = FindMetaTable("Panel")
local PAN_GetPos = meta.GetPos
local PAN_GetSize = meta.GetSize
local PAN_LocalToScreen = meta.LocalToScreen
local PAN_GetParent = meta.GetParent

local vmeta = FindMetaTable("v2")
local V2_SetUnpacked = vmeta.SetUnpacked
local V2_Unpack = vmeta.Unpack
local V2_Set = vmeta.Set

local NewV2 = Vector2

local math_Round = math.Round

local function InitVector2(self) self.vpos = NewV2() self.cpos = NewV2() end

local function HandleVector2(self)
	if not self.initv2 then
		InitVector2(self)
		self.initv2 = true
	end

	local x, y = self:GetPos()
	self.vpos:SetUnpacked(x, y)

	local w, h = self:GetSize()
	self.cpos = self.vpos + Vector2(math_Round(w * 0.5, 0), math_Round(h * 0.5, 0))
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