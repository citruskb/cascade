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

local function InitVector2(self) self.vpos = NewV2() self.svpos = NewV2() self.cpos = NewV2() self.scpos = NewV2() end

local function HandleVector2(self)

	if not self.initv2 then
		InitVector2(self)
		self.initv2 = true
	end


	-- Set "vpos"
	-- This is a Vector2, top left corner. Pannel positions are always whole numbers.
	local vpos = self.vpos
	V2_SetUnpacked(vpos,
		PAN_GetPos(self))


	-- Set "svpos"
	-- This is a Vector2, top left corner relative to the entire screen.
	-- If we have a parent, LocalToScreen needs to be relative to that parent. Otherwise, it's simply the same as vpos.
	local parent = PAN_GetParent(self)
	local svpos = self.svpos
	if IsValid(parent) then
		local x, y = V2_Unpack(vpos)
		V2_SetUnpacked(svpos,
			PAN_LocalToScreen(parent, x, y))
	else
		V2_Set(svpos, vpos)
	end


	-- Set "cpos"
	-- This is a Vector2, center of the panel. Remember, postive x is right, positive y is down.
	local w, h = PAN_GetSize(self)
	self.cpos = svpos + Vector2(math_Round(w * 0.5, 0), math_Round(h * 0.5, 0))


	-- Set "scpos"
	-- This is a Vector2, center of the panel relative to the entire screen.
	-- Again, if we have a parent, LocalToScreen needs to be relative to that parent. Otherwise this is the same as cpos.
	local scpos = self.scpos
	if IsValid(parent) then
		local x, y = V2_Unpack(scpos)
		V2_SetUnpacked(scpos,
			PAN_LocalToScreen(self, x, y))
	else
		V2_Set(scpos, cpos)
	end

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
function meta:GetSVPos() return self.svpos end
function meta:GetCPos() return self.cpos end
function meta:GetSCPos() return self.scpos end