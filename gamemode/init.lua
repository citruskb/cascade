AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

AddCSLuaFile("sh_convars.lua")
AddCSLuaFile("sh_registeritems.lua")

AddCSLuaFile("cl_dermaskin.lua")
AddCSLuaFile("cl_handlemouse.lua")
AddCSLuaFile("cl_debug.lua")

AddCSLuaFile("vgui/dgridcell.lua")
AddCSLuaFile("vgui/dplayermodel.lua")
AddCSLuaFile("vgui/dplayerstats.lua")
AddCSLuaFile("vgui/pgridinventory.lua")
AddCSLuaFile("vgui/piteminfo.lua")
AddCSLuaFile("vgui/pshop.lua")
AddCSLuaFile("vgui/pphysobj2doverlay.lua")

include("shared.lua")
include("sh_convars.lua")
include("sh_registeritems.lua")

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