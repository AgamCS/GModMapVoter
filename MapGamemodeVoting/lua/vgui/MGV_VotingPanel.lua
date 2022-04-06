local PANEL = {}
local blur = Material( "pp/blurscreen" )
local replay_color = Color(90, 255, 53)

function PANEL:Init()
    self.Voters = {}
    local scrw, scrh = ScrW(), ScrH()

    self:ParentToHUD()
    self:SetSize(scrw, scrh)
    self:ShowCloseButton(false)

    self.Background = vgui.Create("DPanel", self)
    self.Background:SetSize(scrw, scrh)
    self.Background:MakePopup()
    
    self.Background:Center()
    self.Background:SetKeyboardInputEnabled(false)
    self.Background.Paint = function(s, w, h)
        surface.SetDrawColor(0, 0, 0, 195)
        surface.DrawRect(0, 0, w, h)
        local x, y = s:LocalToScreen( 0, 0 )

        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.SetMaterial( blur )

    for i = 1, 5 do
        blur:SetFloat( "$blur", ( i / 4 ) * 4 )
        blur:Recompute()

        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
    end
    end

    self.Title = vgui.Create("DLabel", self.Background)
    self.Title:SetText("")
    self.Title:SetPos(scrw * 0.5, scrh * 0.05)
    self.Title:SetSize(scrw * 0.05, scrh * 0.15)
    self.Title.Text = "TITLE"

    self.Title.Paint = function(s, w, h)
        draw.SimpleText(s.Text, "MGV_Text", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.Countdown = vgui.Create("DLabel", self.Background)
    self.Countdown:SetSize(scrw * 0.5, scrh * 0.15)
    self.Countdown:SetPos(0, scrh * 0.07)
    self.Countdown:SetText("")
    self.Countdown.Text = "COUNTDOWN: BLANK SECONDS"
    
    self.Countdown.Paint = function(s, w, h)
        draw.SimpleText(s.Text, "MGV_Text", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.infoLabel = vgui.Create("DLabel", self.Background)
    self.infoLabel:SetPos(scrw * 0.5, scrh * 0.09)
    self.infoLabel:SetSize(scrw * 0.05, scrh * 0.15)
    self.infoLabel:SetText("")
    self.infoLabel.Text = "INFO"
    
    self.infoLabel.Paint = function(s, w, h)
        draw.SimpleText(s.Text, "MGV_Text", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    

    self.VotingList = vgui.Create("DScrollPanel", self.Background)
    self.VotingList:StretchToParent(0, scrh * 0.05 , 0, 0)
    self.VotingList:SetPos(0, scrh * 0.3)
    self.VotingList:DockMargin(scrw * 0.05, scrh * 0.05, scrw * 0.3, scrh * 0.1)
    self.VotingList:DockPadding(scrw * 0.2, scrh * 0.1, scrw * 0.3, scrh * 0.5)
    
    
end

function PANEL:PerformLayout(w, h)

    self:SetSize(w, h)

    self.Background:SetSize(w, h)
    self.Background:Center()

    self.Title:SetSize(w * 0.7, h * 0.15)
    self.Title:SetPos(-(w * 0.674), h * 0.05)
    
    self.Countdown:SetSize(w * 0.7, h * 0.15)
    self.Countdown:SetPos(-(w * 0.674), h * 0.09)

    self.infoLabel:SetSize(w * 0.7, h * 0.15)
    self.infoLabel:SetPos(-(w * 0.674), h * 0.13)

    
    self.VotingList:StretchToParent(0, h * 0.05 , 0, 0)
    self.VotingList:SetPos(0, h * 0.3)
    self.VotingList:DockMargin(w * 0.05, h * 0.05, w * 0.3, h * 0.1)
    self.VotingList:DockPadding(w * 0.2, h * 0.1, w * 0.3, h * 0.5)

end

function PANEL:PopulateCandidates(tbl)
    self.VotingList:Clear()
    local w, h = self.VotingList:GetWide(), self.VotingList:GetTall()
    for k, v in pairs(tbl) do
        local btn = vgui.Create("DButton", self.VotingList)
        btn.id = k
        btn:SetSize(w * 0.1, h * 0.1)
        btn:Dock(TOP)
        btn:DockMargin(0, h * 0.01, 0, h * 0.01)
        btn:SetText("")

        btn.NumVotes = 0
        
        --self.VotingList:AddItem(btn)

        btn.DoClick = function()
            net.Start("MGV_Update")
                net.WriteUInt(MGV.UPDATE_VOTE, 3)
                net.WriteUInt(btn.id, 32)
            net.SendToServer()
        end

        btn.Paint = function(s, w, h)
            if s:IsHovered() then
                surface.SetDrawColor(0, 0, 0, 200)
                surface.DrawRect(0, 0, w, h)
            else
                surface.SetDrawColor(0, 0, 0, 250)
                surface.DrawRect(0, 0, w, h)
            end
            draw.SimpleText(MGV.FormatGamemode(v), "MGV_Text", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end       
    end
end

function PANEL:Think()
    for k, v in pairs(self.VotingList:GetChildren()) do
        v.NumVotes = 0
    end
    
    for k, v in pairs(self.Voters) do
        if(not IsValid(v.Player)) then
            v:Remove()
        else
            if(not MGV.Votes[v.Player:SteamID()]) then
                v:Remove()
            else
                local bar = self:GetCandidate(MGV.Votes[v.Player:SteamID()])
                
                bar.NumVotes = bar.NumVotes + 1
                
                if(IsValid(bar)) then
                    local CurrentPos = Vector(v.x, v.y, 0)
                    local NewPos = Vector((bar.x + bar:GetWide()) - 21 * bar.NumVotes - 2, bar.y + (bar:GetTall() * 0.5 - 10), 0)
                    
                    if(not v.CurPos or v.CurPos ~= NewPos) then
                        v:MoveTo(NewPos.x, NewPos.y, 0.3)
                        v.CurPos = NewPos
                    end
                end
            end
        end
        
    end
    
    local timeLeft = math.Round(math.Clamp(MGV.EndTime - CurTime(), 0, math.huge))
    self.Countdown.Text = timeLeft or 0 .. " seconds"
end


function PANEL:AddVoter(ply)
    for k, v in pairs(self.Voters) do
        if v.Player == ply then return false end
    end

    local avatarCanvas = vgui.Create("DPanel", self.VotingList:GetCanvas())
    local avatar = vgui.Create("AvatarImage", avatarCanvas)
    avatarCanvas.Player = ply
    avatar:SetSize(16, 16)
    avatar:SetPos(160, 160)
    avatar:SetZPos(1000)
    avatar:SetTooltip(ply:Name())
    avatar:SetPlayer(ply)

    avatarCanvas.Paint = function(s, w, h)
        surface.SetDrawColor(color_white)
        surface.DrawRect(0, 0, w, h)
    end

    table.insert(self.Voters, avatarCanvas)
end

function PANEL:GetCandidate(id)
    for k, v in pairs(self.VotingList:GetChildren()) do
        if v == id then
            return v
        end
    end
    return false
end

function PANEL:Paint(w, h)
    
end

vgui.Register("MGV_VotingPanel", PANEL, "DFrame")