local DSS_FLAG = flag.allow_dss + flag.dodge_ball + flag.our_ball_placement
local pass_pos = CGeoPoint(4300,1100)
local shootPosKicker__ = CGeoPoint(0,0)
local shootPosSpecial__ = CGeoPoint(0,0)
local PassPos = function()
	local KickerShootPos = Utils.PosGetShootPoint(vision, player.posX("Kicker"),player.posY("Kicker"))
	if ball.posY() < 0 then 
		startPos = CGeoPoint(4050,1500)
		endPos = CGeoPoint(4400,800)
	else
		startPos = CGeoPoint(4050,-1500)
		endPos = CGeoPoint(4400,-800)
	end
	local res = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,startPos,endPos,100,500)
	return CGeoPoint(res:x(),res:y())
end
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
  Special  = task.stop(),
  Kicker   = task.stop(),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "(AK)(S){TDG}"
},



["ready"] = {
  switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        pass_pos = CGeoPoint (param.SpecialWaitPlacementPos():x(),param.SpecialWaitPlacementPos():y())
        -- 如果有挑球，无脑传bugpass
        if Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),pass_pos,param.enemy_buffer) then
            return "BugPass"
        elseif Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),pass_pos,param.enemy_buffer) then
            
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




["BugPass"] = {
  switch = function()
    GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
    pass_pos = CGeoPoint (param.KickerWaitPlacementPos():x(),param.KickerWaitPlacementPos():y())
	
    if player.num("Special") ~= -1 and player.num("Special") ~= nil then 
		shootPosKicker__ = player.pos("Special")
		shootPosSpecial__ = Utils.PosGetShootPoint(vision, player.pos("Special"):x(),player.pos("Special"):y())
	else
		shootPosKicker__ = Utils.PosGetShootPoint(vision, pass_pos:x(),pass_pos:y())
    end

    debugEngine:gui_debug_x(shootPosKicker__,3)
    debugEngine:gui_debug_msg(CGeoPoint(0,0),GlobalMessage.Tick.ball.rights)
    if(GlobalMessage.Tick.ball.rights == -1) then
        return "exit"
    end
	debugEngine:gui_debug_msg(CGeoPoint(-1000,-1000),player.num("Special"),4)
    if(player.kickBall("Assister"))then
		if player.num("Special") == -1 or player.num("Special") == nil then 
			return "exit"
		end
        if(player.canTouch(pass_pos, shootPosKicker__, param.canTouchAngle) and 
          Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),pass_pos,param.enemy_buffer)) then
            return "KickerTouch"
        elseif Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),pass_pos,param.enemy_buffer) then
            return "KickerGetball"
        else
            return "exit"
        end
    end
  end,
  Assister = task.Shootdot("Assister",function() return pass_pos end ,param.shootKp+1,15,kick.flat),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,function() return (player.pos("Special") - player.pos("Kicker") ):dir() end),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,function() return (shootPosSpecial__ - player.pos("Special")):dir() end),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "(AKS){TDG}"
},


["KickerTouch"] = {
  switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if(GlobalMessage.Tick.ball.rights == -1) then
            return "exit"
        end
      	debugEngine:gui_debug_msg(CGeoPoint(-1000,-1000),tostring(player.canTouch(ball.pos(), shootPosSpecial__, param.canTouchAngle)))
        if (player.kickBall("Kicker")) then
            return "SpecialTouch"
            -- if(player.canTouch(ball.pos(), shootPosSpecial__, param.canTouchAngle) and 
			-- 	  Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),shootPosSpecial__,param.enemy_buffer)) then
			-- 	return "SpecialTouch"

			-- elseif Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),shootPosSpecial__,param.enemy_buffer) then
			-- 	-- return "SpecialGetball"
			-- else
            -- 	return "exit"
        	-- end
        end
        debugEngine:gui_debug_x(shootPosKicker__,3)
  end,
  Assister = task.stop(),
  Kicker   = task.touchKick(function() return CGeoPoint(player.posX("Special"),player.posY("Special")) end, false, param.shootKp, kick.flat),
  Special  = task.goCmuRush(function() return CGeoPoint(player.posX("Special"),player.posY("Special")) end,function() return (shootPosSpecial__ - player.pos("Special")):dir() end,_,DSS_FLAG),

  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{ASKTDG}"
},

["KickerGetball"] = {
    switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if(GlobalMessage.Tick.ball.rights == -1 or player.toBallDist("Kicker") < 500) then
            return "exit"
        end
    end,
    Assister = task.stop(),
	Special  =task.getball(function() return pass_pos end,param.playerVel,param.getballMode),
    Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.stop(),
	match = "{ASKTDG}"
},


["SpecialTouch"] = {
	switch = function()
		  GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
		  if(GlobalMessage.Tick.ball.rights == -1) then
			  return "exit"
		  end
		  if (player.kickBall("Kicker")) then
			  if(player.canTouch(ball.pos(), shootPosSpecial__, param.canTouchAngle) and 
				  Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),shootPosSpecial__,param.enemy_buffer)) then
				  return "SpecialTouch"
			  elseif Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),shootPosSpecial__,param.enemy_buffer) then
				  -- return "SpecialGetball"
			  else
			  return "exit"
		  end
		  end
		  debugEngine:gui_debug_x(shootPosKicker__,3)
	end,
	Assister = task.stop(),
	Kicker   = task.stop(),
	Special  = task.touchKick(function() return shootPosSpecial__ end, false, 999, kick.flat),
  
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "{ASKTDG}"
  },

name = "our_CenterKick",
applicable = {
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}
