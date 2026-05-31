local PlayerManager = player_manager
local math_Random = math.Random

function GM:PlayerInitialSpawn(pl)
    pl:DrawShadow(false)
    pl.LastFlashLightToggle = 0

    pl:SprintDisable()
    pl:SetCanWalk(false)
    pl:SetCanZoom(false)

    pl:SetNoCollideWithTeammates(false) -- We handle custom collisions in GM:PlayerSpawn(pl)

    pl:SetTeam(TEAM_BATTLER)
end

function GM:PlayerSpawn(pl)
    pl:StripWeapons()

    if pl:GetMaterial() ~= "" then
        pl:SetMaterial("")
    end

    pl:UnSpectate()

    local col = Vector(pl:GetInfo("cl_playercolor"))
    col.x = math.Clamp(col.x, 0, 1)
    col.y = math.Clamp(col.y, 0, 1)
    col.z = math.Clamp(col.z, 0, 1)
    pl:SetPlayerColor(col)

    local skin = pl:GetInfoNum("cl_playerskin", 0)
    pl:SetSkin(skin)

    local groups = pl:GetInfo("cl_playerbodygroups") or ""
    groups = string.Explode( " ", groups)
    for k = 0, pl:GetNumBodyGroups() - 1 do
        pl:SetBodygroup(k, tonumber(groups[ k + 1 ]) or 0)
    end

    pl:SetSolid(SOLID_OBB)
    pl:SetSolidFlags(FSOLID_FORCE_WORLD_ALIGNED)

    pl:SetCustomGroupAndFlags(CASCADE_COLLISIONGROUP_NON_SPECTATOR, CASCADE_COLLISIONFLAGS_NON_SPECTATOR)
    pl:SetCustomCollisionCheck(true)

    local desiredName = pl:GetInfo("cl_playermodel")
    local modelName = PlayerManager.TranslatePlayerModel(#desiredName == 0 and self.RandomPlayerModels[math_Random(#self.RandomPlayerModels)] or desiredName)
    local lowerModelName = string.lower(modelName)
    if table.HasValue(self.RestrictedModels, lowerModelName) then
        modelName = "models/player/alyx.mdl"
        lowerModelName = modelName
    end
    pl:SetModel(modelName)

    pl:SetMaxHealth(100)

    col = Vector(pl:GetInfo("cl_weaponcolor"))
    col.x = math.Clamp(col.x, 0, 1)
    col.y = math.Clamp(col.y, 0, 1)
    col.z = math.Clamp(col.z, 0, 1)
    pl:SetWeaponColor(col)

    gamemode.Call("PostPlayerSpawn", pl)
end

function GM:PostPlayerSpawn(pl) end