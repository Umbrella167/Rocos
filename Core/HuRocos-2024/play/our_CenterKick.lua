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
  Special  = task.stop(),
  Kicker   = task.stop(),
  Center = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSCDG}"

},



["ready"] = {
  switch = function()
    kickFalg(ball.pos(),function() return param.KickerWaitPlacementPos() end)
        pass_pos = CGeoPoint (param.SpecialWaitPlacementPos():x(),param.SpecialWaitPlacementPos():y())
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

    pass_pos = CGeoPoint (param.KickerWaitPlacementPos():x(),param.KickerWaitPlacementPos():y())
	
    if player.num("Special") ~= -1 and player.num("Special") ~= nil then 
		shootPosKicker__ = player.pos("Special")
		shootPosSpecial__ = Utils.PosGetShootPoint(vision, player.pos("Special"):x(),player.pos("Special"):y())
	else
		shootPosKicker__ = Utils.PosGetShootPoint(vision, pass_pos:x(),pass_pos:y())
    end

    debugEngine:gui_debug_x(shootPosKicker__,3)
    debugEngine:gui_debug_msg(CGeoPoint(0,0),GlobalMessage.Tick().ball.rights)
    if(GlobalMessage.Tick().ball.rights == -1) then
        return "exit"
    end
    shootPosKicker__ = Utils.PosGetShootPoint(vision, pass_pos:x(),pass_pos:y())
    debugEngine:gui_debug_x(shootPosKicker__,3)
    debugEngine:gui_debug_msg(CGeoPoint(0,0),GlobalMessage.Tick().ball.rights)
    if(GlobalMessage.Tick().ball.rights == -1 ) then
        return "exit"
    end
    if(player.kickBall("Assister"))then
        return "exit"
    end
  end,
  Assister = task.Shootdot("Assister",function() return pass_pos end,param.shootError + 2,function() return ikkflag end),
  Kicker   = task.goCmuRush(function() return param.KickerWaitPlacementPos() end,function() return (player.pos("Special") - player.pos("Kicker") ):dir() end),
  Special  = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end,function() return (shootPosSpecial__ - player.pos("Special")):dir() end),
  Center = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "{AKSCDG}"

},



name = "our_CenterKick",
applicable = {
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}
