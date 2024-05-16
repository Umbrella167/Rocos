local DSS_FLAG = flag.allow_dss + flag.dodge_ball + flag.our_ball_placement
local pass_pos = CGeoPoint(0,0)
local shootPosKicker__ = CGeoPoint(0,0)
local toBallDir = function(role)
    return function()
        return player.toBallDir(role)
    end
end
local ikkflag = 1
local kickFalg = function(startPos,endPos) 
    local istartPos
    if type(startPos) == 'function' then
      istartPos = startPos()
    else
      istartPos = startPos
    end

    local iendPos
    if type(endPos) == 'function' then
      iendPos = endPos()
    else
      iendPos = endPos
    end
  if Utils.isValidPass(vision,istartPos,iendPos,param.enemy_buffer+30) then
    ikkflag = kick.flat()
  else
    ikkflag = kick.chip()
  end
end
gPlayTable.CreatePlay {
firstState = "Init1",

["Init1"] = {
	switch = function()
    
		return "start"
	end,
	Assister = task.goCmuRush(function() return player.pos(param.LeaderNum) end, player.toBallDir("Assister"), a, DSS_FLAG),
    Kicker = task.goCmuRush(function() return player.pos(param.LeaderNum) end, 0, a, DSS_FLAG, r, v, s, force_manual),
    Special = task.goCmuRush(function() return player.pos(param.LeaderNum) end, 0, a, DSS_FLAG, r, v, s, force_manual),
    Center = task.stop(),
    Defender = task.stop(),
    Goalie = task.stop(),
    match = "[A][KSC]{DG}"
},
["start"] = {
  	switch = function()
      kickFalg(ball.pos(),function() return param.KickerWaitPlacementPos() end)
    	debugEngine:gui_debug_arc(ball.pos(),500,0,360,1)
		return "ready"
	end,
	Assister = task.goCmuRush(function() return ball.pos() end),
	Kicker   = task.stop(),
	Special  = task.stop(),
	Center = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
  match = "{AKSCDG}"

},

["ready"] = {
  	switch = function()
      kickFalg(ball.pos(),function() return param.KickerWaitPlacementPos() end)
			return "passToKicker"

	end,
	Assister = task.stop(),
	Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
	Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
	Center = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
  match = "{AKSCDG}"

},


["passToKicker"] = {
	switch = function()
    kickFalg(ball.pos(), param.KickerWaitPlacementPos())
        if(GlobalMessage.Tick().ball.rights == -1 or player.kickBall("Assister")) then
            return "exit"
        end
  end,
  Assister = task.Shootdot("Assister",function() return param.KickerWaitPlacementPos() end,param.shootError + 5,function() return ikkflag end),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
  Center = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSCDG}"

},



name = "our_FrontKick",
applicable = {
  exp = "a",
  a = true
},
attribute = "attack",
timeout = 99999
}
