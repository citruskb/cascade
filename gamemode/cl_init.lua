include("shared.lua")
include("sh_convars.lua")
include("sh_registeritems.lua")

include("cl_handlemouse.lua")
include("cl_debug.lua")

include("vgui/dgridcell.lua")
include("vgui/dgridinventory.lua")
include("vgui/pshop.lua")
include("vgui/pphysobj2doverlay.lua")

GM_ZPOS_POVERLAY = 10
GM_ZPOS_PSHOP = 9

MySelf = MySelf or NULL
hook.Add("InitPostEntity", "GetLocal", function()
	MySelf = LocalPlayer()
end)

function GM:Initialize()
	RunConsoleCommand("r_drawmodeldecals", "0") -- Could possibly cause crashes.
	RunConsoleCommand("r_dynamic", "0") -- Flashlight dynamic lights of other players.
	RunConsoleCommand("cl_threaded_bone_setup", "0") -- disable due to client crash.
end

function GM:InitPostEntity()
	RunConsoleCommand("pp_bloom", "0")
	self:CreateSounds()
end

function GM:OnReloaded()
	self.BaseClass.OnReloaded(self)

	timer.Simple(0, function() LocalPlayerFound() end)
end

local M_Player = FindMetaTable("Player")
local P_Team = M_Player.Team

function GM:PlayerBindPress(pl, bind, pressed)
	local pTeam = P_Team(MySelf)

	if pTeam ~= TEAM_SPECTATOR and string.find(bind, "impulse 100") then
		gamemode.Call("ToggleFlashlight")
	end

	if bind == "gm_showhelp" then
		if pressed then self:ShowHelp() end
		return true
	end

	if bind == "+reload" then
		if pressed and self.HeldItem then
			self.HeldItem:Rotate90CCW()
		end
		return true
	end

	--if bind == "+attack" then gamemode.Call("LeftMouseClick", pl) end
end

-- Validity hack

-- We do this so we don't need to check if the local player is valid constantly clientside in these functions.
-- Empty functions get filled when the local player is found.
function GM:Think() end
function GM:_Think() end

GM.Think = GM._Think
GM.HUDShouldDraw = GM.Think
GM.CalcView = GM.Think
GM.ShouldDrawLocalPlayer = GM.Think
GM.PostDrawOpaqueRenderables = GM.Think
GM.PostDrawTranslucentRenderables = GM.Think
GM.HUDPaint = GM.Think
GM.HUDPaintBackground = GM.Think
GM.CreateMove = GM.Think
GM.PrePlayerDraw = GM.Think
GM.PostPlayerDraw = GM.Think
GM.InputMouseApply = GM.Think
GM.GUILeftMouseClick = GM.Think
GM.HUDWeaponPickedUp = GM.Think

local gm_ = GM
function LocalPlayerFound()
	gm_.Think = gm_._Think
	gm_.HUDShouldDraw = gm_._HUDShouldDraw
	gm_.CalcView = gm_._CalcView
	gm_.ShouldDrawLocalPlayer = gm_._ShouldDrawLocalPlayer
	gm_.PostDrawTranslucentRenderables = gm_._PostDrawTranslucentRenderables
	gm_.HUDPaint = gm_._HUDPaint
	gm_.HUDPaintBackground = gm_._HUDPaintBackground
	gm_.CreateMove = gm_._CreateMove
	gm_.PrePlayerDraw = gm_._PrePlayerDraw
	gm_.PostPlayerDraw = gm_._PostPlayerDraw
	gm_.InputMouseApply = gm_._InputMouseApply
	gm_.GUILeftMouseClick = gm_._GUILeftMouseClick
	gm_.HUDWeaponPickedUp = gm_._HUDWeaponPickedUp
	gm_.RenderScene = gm_._RenderScene
	gm_.SetupSkyboxFog = gm_._SetupSkyboxFog
	gm_.SetupWorldFog = gm_._SetupWorldFog

	if render.GetDXLevel() >= 80 then gm_.RenderScreenspaceEffects = gm_._RenderScreenspaceEffects end

	gm_.UncappedScreenScale = ScreenScale(true)
end
hook.Add("InitPostEntity", "InitPostEntity.LocalPlayerFound", LocalPlayerFound)
hook.Add("OnReloaded", "OnReloaded.LocalPlayerFound", LocalPlayerFound)

-- The following functions should be set up as is with the underscore. No need to check if the local player is valid or not.
local nextTick = 0
function GM:_Think()
	local ct = CurTime()

	gamemode.Call("HandleMousePress")
	PhysObj2D:PhysicsStep()

	if nextTick > ct then return end
	nextTick = ct + 1

	local allPlayers = player.GetAll()
	for i = 1, #allPlayers do
		local pl = allPlayers[i]
		gamemode.Call("PlayerThink", pl)
	end

	self.UncappedScreenScale = ScreenScale(true)
end
function GM:PlayerThink(pl) end

HideHUDElements = {}
HideHUDElements["CHudWeaponSelection"] = true
HideHUDElements["CHUDQuickInfo"] = true
HideHUDElements["CHudHealth"] = true
HideHUDElements["CHudSecondaryAmmo"] = true
HideHUDElements["CHudAmmo"] = true
HideHUDElements["CHudTrain"] = true
HideHUDElements["CHudMessage"] = true
HideHUDElements["CHudWeapon"] = true
HideHUDElements["CHudCrosshair"] = true
HideHUDElements["CHudCloseCaption"] = true
HideHUDElements["CHudGMod"] = true
function GM:_HUDShouldDraw(name)
	return (self.clFilmMode and name == "CHudWeaponSelection") or not HideHUDElements[name]
end

function GM:_CalcView(pl, origin, angles, fov, znear, zfar)
	return self.BaseClass.CalcView(self, pl, origin, angles, fov, znear, zfar)
end

function GM:_ShouldDrawLocalPlayer(pl)
	return false
end

function GM:_PostDrawTranslucentRenderables() end

function GM:_HUDPaint() end

function GM:_HUDPaintBackground() end

function GM:_CreateMove() end

function GM:_PrePlayerDraw(pl)
	if pl ~= MySelf and pl:IsEffectActive(EF_DIMLIGHT) then
		pl:RemoveEffects(EF_DIMLIGHT)
	end
end

function GM:_PostPlayerDraw(pl) end

function GM:_InputMouseApply(cmd, x, y, ang) end

function GM:_GUILeftMouseClick(mc) end

function GM:_HUDWeaponPickedUp(wep) end

function GM:_RenderScene() end

function GM:_SetupSkyboxFog(skyboxscale) return end

function GM:_SetupWorldFog() return end
--


-- Skybox stuff
function GM:PreDrawSkyBox() self.DrawingInSky = true end
function GM:PostDrawSkyBox() self.DrawingInSky = false end
--

-- Overrides
function GM:CreateCustomFonts() end
function GM:PlayerDeath(pl, attacker) end
function GM:ScalePlayerDamage(pl, hitgroup, dmginfo) end
function GM:PlayerShouldTakeDamage(pl, attacker) return false end
function GM:PostProcessPermitted(str) return false end
--


-- Footsteps
function GM:PlayerStepSoundTime(pl, iType, bWalking)
	if iType == STEPSOUNDTIME_NORMAL or iType == STEPSOUNDTIME_WATER_FOOT then
		return 520 - pl:GetVelocity():Length()
	end

	if iType == STEPSOUNDTIME_ON_LADDER then return 500 end

	if iType == STEPSOUNDTIME_WATER_KNEE then return 650 end

	return 350
end
function GM:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume) return end
--


-- EasyLabel
function EasyLabel(parent, text, font, textcolor)
	local dpanel = vgui.Create("DLabel", parent)
	if font then
		dpanel:SetFont(font or "DefaultFont")
	end
	dpanel:SetText(text)
	dpanel:SizeToContents()
	if textcolor then
		dpanel:SetTextColor(textcolor)
	end
	dpanel:SetKeyboardInputEnabled(false)
	dpanel:SetMouseInputEnabled(false)

	return dpanel
end
--


-- Fonts
GM.font_family = "Typeface Mario 64"
function GM:CreateCustomFonts() end
--

-- Sounds
function GM:CreateSounds()
	self.snd_pop = CreateSound(MySelf, "items/ammocrate_open.wav")
end
function GM:PlaySnd(idx)
	self["snd_" .. idx]:Stop()
	self["snd_" .. idx]:Play()
end
--