MGV.config = MGV.config or {}

--[[ Remove any gamemode from the voting list by typing its name and assigning to nil inside the table below
Example: ["darkrp"] = "nil",

Add gamemodes to the voting list by typing its name and assigning it its map type
Example: ["deathrun"] = "deathrun_"

Make sure that the name is the same exact name found in the gamemodes text file. This is typically the same as the gamemodes folder name.
The map type is also found in the gamemodes text file. Its usually something like "maps"   "^something"
Just remove the carrot (^) and add a underscore (_) at the end.
--]]
MGV.config.gamemodePrefixes = {
    ["base"] = "nil",
    ["sandbox"] = "nil", 
    ["darkrp"] = "nil",
    ["kf"] = "nil",
    ["mf_survival"] = "nil",
    ["terrortown"] = "ttt_",
    ["prop_hunt"] = "ph_",
}    

if SERVER then
    MGV.config.mapVoteTime = 30 -- Time to vote for a map
    MGV.config.gamemodeVoteTime = 15 -- Time to vote for a gamemode
    MGV.config.replayMap = true -- Allow voting for replaying the current map
    MGV.config.rtvCount = 3 -- Number of players that are needed to rock the vote use decimals less than 1 for percentage of players on the server
    MGV.config.mapLimit = nil -- Number of maps that appear in the voting screen, set to nil to remove limit

  
    concommand.Add("gamemodeslist", function(NULL) 
        PrintTable( engine.GetGamemodes() )
    end)
end

if CLIENT then
    surface.CreateFont( "MGV_Text", {
        font = "Marlett", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
        extended = false,
        size = ScreenScale(6),
        weight = 500,    
    } )
end