--[[
Cascade
Made by Citrus
citruskb@outlook.com
]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function GM:Initialize()
	game.ConsoleCommand("sv_gravity 600\n")
end

function GM:InitPostEntity() end