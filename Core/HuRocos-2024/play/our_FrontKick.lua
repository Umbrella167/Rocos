local DSS_FLAG = flag.allow_dss + flag.dodge_ball + flag.our_ball_placement
local pass_pos = CGeoPoint(0,0)
local shootPosKicker__ = CGeoPoint(0,0)
local toBallDir = function(role)
    return function()
        return player.toBallDir(role)
    end
end
gPlayTable.CreatePlay {
firstState = "start",
["start"] = {
  	switch = function()
    	debugEngine:gui_debug_arc(ball.pos(),500,0,360,1)
		return "ready"
	end,
	Assister = task.goCmuRush(function() return ball.pos() end),
	Kicker   = task.stop(),
	Special  = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "(AKS){TDG}"
},

["ready"] = {
  	switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),CGeoPoint(player.posX("Kicker"),player.posY("Kicker")),param.enemy_buffer) then
			return "passToKicker"
        elseif Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),CGeoPoint(player.posX("Special"),player.posY("Special")),param.enemy_buffer) then
			return "passToSpecial"
        end
	end,
	Assister = task.stop(),
	Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
	Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "(AKS){TDG}"
},



["passToKicker"] = {
	switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if(GlobalMessage.Tick.ball.rights == -1 or player.toBallDist("Kicker") > 500) then
            return "exit"
        end
  end,
  Assister = task.Shootdot("Assister",function() return player.pos("Kicker") end,param.shootKp,param.shootError + 5,kick.flat),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "(AKS){TDG}"
},
["passToSpecial"] = {
	switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if(GlobalMessage.Tick.ball.rights == -1 or player.toBallDist("Special") > 500) then
            return "exit"
        end
  end,
  Assister = task.Shootdot("Assister",function() return player.pos("Special") end,param.shootKp,param.shootError + 5,kick.flat),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "(AKS){TDG}"
},


name = "our_FrontKick",
applicable = {
  exp = "a",
  a = true
},
attribute = "attack",
timeout = 99999
}
