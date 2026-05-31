DeriveGamemode("orange-juice")

GM.Name		=	"Cascade"
GM.Author	=	"Citrus"
GM.Email	=	"citruskb@outlook.com"
GM.Website	=	""


-- Setup the teams!
TEAM_BATTLER = 1
TEAM_SPECTATOR = 2

team.SetUp(TEAM_BATTLER, "Battlers", Color(70, 100, 240, 255))
team.SetUp(TEAM_SPECTATOR, "Spectators", Color(200, 200, 200, 255))
--


local PlayerManager = player_manager
function GM:GetHandsModel(pl)
	return PlayerManager.TranslatePlayerHands(PlayerManager.TranslateToPlayerModelName(pl:GetModel()))
end


-- Playermodel stuffs

-- Don't let players use these models.
GM.RestrictedModels = {}

-- If a person has no player model then use one of these (auto-generated).
GM.RandomPlayerModels = {}

for name, mdl in pairs(PlayerManager.AllValidModels()) do
	if not table.HasValue(GM.RestrictedModels, string.lower(mdl)) then
		table.insert(GM.RandomPlayerModels, name)
	end
end
--


-- Precache models
local validmodels = PlayerManager.AllValidModels()
validmodels["tf01"] = nil
validmodels["tf02"] = nil

function PrecacheResources()
	for name, mdl in pairs(PlayerManager.AllValidModels()) do
		util.PrecacheModel(mdl)
	end

	for name, wep in pairs(weapons.GetList()) do
		if wep.ViewModel then util.PrecacheModel(wep.ViewModel) end
		if wep.WorldModel then util.PrecacheModel(wep.WorldModel) end
	end
end
hook.Add("Initialize", "Initialize.Precache", PrecacheResources)
--


-- Overrides
function GM:OnPlayerHitGround(pl, inwater, hitfloater, speed) return true end
function GM:GetFallDamage(pl, fallspeed) return 0 end
function GM:VehicleMove() end
function GM:KeyPress(pl, key) end
function GM:KeyRelease(pl, key) end
function GM:PlayerButtonDown(pl, button) end
function GM:PlayerButtonUp(pl, button) end
--


-- Noclip
function GM:PlayerNoClip(pl, on)
	if not pl:IsAdmin() then return false end

	return true
end
--