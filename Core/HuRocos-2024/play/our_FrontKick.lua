local half = param.pitchLength / 2

local toBallDir = function(role)
  return function()
    return player.toBallDir(role)
  end
end

local function defendToBall(role, mode)
  local ball_pos = ball.pos()
  local role_pos = player.pos(role)
  local basePos = param.ourGoalPos
  if mode == 0 then
    basePos = param.ourTopGoalPos
  elseif mode == 1 then
    basePos = param.ourButtomGoalPos
  elseif mode == 2 then
    basePos = param.ourGoalPos
  end
  local defendPoint = task.getLineCrossDefenderPos(ball_pos, basePos)
  if defendPoint == CGeoPoint(9999, 9999) then
    defendPoint = role_pos
  end
  local idir = player.toPointDir(ball_pos, role)
  local mexe, mpos = GoCmuRush { pos = defendPoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }
  return { mexe, mpos }
end

local function defenderDirectTask()
  local ball_pos = ball.pos()
  local defender_pos = player.pos("Defender")
  if player.toBallDist("Assister") < param.defenderAssisterDist then
    return defendToBall("Defender", 1)
  end
  local defend_limit_x = -half + param.penaltyDepth + param.defenderBuf
  if defender_pos:x() > defend_limit_x + param.defenderMaxChaseDist then
    return defendToBall("Defender", 1)
  end
  local has_ball = player.myinfraredCount("Defender") >= 8 or
    (player.toBallDist("Defender") < 180 and ball.velMod() < 700)
  if has_ball then
    local clear_target = CGeoPoint(half, 0)
    return task.pass_2026("Defender", function() return clear_target end, kick.flat, 5.0, 180, 100)()
  end
  local intercept_pos = Utils.GetBestInterPos(vision, defender_pos, param.playerVel, 2, 0, param.V_DECAY_RATE)
  if intercept_pos ~= CGeoPoint(9999, 9999) then
    if Utils.MakeInField ~= nil then
      intercept_pos = Utils.MakeInField(intercept_pos, 120)
    end
    if defender_pos:dist(intercept_pos) < 460 then
      return task.defend_kick("Defender")
    end
  end
  return defendToBall("Defender", 1)
end

local subScript = false

gPlayTable.CreatePlay {
  firstState = "Init1",

  ["Init1"] = {
    switch = function()
      if not subScript then
        gSubPlay.new("Goalie", "Nor_Goalie")
        subScript = true
      end
      return "ready"
    end,
    Assister = task.stop(),
    Kicker = task.stop(),
    Special = task.stop(),
    Center = task.stop(),
    Defender = task.stop(),
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  ["ready"] = {
    switch = function()
      if bufcnt(true, 20) then
        return "pass"
      end
    end,
    Assister = task.goCmuRush(function() return ball.pos() end, toBallDir("Assister")),
    Kicker = task.goCmuRush(function() return param.KickerWaitPlacementPos() end, toBallDir("Kicker")),
    Special = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end, toBallDir("Special")),
    Center = task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-1500, 0) end, toBallDir("Center")),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  -- Assister passes toward Kicker (dynamic target)
  ["pass"] = {
    switch = function()
      if player.kickBall("Assister") then
        return "attack"
      end
      if GlobalMessage.Tick().ball.rights == -1 then
        return "exit"
      end
      if bufcnt(true, 200) then
        return "exit"
      end
    end,
    Assister = task.Shootdot("Assister", function() return player.pos("Kicker") end, param.shootError, kick.flat),
    Kicker = task.goCmuRush(function() return param.KickerWaitPlacementPos() end, toBallDir("Kicker")),
    Special = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end, toBallDir("Special")),
    Center = task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-1500, 0) end, toBallDir("Center")),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  -- Kicker intercepts and shoots
  ["attack"] = {
    switch = function()
      if player.kickBall("Kicker") then
        return "exit"
      end
      if GlobalMessage.Tick().ball.rights == -1 then
        return "exit"
      end
      if bufcnt(true, 200) then
        return "exit"
      end
    end,
    Kicker = task.getball(function() return CGeoPoint(half, 0) end, param.playerVel, param.getballMode),
    Assister = task.goCmuRush(function() return ball.pos() end, toBallDir("Assister")),
    Special = task.goCmuRush(function() return param.SpecialWaitPlacementPos() end, toBallDir("Special")),
    Center = task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-1500, 0) end, toBallDir("Center")),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  name = "our_FrontKick",
  applicable = {
    exp = "a",
    a = true
  },
  attribute = "attack",
  timeout = 99999
}
