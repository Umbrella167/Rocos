local goaliePos = CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius,0)
local middlePos = function()
  local ballPos = ball.pos()
  local idir = (pos.ourGoal() - ballPos):dir()
  local pos = ballPos + Utils.Polar2Vector(550+param.playerFrontToCenter,idir)
  return pos
end
local leftPos = function()
    local ballPos = ball.pos()
    ballPos = CGeoPoint(ballPos:x(),ballPos:y())
    local idir = ((pos.ourGoal() - ballPos):dir()) + 0.6
    local pos = ballPos + Utils.Polar2Vector(550+param.playerFrontToCenter,idir)
    debugEngine:gui_debug_msg(CGeoPoint(0,0),"x:" ..ballPos:x() .. "      y:" ..ballPos:y())
    return pos
end
local rightPos = function()
  local ballPos = ball.pos()
  local idir = ((pos.ourGoal() - ballPos):dir()) - 0.6
  local pos = ballPos + Utils.Polar2Vector(550+param.playerFrontToCenter,idir)
  return pos
end

local defendpos = {
  CGeoPoint(-4350,0),
  CGeoPoint(-3300,850),
  CGeoPoint(-3300,-850),

}
local a = 2500
local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
gPlayTable.CreatePlay {

firstState = "start",

["start"] = {
  switch = function()
    debugEngine:gui_debug_arc(ball.pos(),500,0,360,1)
    if cond.isGameOn() then
      return "exit"
    end
  end,
  Kicker   = task.goCmuRush(middlePos,dir.playerToBall,a,DSS_FLAG),
  Assister = task.goCmuRush(leftPos,dir.playerToBall,a,DSS_FLAG),
  Special  = task.goCmuRush(rightPos,dir.playerToBall,a,DSS_FLAG),
  Center = task.goCmuRush(defendpos[3],dir.playerToBall,a,DSS_FLAG),
  Defender = task.goCmuRush(defendpos[2],dir.playerToBall,a,DSS_FLAG),
  Goalie = task.goCmuRush(defendpos[1],dir.playerToBall),
  match = "[AKSC]{DG}"
},

name = "STOP",
applicable = {
  exp = "a",
  a = true
},
attribute = "attack",
timeout = 99999
}
