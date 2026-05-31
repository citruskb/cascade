include("shared.lua")

function GM:Initialize()
	RunConsoleCommand("r_drawmodeldecals", "0") -- Could possibly cause crashes.
	RunConsoleCommand("r_dynamic", "0") -- Flashlight dynamic lights of other players.
	RunConsoleCommand("cl_threaded_bone_setup", "0") -- disable due to client crash.
end

function GM:InitPostEntity()
	RunConsoleCommand("pp_bloom", "0")
end

function GM:OnReloaded()
	self.BaseClass.OnReloaded(self)

	timer.Simple(0, function() LocalPlayerFound() end)
end

local nextTick = 0
function GM:Think()
	local ct = CurTime()

	if nextTick > ct then return end
	nextTick = ct + 1

	local allPlayers = player.GetAll()
	for i = 1, #allPlayers do
		local pl = allPlayers[i]
		gamemode.Call("PlayerThink", pl)
	end
end
function GM:PlayerThink(pl) end

local M_Player = FindMetaTable("Player")
local P_Team = M_Player.Team
function GM:PlayerBindPress(pl, bind, wasin)
	local pTeam = P_Team(MySelf)

	if pTeam ~= TEAM_SPECTATOR and string.find(bind, "impulse 100") then
		gamemode.Call("ToggleFlashlight")
	end
end

-- The following functions should be set up as is with the underscore. No need to check if the local player is valid or not. 
function GM:_Think() end

function GM:_HUDShouldDraw(name)
	return (self.clFilmMode and name == "CHudWeaponSelection") --or not HideHUDElements[name]
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

function GM:_GUIMousePressed(mc) end

function GM:_HUDWeaponPickedUp(wep) end

function GM:_RenderScene() end

function GM:_SetupSkyboxFog(skyboxscale) return end

function GM:_SetupWorldFog() return end