MGV.Vote = MGV.Vote or {}
MGV.Vote.Gamemodes = MGV.Vote.Gamemodes or {} -- List of gamemodes
MGV.Vote.Maps = MGV.Vote.Maps or {} -- List of maps
MGV.Vote.GamemodeAllowed = MGV.Vote.GamemodeAllowed or false -- Is gamemode voting currently allowed
MGV.Vote.MapAllowed = MGV.Vote.MapAllowed or false -- Is map voting currently allowed
MGV.Vote.VotedGamemode = MGV.Vote.VotedGamemode or false -- Has a gamemode already been voted for
MGV.Vote.VotedMap = MGV.Vote.VotedMap or false -- Has a map already been voted for
MGV.Vote.GamemodeVoteCount = MGV.Vote.GamemodeVoteCount or {}
MGV.Vote.MapVoteCount = MGV.Vote.MapVoteCount or {}

util.AddNetworkString("MGV_GamemodeVote")
util.AddNetworkString("MGV_MapVote")
util.AddNetworkString("MGV_SkipGamemodeVote")
util.AddNetworkString("MGV_RTV")
util.AddNetworkString("MGV_CancelVote")
util.AddNetworkString("MGV_Error")
util.AddNetworkString("MGV_Update")

net.Receive("MGV_Update", function(len, ply)
    if MGV.Vote.GamemodeAllowed && net.ReadUInt(3) == MGV.UPDATE_GAMEMODEVOTE && IsValid(ply) then
        local gamemode_id = net.ReadUInt(32)
        if MGV.Vote.Gamemodes[gamemode_id] then
            MGV.Vote.GamemodeVoteCount[ply:SteamID64()] = gamemode_id
            net.Start("MGV_Update")
                net.WriteUInt(MGV.UPDATE_GAMEMODEVOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(gamemode_id, 32)
            net.Broadcast()
        end
    elseif MGV.Vote.MapAllowed && net.ReadUInt(3) == MGV.UPDATE_MAPVOTE && IsValid(ply) then
        local map_id = net.ReadUInt(32)
        if MGV.Vote.Maps[map_id] then
            MGV.Vote.MapVoteCount[ply:SteamID64()] = map_id
            net.Start("MGV_Update")
                net.WriteUInt(MGV.UPDATE_MAPVOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(map_id, 32)
            net.Broadcast()
        end
    end
end)


local function findMaps(votedGamemode) -- Function to find maps based on gamemode prefix
    local maps = file.Find("maps/*.bsp", "GAME")
    local amt = 0
    local votemaps = {}
    prefix = {}
    for k, v in pairs(engine.GetGamemodes()) do
        if v.name == votedGamemode then
            local str = v.maps
            prefix = string.Explode("|", str)
        end
        for h=1, #prefix do
            if string.sub(prefix[h], 1, 1) then
                prefix[h] = string.sub(prefix[h], 2,  nil)
            end
        end
    end
    
    for k, map in pairs(maps) do
        for _, v in pairs(prefix)
        if string.find(map, "^"..v) then
            table.insert(votemaps, map:sub(1, -5)) 
            amt = amt + 1
            break
        end
        if(MGV.config.mapLimit and amt >= MGV.config.mapLimit) then break end
    end
    return votemaps
end

function MGV.Vote:StartGamemodeVote()
    local current = engine.ActiveGamemode()
    local gamemodes = {}
    for k, v in pairs(engine.GetGamemodes()) do
        if MGV.config.gamemodePrefixes[v.name] != "nil" && v.name != current then
            table.insert(gamemodes, v.name)
        end
    end

    if #gamemodes < 2 then -- Force start map vote if there's only one gamemode
        MGV.Vote.VotedGamemode = gamemodes[1]
        net.Start("MGV_Update", function()
            net.WriteUInt(MGV.GAMEMODESKIP, 3)
        net.Broadcast()

        timer.Simple(5, function()
            MGV.Vote:StartMapVote()
        end)
        break 
    end
    table.insert(gamemodes, 1, "REPLAY CURRENT GAMEMODE " .. MGV.FormatGamemode(current))
    MGV.Vote.Gamemodes = gamemodes
    local jsonTable = util.TableToJSON(gamemodes)
    net.Start("MGV_GamemodeVote")
        net.WriteString(jsonTable)
        net.WriteUInt(MGV.config.gamemodeVoteTime, 32)
    net.Broadcast()

    MGV.Votes.GamemodeAllowed = true
    
    timer.Create("MGV_GamemodeTimer", MGV.config.gamemodeVoteTime, 1, function()
        local gamemode_votes = {}
        for id, map in pairs(MGV.Votes.GamemodeVoteCount) do
            if !gamemode_votes[v] then
                gamemode_votes[v] = 0
            end
            for _, ply in pairs(player.GetAll()) do
                if ply:SteamID64() == id then
                    gamemode_votes[v] = gamemodes_votes[v] + 1
                end
            end
        end
        MGV.Votes.GamemodeAllowed = false
        local winner = table.GetWinningKey(gamemodes_votes)
        if winner == "REPLAY CURRENT GAMEMODE " .. MGV.FormatGamemode(current) then
            MGV.Vote.VotedGamemode = current
        else
            MGV.Vote.VotedGamemode = winner
        end

        net.Start("MGV_Update")
            net.WriteUInt(MGV.GAMEMODEWIN, 3)
            net.WriteUInt(winner, 32)
        net.Broadcast()

        timer.Simple(3, function()
            MGV.Vote:StartMapVote()
        end)
    end)
end

function MGV.Vote:StartMapVote()
    local current = game.GetMap()
    local maps = findMaps(MGV.Vote.VotedGamemode)
    if #maps < 2 then -- Force start map change if there's only one map
        MGV.Vote.VotedMap = maps[1]
        net.Start("MGV_Update", function()
            net.WriteUInt(MGV.MAPSKIP, 3)
        net.Broadcast()

        timer.Simple(5, function()
            RunConsoleCommand("changelevel", MGV.Vote.VotedMap)
            RunConsoleCommand("changegamemode", MGV.Vote.VotedGamemode)
        end)
        break 
    end
    table.remove(maps, table.KeyFromValue(maps, current))
    table.insert(gamemodes, 1, "REPLAY CURRENT MAP " .. current)
    local jsonTable = util.TableToJSON(maps)
    net.Start("MGV_MapVote")
        net.WriteString(jsonTable)
        net.WriteUInt(MGV.config.mapVoteTime, 32)
    net.Broadcast()

    MGV.Votes.MapAllowed = true
    
    timer.Create("MGV_MapVoteTimer", MGV.config.mapVoteTime, 1, function()
        local map_votes = {}
        for id, map in pairs(MGV.Vote.MapVoteCount) do
            if !map_votes[v] then
                map_votes[v] = 0
            end
            for _, ply in pairs(player.GetAll()) do
                if ply:SteamID64() == id then
                    map_votes[v] = map_votes[v] + 1
                end
            end
        end
        MGV.Votes.MapAllowed = false
        local winner = table.GetWinningKey(map_votes)
        if winner == "REPLAY CURRENT Map " .. current then
            MGV.Vote.VotedMap = current
        else
            MGV.Vote.VotedMap = winner
        end

        net.Start("MGV_Update")
            net.WriteUInt(MGV.GAMEMODEWIN, 3)
            net.WriteUInt(winner, 32)
        net.Broadcast()

        timer.Simple(3, function()
            RunConsoleCommand("changelevel", MGV.Vote.VotedMap)
            RunConsoleCommand("changegamemode", MGV.Vote.VotedGamemode)
        end)
    end)

end

