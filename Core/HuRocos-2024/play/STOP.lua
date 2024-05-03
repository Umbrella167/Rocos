local goaliePos = CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius,0)
local middlePos = function()
  local ballPos = ball.pos()
  local idir = (pos.ourGoal() - ballPos):dir()
  local pos = ballPos + Utils.Polar2Vector(550+param.playerFrontToCenter,idir)
  return pos
end
local leftPos = function()
  local ballPos = ball.pos()
  local idir = ((pos.ourGoal() - ballPos):dir()) + 0.6
  local pos = ballPos + Utils.Polar2Vector(550+param.playerFrontToCenter,idir)
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
  Kicker   = task.goCmuRush(middlePos,dir.playerToBall,DSS_FLAG),
  Assister = task.goCmuRush(leftPos,dir.playerToBall,DSS_FLAG),
  Special  = task.goCmuRush(rightPos,dir.playerToBall,DSS_FLAG),
  Tier = task.goCmuRush(defendpos[3],dir.playerToBall,DSS_FLAG),
  Defender = task.goCmuRush(defendpos[2],dir.playerToBall,DSS_FLAG),
  Goalie = task.goCmuRush(defendpos[1],dir.playerToBall),
  match = "[AKS]{TDG}"
},

name = "STOP",
applicable = {
  exp = "a",
  a = true
},
attribute = "attack",
timeout = 99999
}
