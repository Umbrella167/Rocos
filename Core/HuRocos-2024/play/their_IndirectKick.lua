local half = param.pitchLength / 2
local penalty_front = -half + param.penaltyDepth

local toBallDir = function(role)
  return function()
    return player.toBallDir(role)
  end
end

-- Ensure position is at least 560mm from ball (rule: 0.5m minimum)
local function ensureBallDist(pos)
  local dist = pos:dist(ball.pos())
  if dist < 560 then
    pos = ball.pos() + Utils.Polar2Vector(560, (pos - ball.pos()):dir())
  end
  return pos
end

-- Detect free kick near our corner: ball close to our goal line AND sideline
local function isCornerKick()
  return ball.posX() < -3000 and math.abs(ball.posY()) > 2000
end

-- Assister: stand between ball and target point, 750mm from ball
-- Virtual point (-2700, 0) intercepts crosses from corner kicks
local assisterPos = function()
  local target
  if isCornerKick() then
    target = CGeoPoint(-2800, 0)
  else
    target = CGeoPoint(-half, 0)
  end
  local pos = ball.pos() + Utils.Polar2Vector(750, (target - ball.pos()):dir())
  if Utils.MakeInField ~= nil then
    pos = Utils.MakeInField(pos, 200)
  end
  return ensureBallDist(pos)
end

-- Fallback positions for Kicker/Special when no enemies to mark
local fallbackKickerPos = function()
  return CGeoPoint(-2500, -2000)
end
local fallbackSpecialPos = function()
  return CGeoPoint(-2500, 2000)
end

-- Center: man-mark 3rd highest threat opponent
local function centerMarkingTask()
  local enemyDribblingNum = GlobalMessage.Tick().their.dribbling_num
  local idir = player.toBallDir("Center")
  local ball_pos = ball.rawPos()

  local candidates = {}
  for i = 0, param.maxPlayer - 1 do
    if enemy.valid(i) and i ~= enemyDribblingNum and enemy.posX(i) < param.markingThreshold then
      local vel_mod = enemy.velMod(i)
      local vel_dir = enemy.velDir(i)
      local enemy_to_goal_dir = (param.ourGoalPos - enemy.pos(i)):dir()
      local raw_diff = vel_dir - enemy_to_goal_dir
      local angle_diff = math.abs(math.atan2(math.sin(raw_diff), math.cos(raw_diff)))
      local moving_toward_goal = angle_diff < math.pi / 2 and 1 or 0
      local depth = param.markingThreshold - math.max(enemy.posX(i), 0)
      local threat = vel_mod * param.markingThreatSpeedWeight * moving_toward_goal
                   + depth * param.markingThreatPosWeight
      table.insert(candidates, { num = i, threat = threat })
    end
  end

  table.sort(candidates, function(a, b) return a.threat > b.threat end)

  -- No enemies to mark → push up to midfield, ready to intercept
  if #candidates == 0 then
    local mexe, mpos = GoCmuRush { pos = CGeoPoint(-800, 0), dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }
    return { mexe, mpos }
  end

  -- Assign target: skip 1st (Kicker) and 2nd (Special), take 3rd or last available
  local target_num
  if #candidates >= 3 then
    target_num = candidates[3].num
  else
    target_num = candidates[#candidates].num
  end

  -- Calculate marking position (same logic as task.defender_marking)
  local enemy_pos = enemy.pos(target_num)
  local ballToEnemy = enemy_pos - ball_pos
  local ballToEnemyDist = ballToEnemy:mod()
  local ballToEnemyDir = ballToEnemy:dir()

  local goal_dir = (param.ourGoalPos - enemy_pos):dir()
  local perp_flag = (param.ourGoalPos:y() - enemy_pos:y()) > 0 and 1 or -1
  local perp_dir = goal_dir + perp_flag * math.pi / 2

  local normalized_dist = math.min(ballToEnemyDist / param.maxMarkingDist, 1)
  local lateral_offset = param.markingLateralBase * (1 - normalized_dist) + param.markingLateralMin
  local back_offset = param.minMarkingDist + ballToEnemyDist * param.markingBackRate

  local markingPos = enemy_pos
    + Utils.Polar2Vector(lateral_offset, perp_dir)
    + Utils.Polar2Vector(-back_offset, ballToEnemyDir)

  -- Out-of-field fallback
  if not Utils.InField(markingPos) then
    local goal_dir = (param.ourGoalPos - enemy_pos):dir()
    local fallback = enemy_pos + Utils.Polar2Vector(param.minMarkingDist, goal_dir)
    if Utils.MakeInField ~= nil then
      markingPos = Utils.MakeInField(fallback, 150)
    elseif Utils.InField(fallback) then
      markingPos = fallback
    else
      markingPos = enemy_pos + Utils.Polar2Vector(param.minMarkingDist, (enemy_pos - CGeoPoint(0, 0)):dir())
    end
  end

  markingPos = ensureBallDist(markingPos)

  local mexe, mpos = GoCmuRush { pos = markingPos, dir = idir, acc = a, flag = flag.allow_dss, rec = r, vel = v }
  return { mexe, mpos }
end

-- Corner kick defense: stand at corner post to block crosses
local function cornerDefenderTask()
  local y = ball.posY() > 0 and 1120 or -1120
  local pos = CGeoPoint(-4000, y)
  local idir = player.toPointDir(ball.pos(), "Defender")
  local mexe, mpos = GoCmuRush { pos = pos, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }
  return { mexe, mpos }
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
  -- Don't go too deep toward our goal (stay at or outside penalty area front)
  defendPoint = CGeoPoint(math.max(defendPoint:x(), -half + param.penaltyDepth + 100), defendPoint:y())
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
        return "defend"
      end
    end,
    Assister = task.goCmuRush(assisterPos, toBallDir("Assister")),
    Kicker = function() return task.defender_marking("Kicker", fallbackKickerPos) end,
    Special = function() return task.defender_marking("Special", fallbackSpecialPos) end,
    Center = function() return centerMarkingTask() end,
    Defender = function()
      if isCornerKick() then return cornerDefenderTask() else return defenderDirectTask() end
    end,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  ["defend"] = {
    switch = function()
      if bufcnt(ball.velMod() > 10, 3) then
        return "exit"
      end
      if bufcnt(true, 200) then
        return "exit"
      end
    end,
    Assister = task.goCmuRush(assisterPos, toBallDir("Assister")),
    Kicker = function() return task.defender_marking("Kicker", fallbackKickerPos) end,
    Special = function() return task.defender_marking("Special", fallbackSpecialPos) end,
    Center = function() return centerMarkingTask() end,
    Defender = function()
      if isCornerKick() then return cornerDefenderTask() else return defenderDirectTask() end
    end,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  name = "their_IndirectKick",
  applicable = {
    exp = "a",
    a = true
  },
  attribute = "attack",
  timeout = 99999
}
