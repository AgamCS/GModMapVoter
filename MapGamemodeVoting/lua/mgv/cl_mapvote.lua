MGV.Endtime = MGV.Endtime or false
MGV.VotedGamemode = MGV.Vote.VotedGamemode or false
MGV.VotedMap = MGV.Vote.VotedMap or false
MGV.Candidates = MGV.Candidates or {}

net.Receive("MGV_GamemodeVote"), function()
    local gamemodes = util.JSONToTable(net.ReadString())
    local length = net.ReadUInt(32)
    MGV.Candidates = gamemodes
    MGV.EndTime = length + CurTime()

    if IsValid(MGV.Panel) then
        MGV.Panel:Remove()
    end
    MGV.Panel = vgui.Create("MGV_VotingPanel")
    MGV.Panel:PopulateCandidates(MGV.Candidates)
end)





