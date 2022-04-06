MGV = MGV or {}
include("config/sh_mgvConfig.lua")
include("mgv/sv_mapvote.lua")
include("mgv/sh_mapvote.lua") 

AddCSLuaFile("mgv/sh_mapvote.lua")
AddCSLuaFile("vgui/MGV_VotingPanel.lua")
AddCSLuaFile("vgui/MGV_VotingList.lua")
AddCSLuaFile("config/sh_mgvConfig.lua")
AddCSLuaFile("mgv/cl_mapvote.lua")

print("mgv loaded")

hook.Add( "Initialize", "AutoTTTMapVote", function()
    local gm_name = engine.ActiveGamemode()
    if GAMEMODE_NAME == "terrortown" then
      function CheckForMapSwitch()
         -- Check for mapswitch
         local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
         SetGlobalInt("ttt_rounds_left", rounds_left)

         local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
         local switchmap = false
         local nextmap = string.upper(game.GetMapNext())

          if rounds_left <= 0 then
            LANG.Msg("limit_round", {mapname = nextmap})
            switchmap = true
          elseif time_left <= 0 then
            LANG.Msg("limit_time", {mapname = nextmap})
            switchmap = true
          end
          if switchmap then
              timer.Stop("end2prep")
              MGV.Vote:StartGamemodeVote(nil, nil, nil, nil)
          end
      end
    end
    
    if GAMEMODE_NAME == "deathrun" then
        function RTV.Vote()
            MGV.Vote:StartGamemodeVote(nil, nil, nil, nil)
        end
    end
    
    if GAMEMODE_NAME == "zombiesurvival" then
      hook.Add("LoadNextMap", "MAPVOTEZS_LOADMAP", function()
        MGV.Vote:StartGamemodeVote(nil, nil, nil, nil)
        return true   
      end )
    end

end )