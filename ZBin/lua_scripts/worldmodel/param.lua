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
-- 射击力度
powerShoot = 300
powerTouch = 300
shootPos = CGeoPoint(0,0)
shootError = 3
shootKp = 1.2
---------------------------------
-- 旋转参数
rotPos = CGeoPoint(150,120)
rotVel = 3.8
---------------------------------
-- getball参数
playerVel = 1 	
-- [0[激进模式], 1[保守模式]]
getballMode = 1
---------------------------------
-- 固定匹配
defend_num1 = 1
defend_num2 = 2
our_goalie_num = 0
---------------------------------
-- lua 两点间有无敌人阈值
enemy_buffer = 150
---------------------------------
INF = 1e9
PI = 3.141592653589793238462643383279
maxPlayer   = 16

pitchLength = CGetSettings("field/width","Int")
pitchWidth  = CGetSettings("field/height","Int")
goalWidth = CGetSettings("field/goalWidth","Int")
goalDepth = CGetSettings("field/goalDepth","Int")
freeKickAvoidBallDist = 500
playerRadius	= 90

penaltyWidth    = CGetSettings("field/penaltyLength","Int")
penaltyDepth	= CGetSettings("field/penaltyWidth","Int")
penaltyRadius	= 1000
penaltySegment	= 500

playerFrontToCenter = 76
lengthRatio	= 1.5
widthRatio	= 1.5
stopRatio = 1.1
frameRate = 73

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