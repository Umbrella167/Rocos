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
rotPos = CGeoPoint:new_local(0,0)
rotVel = 5
---------------------------------


INF = 1e9
PI = 3.141592653589793238462643383279
maxPlayer   = 16
pitchLength = 12000
pitchWidth  = 9000
goalWidth = 1000
goalDepth = 200
freeKickAvoidBallDist = 500
playerRadius	= 90
penaltyWidth    = 3600
penaltyDepth	= 1800
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
