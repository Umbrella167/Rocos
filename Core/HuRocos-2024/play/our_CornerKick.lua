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

        pass_pos = PassPos()
        debugEngine:gui_debug_x(pass_pos)
        debugEngine:gui_debug_msg(pass_pos,"PassPos")
        -- 如果有挑球，无脑传bugpass
            return "BugPass"
  end,
  Assister = task.stop(),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
  Center = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSCDG}"

},

["BugPass"] = {
  switch = function()
    kickFalg(ball.pos(),function() return param.KickerWaitPlacementPos() end)

    shootPosKicker__ = Utils.PosGetShootPoint(vision, pass_pos:x(),pass_pos:y())
    debugEngine:gui_debug_x(shootPosKicker__,3)
    debugEngine:gui_debug_msg(CGeoPoint(0,0),GlobalMessage.Tick().ball.rights)
    if(GlobalMessage.Tick().ball.rights == -1) then
        return "exit"
    end
    if(player.kickBall("Assister") )then
        return "exit"
    end
  end,
  Assister = task.Shootdot("Assister",function() return pass_pos end,param.shootError + 5,function() return ikkflag end),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,toBallDir("Kicker")),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,toBallDir("Special")),
  Center = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSCDG}"

},

name = "our_CornerKick",
applicable = {
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}
