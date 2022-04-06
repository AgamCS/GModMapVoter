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
util.AddNetworkString("MGV_RTV")
util.AddNetworkString("MGV_CancelVote")
util.AddNetworkString("MGV_Error")
util.AddNetworkString("MGV_Update")

net.Receive("MGV_Update", function(len, ply)
    if MGV.Vote.GamemodeAllowed && net.ReadUInt(3) == MGV.UPDATE_VOTE && IsValid(ply) then
        local gamemode_id = net.ReadUInt(32)
        print(gamemode_id)
        print(MGV.Vote.Gamemodes[gamemode_id])
        if MGV.Vote.Gamemodes[gamemode_id] then
            MGV.Vote.GamemodeVoteCount[ply:SteamID64()] = gamemode_id
            net.Start("MGV_Update")
                net.WriteUInt(MGV.UPDATE_VOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(gamemode_id, 32)
            net.Broadcast()
        end
    elseif MGV.Vote.MapAllowed && net.ReadUInt(3) == MGV.UPDATE_VOTE && IsValid(ply) then
        local map_id = net.ReadUInt(32)
        print(map_id)
        print(MGV.Vote.Maps[map_id])
        if MGV.Vote.Maps[map_id] then
            MGV.Vote.MapVoteCount[ply:SteamID64()] = map_id
            net.Start("MGV_Update")
                net.WriteUInt(MGV.UPDATE_VOTE, 3)
                net.WriteEntity(ply)
                net.WriteUInt(map_id, 32)
            net.Broadcast()
        end
    end
end)


local function findMaps(votedGamemode, current) -- Function to find maps based on gamemode prefix
    current = current or " "
    local maps = file.Find("maps/*.bsp", "GAME")
    local amt = 0
    local votemaps = {}
    local prefix = {}
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
        for _, v in pairs(prefix) do
            if string.find(map, "^"..v) && map != current then -- current map will be added later to make sure its the first in the table
                table.insert(votemaps, map:sub(1, -5)) 
                amt = amt + 1
                break
            end
        end
        if(MGV.config.mapLimit and amt >= MGV.config.mapLimit) then break end
    end
    PrintTable(votemaps)
    return votemaps
end

function MGV.Vote:StartGamemodeVote()
    local current = engine.ActiveGamemode()
    local gamemodes = {}
    local gamemode_votes = {}
    for k, v in pairs(engine.GetGamemodes()) do
        if MGV.config.gamemodePrefixes[v.name] != "nil" && v.name != current then
            table.insert(gamemodes, v.name)
        end
    end
    table.sort(gamemodes)
    table.insert(gamemodes, 1, "REPLAY: " .. MGV.FormatGamemode(current))
    if #gamemodes < 2 then -- Force start map vote if there's only one gamemode
        if ("REPLAY: " .. MGV.FormatGamemode(current) == gamemodes[1]) then
            MGV.Vote.VotedGamemode = current
        else
            MGV.Vote.VotedGamemode = gamemodes[1]
        end
        
        net.Start("MGV_Update")
            net.WriteUInt(MGV.GAMEMODESKIP, 3)
            net.WriteString(MGV.Vote.VotedGamemode)
        net.Broadcast()

        timer.Simple(5, function()
            MGV.Vote:StartMapVote()
        end)
        return 
    end
    MGV.Vote.Gamemodes = gamemodes
    local jsonTable = util.TableToJSON(gamemodes)
    net.Start("MGV_GamemodeVote")
        net.WriteString(jsonTable)
        net.WriteUInt(MGV.config.gamemodeVoteTime, 32)
    net.Broadcast()

    MGV.Vote.GamemodeAllowed = true
    
    timer.Create("MGV_GamemodeTimer", MGV.config.gamemodeVoteTime, 1, function()
        for id, gm in pairs(MGV.Vote.GamemodeVoteCount) do
            if !gamemode_votes[gm] then
                gamemode_votes[gm] = 0
            end
            for _, ply in pairs(player.GetAll()) do
                if ply:SteamID64() == id then
                    gamemode_votes[gm] = gamemode_votes[gm] + 1
                end
            end
        end
        MGV.Vote.GamemodeAllowed = false

        if !IsValid(gamemode_votes) then -- If no gamemodes are selected, pick a random one
            MGV.Vote.VotedGamemode = math.random(1, #MGV.Vote.Gamemodes)
            print("No gamemode selected, picking " .. MGV.Vote.Gamemodes[MGV.Vote.VotedGamemode])
            net.Start("MGV_Update")
                net.WriteUInt(MGV.GAMEMODEWIN, 3)
                net.WriteUInt(MGV.Vote.VotedGamemode, 32)
            net.Broadcast()

            timer.Simple(3, function()
                MGV.Vote:StartMapVote()
            end)
            return
        end

        local winner = table.GetWinningKey(gamemodes_votes)
        
        if gamemodes[winner] == "REPLAY: " .. MGV.FormatGamemode(current) then
            MGV.Vote.VotedGamemode = current
        else
            MGV.Vote.VotedGamemode = winner
        end

        net.Start("MGV_Update")
            net.WriteUInt(MGV.GAMEMODEWIN, 3)
            net.WriteUInt(MGV.Vote.VotedGamemode, 32)
        net.Broadcast()

        timer.Simple(3, function()
            MGV.Vote:StartMapVote()
        end)
    end)
end

function MGV.Vote:StartMapVote()
    local current = game.GetMap()
    local gm_name = MGV.Vote.Gamemodes[MGV.Vote.VotedGamemode]
    if gm_name == "REPLAY: " .. MGV.FormatGamemode(engine.ActiveGamemode()) then
        gm_name = engine.ActiveGamemode()
    end
    local maps = findMaps(gm_name, current)
    local map_votes = {}
    table.sort(maps)
    if gm_name == GAMEMODE_NAME then
        table.insert(maps, 1, "REPLAY: " .. current)
    end
    if #maps < 2 then -- Force start map change if there's only one map
        if "REPLAY: " .. current == maps[1] then
            MGV.Vote.VotedMap = current
        else
            MGV.Vote.VotedMap = maps[1]
        end
        print(MGV.Vote.VotedMap)
        net.Start("MGV_Update")
            net.WriteUInt(MGV.MAPSKIP, 3)
            net.WriteString(MGV.Vote.VotedMap)
        net.Broadcast()

        timer.Simple(5, function()
            hook.Run("MapVoteChange", MGV.Vote.VotedMap)
            RunConsoleCommand("changelevel", MGV.Vote.VotedMap)
            RunConsoleCommand("gamemode", MGV.Vote.Gamemodes[MGV.Vote.VotedGamemode])
        end)
        return
    end
    local jsonTable = util.TableToJSON(maps)
    net.Start("MGV_MapVote")
        net.WriteString(jsonTable)
        net.WriteUInt(MGV.config.mapVoteTime, 32)
    net.Broadcast()

    MGV.Vote.MapAllowed = true
    
    timer.Create("MGV_MapVoteTimer", MGV.config.mapVoteTime, 1, function()
        for id, map in pairs(MGV.Vote.MapVoteCount) do
            if !map_votes[map] then
                map_votes[map] = 0
            end
            for _, ply in pairs(player.GetAll()) do
                if ply:SteamID64() == id then
                    map_votes[gm] = map_votes[gm] + 1
                end
            end
        end

        if !IsValid(map_votes) then -- If no maps are selected, pick a random one
            MGV.Vote.VotedMap = maps[math.random(1, #maps)]
            print("No map selected, picking " .. MGV.Vote.VotedMap)
            net.Start("MGV_Update")
                net.WriteUInt(MGV.MAPWIN, 3)
                net.WriteString(MGV.Vote.VotedMap)
            net.Broadcast()

            timer.Simple(3, function()
                hook.Run("MapVoteChange", MGV.Vote.VotedMap)
                RunConsoleCommand("changelevel", MGV.Vote.VotedMap)
                RunConsoleCommand("gamemode", MGV.Vote.Gamemodes[MGV.Vote.VotedGamemode])
            end)
            return
        end
        MGV.Vote.MapAllowed = false
        local winner = table.GetWinningKey(map_votes)
        if maps[winner] == "REPLAY: " .. current then
            MGV.Vote.VotedMap = current
        else
            MGV.Vote.VotedMap = maps[winner]
        end

        net.Start("MGV_Update")
            net.WriteUInt(MGV.MAPWIN, 3)
            net.WriteUInt(MGV.Vote.VotedMap, 32)
        net.Broadcast()

        timer.Simple(3, function()
            hook.Run("MapVoteChange", MGV.Vote.VotedMap)
            RunConsoleCommand("changelevel", MGV.Vote.VotedMap)
            RunConsoleCommand("gamemode", MGV.Vote.Gamemodes[MGV.Vote.VotedGamemode])
        end)
    end)

end

function MGV.Vote:Cancel()
    if MGV.Vote.MapAllowed == true or MGV.Vote.GamemodeAllowed == true then
        MGV.GamemodeAllowed = false
        MGV.Vote.MapAllowed = false
        net.Start("MGV_CancelVote")
        net.Broadcast()

        timer.Remove("MGV_MapVoteTimer")
    end
end
