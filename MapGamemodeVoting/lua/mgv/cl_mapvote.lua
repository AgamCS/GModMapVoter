MGV.Panel = MGV.Panel or {}
MGV.Endtime = MGV.Endtime or false
MGV.VotedGamemode = MGV.VotedGamemode or false
MGV.VotedMap = MGV.VotedMap or false
MGV.Candidates = MGV.Candidates or {}

net.Receive("MGV_GamemodeVote", function()
    local gamemodes = util.JSONToTable(net.ReadString())
    local length = net.ReadUInt(32)
    MGV.Candidates = gamemodes
    MGV.EndTime = length + CurTime()

    if IsValid(MGV.Panel) then
        MGV.Panel:Remove()
    end
    MGV.Panel = vgui.Create("MGV_VotingPanel")
    MGV.Panel.Title.Text = "GAMEMODE VOTING"
    MGV.Panel.Title:SizeToContents()
    MGV.Panel:PopulateCandidates(MGV.Candidates)
end)

net.Receive("MGV_MapVote", function()
    local maps = util.JSONToTable(net.ReadString())
    local length = net.ReadUInt(32)
    MGV.Candidates = maps
    MGV.EndTime = length + CurTime()

    if IsValid(MGV.Panel) then
        MGV.Panel:Remove()
    end
    MGV.Panel = vgui.Create("MGV_VotingPanel")
    MGV.Panel.Title.Text = "MAP VOTING"
    MGV.Panel.Title:SizeToContents()
    MGV.Panel:PopulateCandidates(MGV.Candidates)
end)

net.Receive("MGV_Update", function()
    local updateType = net.ReadUInt(32)

    if updateType == MGV.UPDATE_VOTE then
        local ply = net.ReadEntity()
        if IsValid(ply) then
            local map_id = net.ReadUInt(32)
            MGV.Candidates[ply:SteamID()] = map_id
            if IsValid(MGV.Panel) then
                MGV.Panel:AddVoter(ply)
            end

        end

    elseif updateType == MGV.GAMEMODEWIN then
        local gamemodeName = MGV.Candidates[net.ReadUInt(32)]
        gamemodeName = MGV.FormatGamemode(gamemodeName)
        MGV.Panel.infoLabel.Text = gamemodeName .. " won the vote!"
        timer.Simple(3, function()
            if IsValid(MGV.Panel) then
                MGV.Panel.infoLabel.Text = ""
            end
        end)

    elseif updateType == MGV.MAPWIN then
        local mapName = net.ReadString()
        MGV.Panel.infoLabel.Text = mapName .. " won the vote!"
        timer.Simple(3, function()
            if IsValid(MGV.Panel) then
                MGV.Panel.infoLabel.Text = ""
            end
        end)

    elseif updateType == MGV.GAMEMODESKIP then
        local gamemodeName = MGV.FormatGamemode(net.ReadString())
        if IsValid(MGV.Panel) then
            MGV.Panel.infoLabel.Text = "Gamemode skipped: Only one avaliable gamemode (" .. gamemodeName ..")"   
            timer.Simple(3, function()
                if IsValid(MGV.Panel) then
                    MGV.Panel.infoLabel.Text = ""
                end
            end)
        end

    elseif updateType == MGV.MAPSKIP then
        local map = net.ReadString()
        if IsValid(MGV.Panel) then
            MGV.Panel.infoLabel.Text = "Map skipped: Only one avaliable map (" .. map ..")"
            timer.Simple(3, function()
                if IsValid(MGV.Panel) then
                    MGV.Panel.infoLabel.Text = ""
                end
            end)
        end
    end

end)

net.Receive("MGV_CancelVote", function()
    if IsValid(MGV.Panel) then
        MGV.Panel:Remove()
        chat.AddText(color_red, "Vote cancelled")
    end
end)


concommand.Add("createMGVPanel", function(NULL)
    local testList = {"Zombie Surival", "Trouble In Terroist Town", "Deathrun"}
    if IsValid(MGV.Panel) then
        MGV.Panel:Remove()
    end
    MGV.Panel = vgui.Create("MGV_VotingPanel")
    MGV.Panel:PopulateCandidates(testList)
end)

concommand.Add("removeMGVPanel", function(NULL)
    if IsValid(MGV.Panel) then
        MGV.Panel:Remove()
    end
end)
