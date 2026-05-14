local toBallDir = function(role)
  return function()
    return player.toBallDir(role)
  end
end

local posClosure = function(p)
  return function()
    return CGeoPoint(p:x(), p:y())
  end
end

-- Defensive formation during opponent's kickoff
-- Positioned between ball and goal to block shooting lanes
-- All robots in our half (x<0), outside center circle (r>500mm), >500mm from ball
local assister_pos = CGeoPoint(-1500, 1500)     -- left blocker
local special_pos = CGeoPoint(-1500, -1500)     -- right blocker
local kicker_pos = CGeoPoint(-1500, 0)          -- center blocker
local center_pos = CGeoPoint(-2500, 500)        -- deep support
local defender_pos = CGeoPoint(-2500, -500)     -- deep support

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
  local defend_limit_x = -param.pitchLength / 2 + param.penaltyDepth + param.defenderBuf
  if defender_pos:x() > defend_limit_x + param.defenderMaxChaseDist then
    return defendToBall("Defender", 1)
  end
  local has_ball = player.myinfraredCount("Defender") >= 8 or
    (player.toBallDist("Defender") < 180 and ball.velMod() < 700)
  if has_ball then
    local clear_target = CGeoPoint(param.pitchLength / 2, 0)
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

  -- Wait for opponent to kick, then exit to normal play
  -- Combined ready+judge states since tasks are identical
  ["ready"] = {
    switch = function()
      if bufcnt(true, 20) and (cond.isNormalStart() or cond.isGameOn()) then
        return "wait"
      end
    end,
    Assister = task.goCmuRush(posClosure(assister_pos), toBallDir("Assister")),
    Kicker = task.goCmuRush(posClosure(kicker_pos), toBallDir("Kicker")),
    Special = task.goCmuRush(posClosure(special_pos), toBallDir("Special")),
    Center = task.goCmuRush(posClosure(center_pos), toBallDir("Center")),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  -- Opponent kicked: ball is live, wait briefly then exit to normal play
  ["wait"] = {
    switch = function()
      if bufcnt(ball.velMod() > 10, 3) then
        return "exit"
      end
      if bufcnt(true, 200) then
        return "exit"
      end
    end,
    Assister = task.goCmuRush(posClosure(assister_pos), toBallDir("Assister")),
    Kicker = task.goCmuRush(posClosure(kicker_pos), toBallDir("Kicker")),
    Special = task.goCmuRush(posClosure(special_pos), toBallDir("Special")),
    Center = task.goCmuRush(posClosure(center_pos), toBallDir("Center")),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
  },

  name = "their_KickOff",
  applicable = {
    exp = "a",
    a = true
  },
  attribute = "attack",
  timeout = 99999
}
