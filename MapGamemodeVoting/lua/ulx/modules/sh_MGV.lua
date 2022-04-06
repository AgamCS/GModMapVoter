local CATEGORY_NAME = "MGV"
------------------------------ VoteMap ------------------------------
local function MGV_VOTE( calling_ply, should_cancel )
	if not should_cancel then
		MGV.StartGamemodeVote(votetime, nil, nil, nil)
		ulx.fancyLogAdmin( calling_ply, "#A called a vote!" )
	else
		MGV.Vote:Cancel()
		ulx.fancyLogAdmin( calling_ply, "#A canceled the vote" )
	end
end

local mapvotecmd = ulx.command( CATEGORY_NAME, "MGV", MGV_VOTE, "!MGV" )
mapvotecmd:addParam{ type=ULib.cmds.BoolArg, invisible=true }
mapvotecmd:defaultAccess( ULib.ACCESS_ADMIN )
mapvotecmd:help( "Invokes the map vote logic" )
mapvotecmd:setOpposite( "unmapvote", {_, _, true}, "!cancelMGV" )