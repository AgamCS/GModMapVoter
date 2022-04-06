MGV = MGV or {}
MGV.GAMEMODEWIN = 1
MGV.MAPWIN = 2
MGV.GAMEMODESKIP = 3
MGV.MAPSKIP = 4
MGV.UPDATE_VOTE = 5

function MGV.FormatGamemode(name)
    for k, gm in pairs(engine.GetGamemodes()) do
        if gm.name == name then
            return gm.title
        end
    end
    return name
end
