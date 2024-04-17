module(..., package.seeall)

-- maxPlayer   = 12
-- pitchLength = 600
-- pitchWidth  = 400
-- goalWidth = 70
-- goalDepth = 20
-- freeKickAvoidBallDist = 50
-- playerRadius	= 9
-- penaltyWidth    = 195
-- penaltyDepth	= 80
-- penaltyRadius	= 80
-- penaltySegment	= 35
-- playerFrontToCenter = 7.6
-- lengthRatio	= 1.5
-- widthRatio	= 1.5
-- stopRatio = 1.1
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

playerFrontToCenter = 76
lengthRatio	= 1.5
widthRatio	= 1.5
stopRatio = 1.1
frameRate = 73
---------------------------------
-- 射击力度
powerShoot = 300
powerTouch = 300
shootPos = CGeoPoint(6000,0)	
shootError = 10--1.8
shootKp = 0.01
---------------------------------
-- 旋转参数
-- rotPos = CGeoPoint(150,120)
rotPos = CGeoPoint(80,80)
rotVel = 3.8
rotCompensate = 0.005   --旋转补偿
---------------------------------
-- getball参数
playerVel = 2.5 	
-- [0[激进模式], 1[保守模式], 2[middle]]
getballMode = 2

---------------------------------
-- 固定匹配
defend_num1 = 1
defend_num2 = 2
our_goalie_num = 0
---------------------------------
-- lua 两点间有无敌人阈值
enemy_buffer = 100
---------------------------------
-- player params
playerRadius	= 90
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


goalieShootMode = function() return 2 end 	-- 1 flat  2 chip
defenderShootMode = function() return 2 end 	-- 1 flat  2 chip
-- goalieAimDirRadius = 9999
goalieBuf = 43
goalieAimDirRadius = pitchLength/4






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
BLACK=0
--~ -------------------------------------------
--~ used for getdata
--~ -------------------------------------------
FIT_PLAYER_POS_X = pitchLength/2 - penaltyDepth
FIT_PLAYER_POS_Y = pitchWidth/2 - 200