AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")
include("sv_spawnlogic.lua")

function GM:Initialize()
	game.ConsoleCommand("sv_gravity 600\n")
end


-- Overrides
function GM:InitPostEntity() end
function GM:PlayerAmmoChanged(pl, ammoID, oldCount, newCount) end
function GM:OnNPCKilled(ent, attacker, inflictor) end
function GM:ShowHelp(pl) end
function GM:ShowTeam(pl) end
function GM:ShowSpare1(pl) end
function GM:ShowSpare2(pl) end
function GM:PlayerSpawnObject(ply, model, skin) return true end
function GM:PlayerSpawnProp(ply, model) return true end
--


-- Collisions
CASCADE_COLLISIONGROUP_DEFAULT = 0
CASCADE_COLLISIONGROUP_NONE = GetNextPow(1)
CASCADE_COLLISIONGROUP_ALL = GetNextPow()
CASCADE_COLLISIONGROUP_DYNAMICPROP = GetNextPow()
CASCADE_COLLISIONGROUP_STATICPROP = GetNextPow()
CASCADE_COLLISIONGROUP_NON_SPECTATOR = GetNextPow()
CASCADE_COLLISIONGROUP_SPECTATOR = GetNextPow()

CASCADE_COLLISIONFLAGS_NON_SPECTATOR = bit.bor(CASCADE_COLLISIONGROUP_ALL, CASCADE_COLLISIONGROUP_DYNAMICPROP, CASCADE_COLLISIONGROUP_STATICPROP)
CASCADE_COLLISIONFLAGS_SPECTATOR = CASCADE_COLLISIONGROUP_SPECTATOR
CASCADE_COLLISIONFLAGS_PROP = bit.bor(CASCADE_COLLISIONGROUP_ALL, CASCADE_COLLISIONGROUP_DYNAMICPROP, CASCADE_COLLISIONGROUP_STATICPROP)
--