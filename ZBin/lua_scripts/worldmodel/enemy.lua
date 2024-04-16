module(..., package.seeall)

function instance(role)
	if type(role) == "number" then
		return vision:theirPlayer(role)
	else
		print("Invalid role in enemy.instance!!!")
	end
end

function pos(role)
	return instance(role):Pos()
end

function posX(role)
	return instance(role):X()
end

function posY(role)
	return instance(role):Y()
end

function dir(role)
	return instance(role):Dir()
end

function vel(role)
	return instance(role):Vel()
end

function velDir(role)
	return vel(role):dir()
end

function velMod(role)
	return vel(role):mod()
end

function rotVel(role)
	return instance(role):RotVel()
end

function valid(role)
	return instance(role):Valid()
end

function toBallDist(role)
	return pos(role):dist(ball.pos())
end

function toBallDir(role)
	return (ball.pos() - pos(role)):dir()
end

function attackNum()
	return defenceInfo:getAttackNum()
end

function situChanged()
 	return defenceInfo:getTriggerState()
end
--need to modify
function isGoalie(role)
	if pos(role):dist(CGeoPoint:new_local(param.pitchLength / 2.0, 0)) < 85 then
		return true
	end
	return false
end
--need to modify
function isDefender(role)
	if pos(role):dist(CGeoPoint:new_local(param.pitchLength / 2.0, 0)) < 120 and not isGoalie(role) then
		return true
	end
	return false
end

function isMarking(role)
	if pos(role):dist() and not isDefender(role) then
		return true
	end
	return false
end

function isAttacker(role)
	if posX(role) < 0 and not isMarking(role) then
		return true
	end
	return false
end

function isBallFacer(role)
	if pos(role):dist(ball.pos()) < 60 then
		return true
	end
	return false
end

function hasReceiver()
	return CEnemyHasReceiver()
end

gEnemyMsg = {
	-- 门将的位置（包括消失处理）
	goaliePos = CGeoPoint:new_local(param.pitchLength/2.0,0)
}

function updateCorrectGoaliePos()
	local theirGoalieNum = skillUtils:getTheirGoalie()
	if enemy.valid(skillUtils:getTheirGoalie()) then
		gEnemyMsg.goaliePos = enemy.pos(theirGoalieNum)
	end
	return gEnemyMsg.goaliePos
end

function getTheirGoaliePos()
	return gEnemyMsg.goaliePos
end

function best()
	return skillUtils:getTheirBestPlayer()
end

function bestVelMod()
	return velMod(best())
end

function bestPos()
	return pos(best())
end

function bestDir()
	return dir(best())
end

function bestToBallDist()
	return pos(best()):dist(ball.pos())
end

function bestToBallDir()
	return (ball.pos() - pos(best())):dir()
end

function toPointDist(role, p)
	local pos
	if type(p) == "function" then
		pos = p()
	else
		pos = p
	end
	return enemy.pos(role):dist(pos)
end

function toOurGoalDist(role)
	return pos(role):dist(CGeoPoint:new_local(-param.pitchLength / 2.0, 0))
end

function nearest()
	local nearDist = 99999
	local nearNum = 0
	for i=1,6 do
		local theDist = enemy.pos(i):dist(ball.pos())
		if enemy.valid(i) and nearDist > theDist then
			nearDist = theDist
			nearNum = i
		end
	end
	return pos(nearNum), dir(nearNum)
end

function closestEnemy(en)
	local minDist = param.INF
	local enemyNum = -1
	for i=0, param.maxPlayer-1 do
		if i == en then
        elseif enemy.valid(i) and enemy.toPointDist(i, enemy.pos(en))<minDist then
        	minDist = enemy.toPointDist(i, enemy.pos(en))
        	enemyNum = i
        end
    end
    return enemyNum
end

function closestPoint(p)
	local minDist = param.INF
	local enemyNum = -1
	for i=0,param.maxPlayer do
        if enemy.valid(i) and enemy.toPointDist(i, p)<minDist then
        	minDist = enemy.toPointDist(i, p)
        	enemyNum = i
        end
    end
    return enemyNum
end

function closestBall()
	local minDist = param.INF
	local enemyNum = -1
	for i=0,param.maxPlayer do
        if enemy.valid(i) and enemy.toBallDist(i)<minDist then
        	minDist = enemy.toBallDist(i)
        	enemyNum = i
        end
    end
    return enemyNum
end

function closestGoal()
	local minDist = param.INF
	local enemyNum = -1
	for i=0,param.maxPlayer do
        if enemy.valid(i) and enemy.toOurGoalDist(i)<minDist then
        	minDist = enemy.toOurGoalDist(i)
        	enemyNum = i
        end
    end
    return enemyNum
end



function closestBallDist()
	local minDist = param.INF
	local enemyNum = -1
	for i=0,param.maxPlayer do
        if enemy.valid(i) and enemy.toBallDist(i)<minDist then
        	minDist = enemy.toBallDist(i)
        	enemyNum = i
        end
    end
    return minDist
end

function atBallLine()
	local minDist = param.INF
	local enemyNum = -1

	local ballPos = ball.rawPos()
	local ballVelDir = ball.velDir()
	for i=0, param.maxPlayer-1 do
        if enemy.valid(i) then
        	local enemyPos = CGeoPoint:new_local(enemy.posX(i), enemy.posY(i))
        	local enemyToBallDir = enemy.toBallDir(i)
        	-- 判断是否对齐
        	local diff = math.abs(math.pi - math.abs(enemyToBallDir - ballVelDir))
        	-- debugEngine:gui_debug_msg(CGeoPoint(-1500, 1000-(160*i)), "diff: "..diff)
        	-- debugEngine:gui_debug_msg(CGeoPoint(1500, 1500), "ballVel: "..ball.velMod())
        	if diff < param.alignRate and enemy.toBallDist(i)<minDist and ball.velMod() > 1000 then
	        	minDist = enemy.toBallDist(i)
	        	enemyNum = i
        	end
        end
    end
    return enemyNum
end