module(..., package.seeall)

---------------------------------
INF = 1e9
PI = 3.141592653589793238462643383279
maxPlayer   = 16
ballDiameter = 42
---------------------------------
-- feild params
pitchLength = CGetSettings("field/width","Int")
pitchWidth  = CGetSettings("field/height","Int")
goalWidth = CGetSettings("field/goalWidth","Int")
goalDepth = CGetSettings("field/goalDepth","Int")
ourGoalPos = CGeoPoint:new_local(-pitchLength/2, 0)
ourTopGoalPos = CGeoPoint:new_local(-pitchLength/2, goalWidth/2)
ourButtomGoalPos = CGeoPoint:new_local(-pitchLength/2, -goalWidth/2)
freeKickAvoidBallDist = 500
penaltyWidth    = CGetSettings("field/penaltyLength","Int")
penaltyDepth	= CGetSettings("field/penaltyWidth","Int")
-- penaltyRadius	= 1000  --?????????Is penaltyRadius ==  penaltyWidth/2 ???????????????
penaltyRadius = penaltyWidth/2
penaltySegment	= 500
ourTopRightPenaltyPos = CGeoPoint:new_local(-pitchLength/2+penaltyDepth, penaltyRadius)
ourTopPenaltyPos = CGeoPoint:new_local(-pitchLength/2, penaltyRadius)
ourButtomPenaltyPos = CGeoPoint:new_local(-pitchLength/2, -penaltyRadius)



---------------------------------

---------------------------------
playerFrontToCenter = 76
lengthRatio	= 1.5
widthRatio	= 1.5
stopRatio = 1.1
frameRate = 73
---------------------------------
-- 射击力度
powerShoot = 300
powerTouch = 300
shootPos = CGeoPoint(4500,0)	
shootError = 5--1.8
shootKp = 0.06
canTouchAngle = 45
---------------------------------
-- 旋转参数
-- rotPos = CGeoPoint(150,120)
rotPos = CGeoPoint(80,80)
rotVel = 3.8
rotCompensate = 0.05   --旋转补偿
---------------------------------
-- getball参数
playerVel = 2.8 	
-- [0[激进模式], 1[保守模式], 2[middle]]
getballMode = 2
-- 上一次算点结果
lastInterPos = CGeoPoint:new_local(-99999,-99999)
---------------------------------
-- 固定匹配
our_goalie_num = 0
defend_num1 =1
defend_num2 = 2
---------------------------------
-- lua 两点间有无敌人阈值
enemy_buffer = 90
---------------------------------
-- player params
playerRadius = 90
---------------------------------
-- defend marking
-- 球的X超过 markingThreshold 队友去盯防
markingThreshold = 1500 
minMarkingDist = playerRadius*3
markingPosRate1 = 1/6
markingPosRate2 = 1/10
-- defender
defenderBuf = playerRadius*3
defenderRadius = ourGoalPos:dist(ourTopRightPenaltyPos) + defenderBuf
defenderAimX = -pitchLength/4
-- goalie
goalieShootMode = function() return 1 end 	-- 1 flat  2 chip
defenderShootMode = function() return 1 end 	-- 1 flat  2 chip
goalieAimDirRadius = 9999
goalieBuf = 43
-- goalieAimDirRadius = pitchLength/4
--------------------------
-- 是否为真实场地
isReality = false 
-- 对齐的准确度
alignRate = 0.8
--~ -------------------------------------------
--~ used for debug
--~ -------------------------------------------
WHITE=0
RED=1
ORANGE=2
YELLOW=3
GREEN=4
CYAN=5
BLUE=6
PURPLE=7
GRAY=9
BLACK=10
--~ -------------------------------------------
--~ used for getdata
--~ -------------------------------------------
FIT_PLAYER_POS_X = pitchLength/2 - penaltyDepth
FIT_PLAYER_POS_Y = pitchWidth/2 - 200

--- 定位球配置
-- 前场判定位置
CornerKickPosX = 3000
CenterKickPosX = 0
KickerWaitPlacementPos = function()
    local startPos
    local endPos
    local KickerShootPos = Utils.PosGetShootPoint(vision, player.posX("Kicker"),player.posY("Kicker"))
    -- 角球
    if ball.posX() > CornerKickPosX then
        if ball.posY() > 0 then
            startPos = CGeoPoint(2600,-1250)
            endPos = CGeoPoint(3000,-850)
        else
            startPos = CGeoPoint(2600,1250)
            endPos = CGeoPoint(3000,850)
        end
    -- 中场球
    elseif ball.posX() < CornerKickPosX and ball.posX() > CenterKickPosX then
        if ball.posY() < 0 then 
            startPos = CGeoPoint(4050,1500)
            endPos = CGeoPoint(4400,800)
        else
            startPos = CGeoPoint(4050,-1500)
            endPos = CGeoPoint(4400,-800)
        end
    else
    -- 前场球
        startPos = CGeoPoint(ball.posX()+3000,1000)
        endPos = CGeoPoint(ball.posX()+4000,-1000)
    end
    local attackPos = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,startPos,endPos,130,500)
    if attackPos:x() == 0 and attackPos:y() == 0 then
        if ball.posX() > CornerKickPosX then
            if ball.posY() < 0 then
                attackPos = CGeoPoint(3000,850)
            else
                attackPos = CGeoPoint(3000,-850)
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
    local SpecialShootPos = Utils.PosGetShootPoint(vision, player.posX("Special"),player.posY("Special"))
    if ball.posX() > CornerKickPosX then
        if ball.posY() < 0 then
            startPos = CGeoPoint(2400,-1100)
            endPos = CGeoPoint(2900,-700)
        else
            startPos = CGeoPoint(2400,1100)
            endPos = CGeoPoint(2900,700)
        end
    elseif ball.posX() < CornerKickPosX and ball.posX() > CenterKickPosX then
        if ball.posY() < 0 then 
            startPos = CGeoPoint(3000,-750)
            endPos = CGeoPoint(3500,-1300)
        else
            startPos = CGeoPoint(3000,750)
            endPos = CGeoPoint(3500,1300)
        end
    else
        startPos = CGeoPoint(ball.posX()+1000,0)
        endPos = CGeoPoint(ball.posX()+2500,-1700)
    end
    local attackPos = Utils.GetAttackPos(vision, player.num("Special"),SpecialShootPos,startPos,endPos,130,500)
    if attackPos:x() == 0 and attackPos:y() == 0 then
        if ball.posX() > CornerKickPosX then
            if ball.posY() > 0 then
                attackPos = CGeoPoint(3000,850)
            else
                attackPos = CGeoPoint(3000,-850)
            end
        else
            attackPos = player.pos("Special")
        end
    end
    return attackPos
end