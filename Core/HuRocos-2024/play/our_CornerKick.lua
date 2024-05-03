local DSS_FLAG = flag.allow_dss + flag.dodge_ball + flag.our_ball_placement
local pass_pos = CGeoPoint(0,0)
local shootPosKicker__ = CGeoPoint(0,0)

local PassPos = function()
	local KickerShootPos = Utils.PosGetShootPoint(vision, 3658,-1124)
	if ball.posY() < 0 then 
		startPos = CGeoPoint(3500,1350)
		endPos = CGeoPoint(4000,1000)
	else
		startPos = CGeoPoint(3500,-1350)
		endPos = CGeoPoint(4000,-1000)
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
    GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
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
        pass_pos = PassPos()
        debugEngine:gui_debug_x(pass_pos)
        debugEngine:gui_debug_msg(pass_pos,"PassPos")
        -- 如果有挑球，无脑传bugpass
        if Utils.isValidPass(vision,CGeoPoint(ball.posX(),ball.posY()),pass_pos,130) then
            return "BugPass"
        else
            
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
    shootPosKicker__ = Utils.PosGetShootPoint(vision, pass_pos:x(),pass_pos:y())
    debugEngine:gui_debug_x(shootPosKicker__,3)
    debugEngine:gui_debug_msg(CGeoPoint(0,0),GlobalMessage.Tick.ball.rights)
    if(GlobalMessage.Tick.ball.rights == -1) then
        return "exit"
    end
    if(player.kickBall("Assister") )then
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
  Assister = task.Shootdot("Assister",function() return pass_pos end,param.shootKp,param.shootError + 5,kick.flat),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSTDG}"
},

["KickerTouch"] = {
  switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if(GlobalMessage.Tick.ball.rights == -1) then
            return "exit"
        end
        if (player.kickBall("Kicker")) then
            return "exit"
        end
        shootPosKicker__ = Utils.PosGetShootPoint(vision, pass_pos:x(),pass_pos:y())
        debugEngine:gui_debug_x(shootPosKicker__,3)
  end,
  Assister = task.stop(),
  Kicker   = task.touchKick(function() return shootPosKicker__ end, false, 9999, kick.flat),
  Special  = task.stop(),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSTDG}"
},

["KickerGetball"] = {
    switch = function()
        GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if(GlobalMessage.Tick.ball.rights == -1 or player.toBallDist("Kicker") < 500) then
            return "exit"
        end
    end,
    Assister = task.stop(),
    Kicker   = task.getball(function() return pass_pos end,param.playerVel,param.getballMode),
    Special  = task.stop(),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.stop(),
    match = "{AKSTDG}"
},
name = "our_CornerKick",
applicable = {
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}
