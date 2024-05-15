module(..., package.seeall)

---------------------------------
INF                       = 1e9
PI                        = 3.141592653589793238462643383279
maxPlayer                 = 16
ballDiameter              = 42
---------------------------------
-----------------------------------------------|
--                ZJHU参数                  --|
-----------------------------------------------|
enemy_buffer              = CGetSettings("ZJHU/enemy_buffer", "Int")
playerBallRightsBuffer    = CGetSettings("ZJHU/playerBallRightsBuffer", "Int")
playerInfraredCountBuffer = CGetSettings("ZJHU/playerInfraredCountBuffer", "Int")
our_goalie_num            = CGetSettings("ZJHU/our_goalie_num", "Int")
defend_num1               = CGetSettings("ZJHU/defend_num1", "Int")
defend_num2               = CGetSettings("ZJHU/defend_num2", "Int")

-----------------------------------------------|
--                feild参数                  --|
-----------------------------------------------|
pitchLength               = CGetSettings("field/width", "Int")
pitchWidth                = CGetSettings("field/height", "Int")
freeKickAvoidBallDist     = 500
penaltyWidth              = CGetSettings("field/penaltyLength", "Int")
penaltyDepth              = CGetSettings("field/penaltyWidth", "Int")
penaltyRadius             = penaltyWidth / 2
penaltySegment            = 500
ourTopRightPenaltyPos     = CGeoPoint:new_local(-pitchLength / 2 + penaltyDepth, penaltyRadius)
ourButtomRightPenaltyPos  = CGeoPoint:new_local(-pitchLength / 2 + penaltyDepth, -penaltyRadius)
ourTopPenaltyPos          = CGeoPoint:new_local(-pitchLength / 2, penaltyRadius)
ourButtomPenaltyPos       = CGeoPoint:new_local(-pitchLength / 2, -penaltyRadius)
-- 球门参数
goalWidth                 = CGetSettings("field/goalWidth", "Int")
goalDepth                 = CGetSettings("field/goalDepth", "Int")
goalRadius                = goalWidth / 2
ourGoalLine               = CGeoSegment(CGeoPoint:new_local(-pitchLength / 2, -INF), CGeoPoint:new_local(-pitchLength / 2,INF))
ourGoalPos                = CGeoPoint:new_local(-pitchLength / 2, 0)
ourTopGoalPos             = CGeoPoint:new_local(-pitchLength / 2, goalRadius)
ourButtomGoalPos          = CGeoPoint:new_local(-pitchLength / 2, -goalRadius)
penaltyMiddleLine         = CGeoSegment(ourGoalPos, ourGoalPos + Utils.Polar2Vector(penaltyDepth, 0))

-- 是否为真实场地
isReality = false
Team = "ONE" -- Team = "TWO"
allowTouch = false              -- 是否开启touch
canTouchAngle = 45           -- 可以touch的角度
dribblingExclusionDist = 135 -- 距离禁区多少距离开启带球
debugSize = 100
-----------------------------------------------|
--                Getball参数                 --|
-----------------------------------------------|
playerVel = 1.5                                 -- 机器人速度
getballMode = 1                               -- [0[激进模式], 1[保守模式], 2[middle]]
-- local V_DECAY_RATE_Reality = 700              -- 场地摩擦
local V_DECAY_RATE_Reality = 800              -- 场地摩擦

lastInterPos = CGeoPoint:new_local(-INF, -INF) -- 上一次算点结果
rushToBallCount = 0                            -- 
distRate = 0.2                                --

-----------------------------------------------|
--                球权和红外参数                --|
-----------------------------------------------|
playerBallRightsBuffer = 120    --球权判断缓冲值
playerInfraredCountBuffer = 120 -- 红外判断缓冲值
-----------------------------------------------|
--                Robot参数                  --|
-----------------------------------------------|
enemy_buffer = 120 -- lua 两点间有无敌人阈值
playerFrontToCenter = 60
lengthRatio = 1.5
widthRatio = 1.5
stopRatio = 1.1
frameRate = 73
playerRadius = 90 -- 机器人半径
-----------------------------------------------|
--                Shoot参数                   --|
-----------------------------------------------|
local shootError_Reality = 5 --1.8  -- 射击误差
shootKp = 0.1                -- 射击力度比例
-- shootPos = CGeoPoint(0, 0)
shootPos = CGeoPoint(pitchLength / 2, 0)

-----------------------------------------------|
--               rot参数                      --|
-----------------------------------------------|
rotPos = CGeoPoint(60, 60)           --CGeoPoint(80,80)      --旋转坐标
rotVel = 4.5                           --旋转速度
local rotCompensate_Reality = -0.015 --旋转补偿
-----------------------------------------------|
--                Tick固定匹配参数             --|
-----------------------------------------------|
-- our_goalie_num = 0
-- defend_num1 = 1
-- defend_num2 = 2
-----------------------------------------------|
--             marking参数             --|
-----------------------------------------------|
markingThreshold = 1500 -- 球的X超过 markingThreshold 队友去盯防
minMarkingDist = playerRadius * 3
markingPosRate1 = 1 / 6
markingPosRate2 = 1 / 10
-----------------------------------------------|
--             defend参数             --|
-----------------------------------------------|
defenderShootMode = function() return 1 end -- 1 flat  2 chip
defenderBuf = playerRadius * 1.5

defenderTopRightPos     = CGeoPoint:new_local(-pitchLength / 2 + penaltyDepth + defenderBuf, penaltyRadius + defenderBuf)
defenderButtomRightPos  = CGeoPoint:new_local(-pitchLength / 2 + penaltyDepth + defenderBuf, -penaltyRadius - defenderBuf)
defenderTopPos          = CGeoPoint:new_local(-pitchLength / 2, penaltyRadius + defenderBuf)
defenderButtomPos       = CGeoPoint:new_local(-pitchLength / 2, -penaltyRadius - defenderBuf)

defenderRadius = ourGoalPos:dist(ourTopRightPenaltyPos) + defenderBuf
defenderAimX = -pitchLength / 4
defenderCatchBuf = param.playerRadius * 6
-----------------------------------------------|
--             goalie参数             --|
-----------------------------------------------|
goalieShootMode = function() return 2 end -- 1 flat  2 chip
goalieBuf = 0
-- goalie 需要考虑敌人朝向的距离，一般为半场的一半
goalieAimDirRadius = pitchLength / 4
-- goalie 在考虑敌人朝向时会走出的最远距离， 一般为球门半径
-- enemyAimBuf = goalRadius
enemyAimBuf = goalWidth
-- goalie 移动的线（mode-0）
goalieMoveLine = CGeoSegment(CGeoPoint:new_local(-pitchLength / 2 + goalieBuf, -INF),
    CGeoPoint:new_local(-pitchLength / 2 + goalieBuf, INF))
goalieMoveX = -pitchLength / 2 + goalieBuf
-- goalie 移动的半径（mode-1）
goalieRadius = goalRadius - goalieBuf
-- goalie 刚吸到球后准备的时间
goalieReadyFrame = 20
-- goalie 吸到球后往稳定点缓慢移动一段距离
goalieStablePoint = CGeoPoint(-pitchLength / 2 + penaltyDepth / 2, 0)
-- goalie 带球的最大帧数
goalieDribblingFrame = 200
-- goalie 带球的加速度
goalieDribblingA = 1000
-- goalie 要踢向的点
goalieTargetPos = CGeoPoint(param.pitchLength / 2, param.pitchWidth / 2)
-- 当截球点离goalie非常近的时候就会直接拦球
goalieCatchBuf = goalieBuf*2


-- 对齐的准确度
alignRate = 0.8



--~ -------------------------------------------
--~ used for debug
--~ -------------------------------------------
WHITE = 0
RED = 1
ORANGE = 2
YELLOW = 3
GREEN = 4
CYAN = 5
BLUE = 6
PURPLE = 7
GRAY = 9
BLACK = 10
--~ -------------------------------------------
--~ used for getdata
--~ -------------------------------------------
FIT_PLAYER_POS_X = pitchLength / 2 - penaltyDepth
FIT_PLAYER_POS_Y = pitchWidth / 2 - 200

-------------------------------------------
-- 方便实物，仿真的值互换  因为因为仿真的值是固定的
V_DECAY_RATE = isReality and V_DECAY_RATE_Reality or 2100
rotCompensate = isReality and rotCompensate_Reality or 0.05
shootError = isReality and shootError_Reality or 8
-------------------------------------------
--- 定位球配置
-- 前场判定位置
CornerKickPosX = 3000
CenterKickPosX = 0
KickerWaitPlacementPos = function()
    local startPos
    local endPos
    local KickerShootPos = Utils.PosGetShootPoint(vision, player.posX("Kicker"), player.posY("Kicker"))
    -- 角球
    if ball.posX() > CornerKickPosX then
        if ball.posY() > 0 then
            startPos = CGeoPoint(2600, -1250)
            endPos = CGeoPoint(3000, -850)
        else
            startPos = CGeoPoint(2600, 1250)
            endPos = CGeoPoint(3000, 850)
        end
        -- 中场球
    elseif ball.posX() < CornerKickPosX and ball.posX() > CenterKickPosX then
        if ball.posY() < 0 then
            startPos = CGeoPoint(4050, 1500)
            endPos = CGeoPoint(4400, 800)
        else
            startPos = CGeoPoint(4050, -1500)
            endPos = CGeoPoint(4400, -800)
        end
    else
        -- 前场球
        startPos = CGeoPoint(ball.posX() + 3000, 1000)
        endPos = CGeoPoint(ball.posX() + 4000, -1000)
    end
    local attackPos = Utils.GetAttackPos(vision, player.num("Kicker"), KickerShootPos, startPos, endPos, 130, 500)
    if attackPos:x() == 0 and attackPos:y() == 0 then
        if ball.posX() > CornerKickPosX then
            if ball.posY() < 0 then
                attackPos = CGeoPoint(3000, 850)
            else
                attackPos = CGeoPoint(3000, -850)
            end
        else
            attackPos = player.pos("Kicker")
        end
    end
    return attackPos
end
SpecialWaitPlacementPos = function()
    local startPos
    local endPos
    local SpecialShootPos = Utils.PosGetShootPoint(vision, player.posX("Special"), player.posY("Special"))
    if ball.posX() > CornerKickPosX then
        if ball.posY() < 0 then
            startPos = CGeoPoint(2400, -1100)
            endPos = CGeoPoint(2900, -700)
        else
            startPos = CGeoPoint(2400, 1100)
            endPos = CGeoPoint(2900, 700)
        end
    elseif ball.posX() < CornerKickPosX and ball.posX() > CenterKickPosX then
        if ball.posY() < 0 then
            startPos = CGeoPoint(3000, -750)
            endPos = CGeoPoint(3500, -1300)
        else
            startPos = CGeoPoint(3000, 750)
            endPos = CGeoPoint(3500, 1300)
        end
    else
        startPos = CGeoPoint(ball.posX() + 1000, 0)
        endPos = CGeoPoint(ball.posX() + 2500, -1700)
    end
    local attackPos = Utils.GetAttackPos(vision, player.num("Special"), SpecialShootPos, startPos, endPos, 130, 500)
    if attackPos:x() == 0 and attackPos:y() == 0 then
        if ball.posX() > CornerKickPosX then
            if ball.posY() > 0 then
                attackPos = CGeoPoint(3000, 850)
            else
                attackPos = CGeoPoint(3000, -850)
            end
        else
            attackPos = player.pos("Special")
        end
    end
    return attackPos
end
