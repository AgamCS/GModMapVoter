MGV = MGV or {}
MGV.GAMEMODEWIN = 1
MGV.MAPWIN = 2
MGV.GAMEMODESKIP = 3
MGV.MAPSKIP = 4
MGV.UPDATE_GAMEMODEVOTE = 5
MGV.UPDATE_MAPVOTE = 6
function MGV.FormatGamemode(name)
    for k, gm in pairs(engine.GetGamemodes()) do
        if gm.name == name then
            return gm.title
        end
    end
end

if SERVER then
    include("config/sh_mgvConfig.lua")
end

if CLIENT then
    AddCSLuaFile("config/sh_mgvConfig.lua")
end

