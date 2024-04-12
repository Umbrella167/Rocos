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
--射击力度
powerShoot = 3000
---------------------------------
--旋转参数
-- -- 顺时针
-- rotPos = CGeoPoint(150, -120)
-- rotVel = -5

-- 逆时针
rotPos = CGeoPoint(150,120)
rotVel = 5


---------------------------------


INF = 1e9
PI = 3.141592653589793238462643383279
maxPlayer   = 16
pitchLength = 9000
pitchWidth  = 6000
goalWidth = 1000
goalDepth = 200
freeKickAvoidBallDist = 500
playerRadius	= 90
penaltyWidth    = 2000
penaltyDepth	= 1000
penaltyRadius	= 1000
penaltySegment	= 500
playerFrontToCenter = 76
lengthRatio	= 1.5
widthRatio	= 1.5
stopRatio = 1.1
frameRate = 73
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