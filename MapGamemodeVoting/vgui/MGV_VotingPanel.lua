MGV.Panel = MGV.Panel or {}
function MGV.Panel:Init()
    local scrw, scrh = ScrW(), ScrH()

    self:ParentToHUD()
    self:MakePopup()
    self.Votes = {}
    
    self.Canvas = vgui.Create("MGV_Canvas", self)
    

    self.Countdown = vgui.Create("MGV_CountdownLabel", self)
    self.Countdown:SetPos(scrw * 0.5, scrh * 0.05)

    self.VotingList = vgui.Create("MGV_VotingList", self)
    
end

function MGV.Panel:PopulateCandidates(tbl)
    self.VotingList:Populate(tbl)
end

function MGV.Panel:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 195)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("MGV_VotingPanel", MGV.Panel, "DPanel")