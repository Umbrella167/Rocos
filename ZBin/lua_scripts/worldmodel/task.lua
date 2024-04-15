module(..., package.seeall)

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---



-- 解决截球算点抖动问题
lastMovePoint = CGeoPoint:new_local(param.INF, param.INF)
function stabilizePoint(p)
	if lastMovePoint:dist(p) < 50 then
		return lastMovePoint
	end
	lastMovePoint = p
	return p
end

-- 快速移动
function endVelController(role, p)
	local endvel = Utils.Polar2Vector(-50,(player.pos(role) - p):dir())
	if player.toPointDist(role, p) > param.playerRadius*2 then
		endvel = Utils.Polar2Vector(-1200,(player.pos(role) - p):dir())
	end
	return endvel
end

-- function angleSub(angle1,angle2,dir)
-- 	-- angle1 :dir1
-- 	-- angle2 :dir2
-- 	-- dir    :[0,1]  0：同向计算 1：反向计算 
-- 	local dir_ = dir:0
-- 	local dir1 = math.abs(dir1) * 57.3
-- 	local dir2 = math.abs(dir2) * 57.3
-- 	local dirsub = math.abs(180 - dir2 - dir1)
-- 	return dirsub
-- end

function TurnRun(pos,vel)
	local ipos = pos or  CGeoPoint:new_local(0,80)  --自身相对坐标 旋转
	local ivel = vel -- 旋转速度 -+ 改变方向
	local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
	return { mexe, mpos }
end


function getball(role, playerVel, inter_flag, target_point)
	return function()
		local p1
		if type(target_point) == 'function' then
			p1 = target_point()
		else
			p1 = target_point
		end
		if player.infraredCount(role) < 5 then
			local qflag = inter_flag or 0
			local playerPos = CGeoPoint:new_local( player.pos(role):x(),player.pos(role):y())
			local inter_pos = stabilizePoint(Utils.GetBestInterPos(vision,playerPos,playerVel,qflag))
			
			local idir = player.toBallDir(role)
			local ipos = ball.pos()
			if inter_pos:x()  ==  param.INF or inter_pos:y()  == param.INF then
				ipos = ball.pos()
			else
				ipos = inter_pos
			end
			
			-- local toballDir = math.abs(player.toBallDir(role))  * 57.3
			local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
			local playerDir = math.abs(player.dir(role)) * 57.3
			local Subdir = math.abs(toballDir-playerDir)
			local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
			if Subdir > 20 then 
				local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
				iflag =  DSS_FLAG
			else
				iflag = flag.dribbling
			end
			ipos = CGeoPoint:new_local(ipos:x(),ipos:y())
			ipos = stabilizePoint(ipos)
			local endvel = Utils.Polar2Vector(300,(ipos - player.pos(role)):dir())
			local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = iflag, rec = r, vel = endvel }
				return { mexe, mpos }
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local iflag = flag.dribbling
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = iflag, rec = 1, vel = v }
			return { mexe, mpos }
		end
	end
end



function getballV2(role, playerVel, inter_flag, target_point)
	return function()
		local p1
		if type(target_point) == 'function' then
			p1 = target_point()
		else
			p1 = target_point
		end
		if player.infraredCount(role) < 5 then
			local qflag = inter_flag or 0
			local playerPos = CGeoPoint:new_local( player.pos(role):x(),player.pos(role):y())
			local inter_pos = stabilizePoint(Utils.GetBestInterPos(vision,playerPos,playerVel,qflag))
			
			local idir = player.toBallDir(role)
			local ipos = ball.pos()
			if inter_pos:x()  ==  param.INF or inter_pos:y()  == param.INF then
				ipos = ball.pos()
			else
				ipos = inter_pos
			end
			
			-- local toballDir = math.abs(player.toBallDir(role))  * 57.3
			local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
			local playerDir = math.abs(player.dir(role)) * 57.3
			local Subdir = math.abs(toballDir-playerDir)
			local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
			if Subdir > 20 then 
				  --自身相对坐标 旋转
				
				local mexe, mpos = CircleRun {pos = CGeoPoint:new_local(0,80) , vel = 5}
				return { mexe, mpos }
			else
				iflag = flag.dribbling
			end
			ipos = CGeoPoint:new_local(ipos:x(),ipos:y())
			ipos = stabilizePoint(ipos)
			local endvel = Utils.Polar2Vector(300,(ipos - player.pos(role)):dir())
			local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = iflag, rec = r, vel = endvel }
				return { mexe, mpos }
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local iflag = flag.dribbling
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = iflag, rec = 1, vel = v }
			return { mexe, mpos }
		end
	end
end
function power(p, Kp) --根据目标点与球之间的距离求出合适的 击球力度 kp系数需要调节   By Umbrella 2022 06
	return function()
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local res = Kp * (p1 - ball.pos()):mod()
		-- if res > 310 then
		-- 	res = 310
		-- end
		-- if res < 230 then
		-- 	res = 230
		-- end
		if res > 6000 then
			res = 6000
		end
		if res < 3500 then
			res = 3500
		end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,3200),"Power" .. res,3)
		return res
	end
end

function GetBallV2(role, p, dist1, speed1) -------dist开始减速的距离   speed减速的速度
	--参数说明
	--role  使用这个函数的角色
	--p	    拿到球后指向的目标点
	--dist  距离球dist mm时开始减速
	--speed 减速后的速度 （范围 0～2500）			
	return function()
		local dist = dist1 or 0
		local speed = speed1 or 0
		local minDist = 9999999
		local longDist = 0
		local ballspeed = 800

		local p1 = p
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		if (player.infraredCount(role) < 20) then
			if ((player.pos(role) - ball.pos()):mod() < dist) then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(0, idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(longDist, idir)
				end
				local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = speed, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			else
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-1 * dist + 10, idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(longDist, idir)
				end
				local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			end
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
			return { mexe, mpos }
		end
	end
end


function TurnToPoint(role, p, speed)
	--参数说明
	-- role 	 使用这个函数的角色
	-- p	     指向坐标
	-- speed	 旋转速度
	return function()
		local p1 = p
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		if speed == nil then
			speed = 800
		end
		local playerPos = player.pos(role)
		local playerDir = player.dir(role)
		local playerToBallDist = player.toBallDist(role)
		local playerToBallDir = (ball.pos() - player.pos(role)):dir()
		local playerToTargetDir = (p1 - player.pos(role)):dir()
		local ballPos = CGeoPoint:new_local (ball.posX(),ball.posY())
		local ballToTargetDir = (p1 - ball.pos()):dir()
		local subPlayerBallToTargetDir = playerToTargetDir - ballToTargetDir
		-- Debug
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*0), string.format("playerDir:         	   %6.3f", playerDir),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*1), string.format("playerToBallDir:         %6.3f", playerToBallDir),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*2), string.format("playerToTargetDir:       %6.3f", playerToTargetDir),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*3), math.abs(playerDir-playerToTargetDir)*57.3)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*4), string.format("playerToBallDist:       %6.3f", playerToBallDist),param.BLUE)
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 1000+150*5), string.format("sub:       %6.3f", ballToTargetDir-playerToTargetDir),param.BLUE)
		-- debugEngine:gui_debug_x(p)
    	
		-- 逆时针旋转
		local idirLeft = (playerDir+param.PI/2)>param.PI and playerDir-(3/2)*param.PI or playerDir+param.PI/2 
		-- 顺时针旋转
		local idirRight = (playerDir-param.PI/2)>param.PI and playerDir+(3/2)*param.PI or playerDir-param.PI/2

		-- if math.abs(playerDir-playerToTargetDir) > 0.14 or math.abs(playerDir-playerToBallDir) > 0.40 then
		if math.abs(playerDir-playerToTargetDir) > 0.14 then
			if subPlayerBallToTargetDir > 0 then
				-- 逆时针旋转
				debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "0")
				local target_pos = playerPos+Utils.Polar2Vector(speed, idirLeft)+Utils.Polar2Vector(2*playerToBallDist, playerToBallDir)
				debugEngine:gui_debug_x(target_pos)
				local mexe, mpos = GoCmuRush { pos = target_pos, dir = playerToBallDir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			end
			-- 顺时针旋转
			debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "1")
			local target_pos = playerPos+Utils.Polar2Vector(speed, idirRight)+Utils.Polar2Vector(2*playerToBallDist, playerToBallDir)
			debugEngine:gui_debug_x(target_pos)
			local mexe, mpos = GoCmuRush { pos = target_pos, dir = playerToBallDir, acc = a, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
		-- else
		elseif playerToBallDist > 1 then
			debugEngine:gui_debug_msg(CGeoPoint:new_local(1000, 1000), "2")
			local mexe, mpos = GoCmuRush { pos = ballPos, dir = playerToTargetDir, acc = a, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
			return { mexe, mpos }  

		end
	end
end

function TurnToPointV2(role, p, speed)
	--参数说明
	-- role 	 使用这个函数的角色
	-- p	     指向坐标
	-- speed	 旋转速度

		local p1 = p
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		if speed == nil then
			speed = param.rotVel
		end

		-- local playerDir = player.dir(role)
		-- local playerToTargetDir = (p1 - player.pos(role)):dir() * 57.3
		-- local ballToTargetDir = (p1 - ball.pos()):dir() * 57.3
		-- local subPlayerBallToTargetDir = playerToTargetDir - ballToTargetDir
			local toballDir = (p1 - player.rawPos(role)):dir() * 57.3
			local playerDir = player.dir(role) * 57.3
			local subPlayerBallToTargetDir = toballDir - playerDir 
			-- local Subdir = math.abs(toballDir-playerDir)
			debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,220),math.abs(toballDir-playerDir) .. "                     " .. subPlayerBallToTargetDir,3)
		if math.abs(toballDir-playerDir) > 4 then
			if subPlayerBallToTargetDir < 0 then
				-- 顺时针旋转
				-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "顺时针")
				local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
				local ivel = speed * -1
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			else
				-- 逆时针旋转
				-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "逆时针")
				local ipos = param.rotPos  --自身相对坐标 旋转
				local ivel = speed
				local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
				return { mexe, mpos }
			end
		else
			local idir = (ball.pos() - player.pos(role)):dir()
			local pp = ball.pos() + Utils.Polar2Vector(50, idir)
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
			return { mexe, mpos }  
			
		end

		-- NOTE: 这里两个if都不成立时没有写额外的操作，需要自行判断退出
end

function ShootdotV2(p, Kp, error_, flag)
	return function()
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local shootpos = function(runner)
			return ball.pos() + Utils.Polar2Vector(-50, (p1 - ball.pos()):dir())
		end
		local idir = function(runner)
			return (p1 - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end

		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
		return { mexe, mpos, flag, idir, error__, power(p, Kp), power(p, Kp), 0x00000000 }
	end
end
function Shootdot(role,p, Kp, error_, flagShoot) --
	return function(runner)
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local shootpos = ball.pos() + Utils.Polar2Vector(-50, (p1 - ball.pos()):dir())
		local idir = function()
			return (p1 - player.pos(role)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
		local endvel = Utils.Polar2Vector(300,player.toBallDir(role))
		-- local toballDir = math.abs(player.toBallDir(role))  * 57.3
		local toballDir = math.abs((ball.rawPos() - player.rawPos(role)):dir() * 57.3)
		local playerDir = math.abs(player.dir(role)) * 57.3
		local Subdir = math.abs(toballDir-playerDir)
		local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
		if Subdir > 5 then 
			local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
			iflag =  DSS_FLAG
			shootpos = ball.pos() + Utils.Polar2Vector(-300, (p1 - ball.pos()):dir())

		else
			iflag = flag.dribbling
		end
		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
		return { mexe, mpos, flagShoot, idir, error__, power(p, Kp), power(p, Kp), 0x00000000 }
	end
end


function playerDirToPointDirSub(role, p) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end

	local playerDir = player.dir(role) * 57.3 + 180
	local playerPointDit = (p1 - player.rawPos(role)):dir() * 57.3 + 180
	local sub = math.abs(playerDir - playerPointDit)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -4000),  "AngleError".. sub)
	return sub
end

function pointToPointAngleSub(p, p2) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end
	local dir_pass = (ball.pos() - p2):dir() * 57.3 + 180
	local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	if sub > 300 then
		sub = 360 - sub
	end
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000, 0), sub)
	return sub
end

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---



--~		Play中统一处理的参数（主要是开射门）
--~		1 ---> task, 2 ---> matchpos, 3---->kick, 4 ---->dir,
--~		5 ---->pre,  6 ---->kp,       7---->cp,   8 ---->flag
------------------------------------- 射门相关的skill ---------------------------------------
-- TODO
------------------------------------ 跑位相关的skill ---------------------------------------
--~ p为要走的点,d默认为射门朝向


-- flag 防守模式选择, 0在球射向球门时选择防守线(x=-param.pitchLength/2-param.playerRadius)上的点, 1在球射向球门使用bestinterpos的点
function goalie(role, flag)
	return function()
		if flag==nil then
			flag = 1
		end
		local goalRadius = param.penaltyRadius
		-- 禁区半径
		local penaltyRadius = param.penaltyWidth/2
		local goalPos = CGeoPoint:new_local(-param.pitchLength/2, 0) 
		local rolePos = CGeoPoint:new_local(player.posX(role), player.posY(role))
		local goalieRadius = goalRadius-100
		local closestBallEnemyNum = enemy.closestBall()
		local enemyNum = closestBallEnemyNum
		local ballPos = ball.rawPos()
		local ballVelDir = ball.velDir()
		local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(9999, ballVelDir))
		-- 找到需要盯防的人 --enemyNum
		if enemy.toBallDist(closestBallEnemyNum) > 100 and enemy.atBallLine() ~= -1 then
			enemyNum = enemy.atBallLine()
		end
		local enemyDir = enemy.dir(enemyNum)
		local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
		local enemyDirLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(9999, enemyDir))
		debugEngine:gui_debug_msg(CGeoPoint(0, 0), enemyNum)
		debugEngine:gui_debug_x(enemyPos)
		local goalToEnemyDir = (enemyPos - goalPos):dir()
		local goalToEnemyLine = CGeoSegment(goalPos, enemyPos)
		local goalLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2, -9999), CGeoPoint:new_local(-param.pitchLength/2, 9999))
		local goalieMoveLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, -9999), CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, 9999))
		local tPos = goalLine:segmentsIntersectPoint(ballLine)
		-- 判断是否踢向球门
		local isShooting = -penaltyRadius-100<tPos:y() and tPos:y()<penaltyRadius+100
		local getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		if flag == 0 then
			getBallPos = goalieMoveLine:segmentsIntersectPoint(ballLine)
		elseif flag == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		end

		if ball.velMod() < 1000 and flag == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		end
		debugEngine:gui_debug_x(getBallPos, param.WHITE)

		-- 守门员需要踢向哪个点
		local targetPos = ball.rawPos() --改了可能会出bug
		-- if (isShooting or ball.velMod() < 1000) and Utils.InExclusionZone(getBallPos) then
		if isShooting and Utils.InExclusionZone(getBallPos) then
			-- 当敌方射门的时候或球滚到禁区内停止时
			local kp = 1
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
			local idir = function(runner)
				return (targetPos - player.pos(runner)):dir()
			end
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos, kick.flat, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
		elseif ball.velMod() < 1000 and Utils.InExclusionZone(getBallPos) then
			-- 球滚到禁区内停止
			local kp = 1
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
			local idir = function(runner)
				return (targetPos - player.pos(runner)):dir()
			end
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos, kick.flat, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
		else
			-- 准备状态
			-- 这里是当球没有朝球门飞过来的时候，需要提前到达的跑位点
			local roleToEnemyDist = (enemyPos-rolePos):mod()
			local goaliePoint = goalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			-- local goaliePoint = goalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			if flag==0 then
				goaliePoint = goalieMoveLine:segmentsIntersectPoint(goalToEnemyLine)
			elseif flag==1 then
				goaliePoint = goalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			end
			if roleToEnemyDist<2500 then
				-- 近处需要考虑敌人朝向的问题
				local enemyAimLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(9999, enemyDir))
				local tPos = goalLine:segmentsIntersectPoint(enemyAimLine)
				-- 判断是否朝向球门
				local isToGoal = -param.penaltySegment-200<tPos:y() and tPos:y()<param.penaltySegment+200

				if isToGoal then
					local tP = tPos+Utils.Polar2Vector(-goalieRadius, enemyDir)
					if flag==0 then
						tP = goalieMoveLine:segmentsIntersectPoint(enemyDirLine)
					elseif flag==1 then
						tP = tPos+Utils.Polar2Vector(-goalieRadius, enemyDir)
					end
					-- goaliePoint = tP
					goaliePoint = CGeoPoint:new_local((tP:x()+goaliePoint:x())/2, (tP:y()+goaliePoint:y())/2)
				end
				debugEngine:gui_debug_x(goaliePoint)
			end
			local idir = player.toPointDir(enemyPos, role)
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos }
		end
	end
end

function touch()
	local ipos = pos.ourGoal()
	local mexe, mpos = Touch { pos = ipos }
	return { mexe, mpos }
end

function touchKick(p, ifInter, power, mode)
	local ipos = p or pos.theirGoal()
	local idir = function(runner)
		return (_c(ipos) - player.pos(runner)):dir()
	end
	local mexe, mpos = Touch { pos = ipos, useInter = ifInter }
	local ipower = function()
		return power or 127
	end
	return { mexe, mpos, mode and kick.flat or kick.chip, idir, pre.low, ipower, cp.full, flag.nothing }
end

function goSpeciPos(p, d, f, a) -- 2014-03-26 增加a(加速度参数)
	local idir
	local iflag
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end

	if f ~= nil then
		iflag = f
	else
		iflag = 0
	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = iflag }
	return { mexe, mpos }
end

function goSimplePos(p, d, f)
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end

	if f ~= nil then
		iflag = f
	else
		iflag = 0
	end

	local mexe, mpos = SimpleGoto { pos = p, dir = idir, flag = iflag }
	return { mexe, mpos }
end

function runMultiPos(p, c, d, idir, a, f)
	if c == nil then
		c = false
	end

	if d == nil then
		d = 20
	end

	if idir == nil then
		idir = dir.shoot()
	end

	local mexe, mpos = RunMultiPos { pos = p, close = c, dir = idir, flag = f, dist = d, acc = a }
	return { mexe, mpos }
end

function staticGetBall(target_pos, dist)
	local idist = dist or 140
	local p = function()
		local target = _c(target_pos) or pos.theirGoal()
		return ball.pos() + Utils.Polar2Vector(idist, (ball.pos() - target):dir())
	end
	local idir = function()
		local target = _c(target_pos) or pos.theirGoal()
		return (target - ball.pos()):dir()
	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, flag = flag.dodge_ball }
	return { mexe, mpos }
end

function goCmuRush(p, d, a, f, r, v, s, force_manual)
	-- p : CGeoPoint, pos
	-- d : double, dir
	-- a : double, max_acc
	-- f : int, flag
	-- v : CVector, target_vel
	-- s : double, max_speed
	-- force_manual : bool, force_manual
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
	return { mexe, mpos }
end

function forcekick(p, d, chip, power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
	return { mexe, mpos, ikick, idir, pre.low, kp.specified(ipower), cp.full, flag.forcekick }
end

function shoot(p, d, chip, power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local iflag = 0x00000000
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
	return { mexe, mpos, ikick, idir, pre.low, kp.specified(8000), cp.full, iflag }
end

------------------------------------ 防守相关的skill ---------------------------------------
-- Defender

-- 获得拥有球或者球将会传到的敌人
function getManMarkEnemy()
	local closestBallEnemyNum = enemy.closestBall()
	local enemyNum = closestBallEnemyNum
	-- 找到需要盯防的人 --enemyNum
	if enemy.toBallDist(closestBallEnemyNum) > 100 and enemy.atBallLine() ~= -1 then
		enemyNum = enemy.atBallLine()
	end
	-- debug
	-- debugEngine:gui_debug_msg(CGeoPoint(0, 0), enemyNum)
	local enemyPos = enemy.pos(enemyNum)
	debugEngine:gui_debug_x(enemyPos, param.BLUE)
	return enemyNum
end

goalPos = CGeoPoint:new_local(-param.pitchLength/2, 0)
topGoalPos = CGeoPoint:new_local(-param.pitchLength/2, param.goalWidth/2)
buttomGoalPos = CGeoPoint:new_local(-param.pitchLength/2, -param.goalWidth/2)
topPenaltyPos = CGeoPoint:new_local(-param.pitchLength/2, param.penaltyRadius)
buttomPenaltyPos = CGeoPoint:new_local(-param.pitchLength/2, -param.penaltyRadius)
penaltyRadius = param.penaltyWidth/2
defender_playerLen = 0

-- 获取需要去挡人的车
function isActiveDefender(role)
	defender_playerLen = 0
	local minRoleToEnemyDist = param.INF
	local roleNum = -1
	local enemyNum = getManMarkEnemy()
	local enemyPos = enemy.pos(enemyNum)

	for i=0, param.maxPlayer-1 do
		local playerName = player.name(i)
		if player.valid(i) and (playerName == "Tier" or playerName == "Defender") then
			defender_playerLen = defender_playerLen + 1
			-- 选取离敌人最近的车为activeDefender
			-- debugEngine:gui_debug_msg(CGeoPoint(-2000, 1000+(150*i)), playerName.."  "..tostring(player.toPointDist(playerName, enemyPos)))
			if player.toPointDist(playerName, enemyPos) < minRoleToEnemyDist then
				minRoleToEnemyDist = player.toPointDist(playerName, enemyPos)
				roleNum = i
			end
        end
	end
	return player.num(role)==roleNum and true or false
end

-- 获取离某点最近的defender
function isCloestDefender(role, p)
	defender_playerLen = 0
	local minRoleToEnemyDist = param.INF
	local roleNum = -1

	for i=0, param.maxPlayer-1 do
		local playerName = player.name(i)
		if player.valid(i) and (playerName == "Tier" or playerName == "Defender") then
			-- 选取离敌人最近的车为activeDefender
			-- debugEngine:gui_debug_msg(CGeoPoint(-2000, 1000+(150*i)), playerName.."  "..tostring(player.toPointDist(playerName, enemyPos)))
			if player.toPointDist(playerName, p) < minRoleToEnemyDist then
				minRoleToEnemyDist = player.toPointDist(playerName, p)
				roleNum = i
			end
        end
	end

	return player.num(role)==roleNum and true or false
end

-- 后卫skill
function defender(role)
	return function()
		
		local ballPos = CGeoPoint:new_local(ball.rawPos():x(), ball.rawPos():y())
		local ballVelDir = ball.velDir()
		local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ballVelDir))


		local enemyNum = getManMarkEnemy()
		local enemyPos = enemy.pos(enemyNum)
		local enemyToGoalDir = (enemy.pos(enemyNum) - goalPos):dir()
		local playerToEnemyDir = function(runner)
			return (enemyPos - player.pos(runner)):dir()
		end

		local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
		local getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 0))
		local isGetBallDefender = isCloestDefender(role, getBallPos)
		
		debugEngine:gui_debug_msg(getBallPos, role, isGetBallDefender and param.CYAN or param.RED)

		local isActiveDefender = isActiveDefender(role)

		-- local defender_AimLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2, -param.INF), CGeoPoint:new_local(-param.pitchLength/2, param.INF))
		local defender_readyLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/4, -param.INF), CGeoPoint:new_local(-param.pitchLength/4, param.INF))
		local defender_defendLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/3, -param.INF), CGeoPoint:new_local(-param.pitchLength/3, param.INF))
		if isActiveDefender then
			debugEngine:gui_debug_x(player.pos(role), param.YELLOW)
		end


		local tPos = defender_readyLine:segmentsIntersectPoint(ballLine)
			-- -- 判断是否踢向我方
		local isShooting = -penaltyRadius-100<tPos:y() and tPos:y()<penaltyRadius+100
		debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), tostring(isShooting))

		if Utils.InOurField(ballPos) then
			-- 当球在我方半场的时候去做相应的防守
			debugEngine:gui_debug_msg(player.pos(role), role, isActiveDefender and param.YELLOW or param.RED )

			-- local tPos = defender_readyLine:segmentsIntersectPoint(ballLine)
			-- -- -- 判断是否踢向我方
			-- local isShooting = -penaltyRadius-100<tPos:y() and tPos:y()<penaltyRadius+100

			local enemyToGoalLine = CGeoSegment(goalPos, enemyPos)
			local defenderPoint = defender_defendLine:segmentsIntersectPoint(enemyToGoalLine)
			-- if defender_playerLen>=2 then
			-- 	if isActiveDefender then
			-- 		local enemyToTopPenaltyLine = CGeoSegment(topPenaltyPos, enemyPos)
			-- 		defenderPoint = defender_defendLine:segmentsIntersectPoint(enemyToTopPenaltyLine)
			-- 	else
			-- 		local enemyToButtomPenaltyLine = CGeoSegment(buttomPenaltyPos, enemyPos)
			-- 		defenderPoint = defender_defendLine:segmentsIntersectPoint(enemyToButtomPenaltyLine)
			-- 	end
			-- end

			if isActiveDefender then
				defenderPoint = enemyPos + Utils.Polar2Vector(param.playerRadius*2, enemyToGoalDir)

			else

			end


			if isShooting and isGetBallDefender then
				defenderPoint = getBallPos
			end


			local idir = player.toPointDir(enemyPos, role)
			local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, defenderPoint) }
			return { mexe, mpos }
		else
			-- 当球在敌方半场时
			local enemyToGoalLine = CGeoSegment(goalPos, enemyPos)
			local defenderPoint = defender_readyLine:segmentsIntersectPoint(enemyToGoalLine)

			if defender_playerLen>=2 then
				if role == "Tier" then
					local enemyToTopPenaltyLine = CGeoSegment(topPenaltyPos, enemyPos)
					defenderPoint = defender_readyLine:segmentsIntersectPoint(enemyToTopPenaltyLine)
				else
					local enemyToButtomPenaltyLine = CGeoSegment(buttomPenaltyPos, enemyPos)
					defenderPoint = defender_readyLine:segmentsIntersectPoint(enemyToButtomPenaltyLine)
				end
			end
			



			if isShooting and isGetBallDefender then
				defenderPoint = getBallPos
			end

			debugEngine:gui_debug_msg(defenderPoint, role, isActiveDefender and param.YELLOW or param.RED )
			-- debugEngine:gui_debug_x(defenderPoint, param.WHITE)
			-- debugEngine:gui_debug_line(enemyPos, topPenaltyPos)
			-- debugEngine:gui_debug_line(enemyPos, buttomPenaltyPos)
			local idir = player.toPointDir(enemyPos, role)
			local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, defenderPoint) }
			return { mexe, mpos }
		end
	end
end


-- 守门员skill
-- flag 防守模式选择, 0在球射向球门时选择防守线(x=-param.pitchLength/2-param.playerRadius)上的点, 1在球射向球门使用bestinterpos的点
function goalie(role, flag)
	return function()
		if flag==nil then
			flag = 1
		end
		local goalRadius = param.penaltyRadius/2
		local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
		local goalieRadius = goalRadius-100
		
		local ballPos = ball.rawPos()
		local ballVelDir = ball.velDir()
		local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ballVelDir))
		local enemyNum = getManMarkEnemy()
		local enemyDir = enemy.dir(enemyNum)
		local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
		local enemyDirLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
		
		local goalToEnemyDir = (enemyPos - goalPos):dir()
		local goalToEnemyLine = CGeoSegment(goalPos, enemyPos)
		local goalLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2, -param.INF), CGeoPoint:new_local(-param.pitchLength/2, param.INF))
		local goalieMoveLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, -param.INF), CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, param.INF))
		local tPos = goalLine:segmentsIntersectPoint(ballLine)
		-- 判断是否踢向球门
		local isShooting = -penaltyRadius-100<tPos:y() and tPos:y()<penaltyRadius+100
		local getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		if flag == 0 then
			getBallPos = goalieMoveLine:segmentsIntersectPoint(ballLine)
		elseif flag == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		end

		if ball.velMod() < 1000 and flag == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1))
		end
		debugEngine:gui_debug_x(getBallPos, param.WHITE)

		-- 守门员需要踢向哪个点
		local targetPos = ball.rawPos() --改了可能会出bug
		-- if (isShooting or ball.velMod() < 1000) and Utils.InExclusionZone(getBallPos) then
		if isShooting and Utils.InExclusionZone(getBallPos) then
			-- 当敌方射门的时候或球滚到禁区内停止时
			local kp = 1
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
			local idir = function(runner)
				return (targetPos - player.pos(runner)):dir()
			end
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos, kick.chip, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
		elseif ball.velMod() < 1000 and Utils.InExclusionZone(getBallPos) then
			-- 球滚到禁区内停止
			local kp = 1
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
			local idir = function(runner)
				return (targetPos - player.pos(runner)):dir()
			end
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos, kick.chip, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
		else
			-- 准备状态
			-- 这里是当球没有朝球门飞过来的时候，需要提前到达的跑位点
			local roleToEnemyDist = (enemyPos-rolePos):mod()
			local goaliePoint = goalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			-- local goaliePoint = goalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			if flag==0 then
				goaliePoint = goalieMoveLine:segmentsIntersectPoint(goalToEnemyLine)
			elseif flag==1 then
				goaliePoint = goalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			end
			if roleToEnemyDist<2500 then
				-- 近处需要考虑敌人朝向的问题
				local enemyAimLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
				local tPos = goalLine:segmentsIntersectPoint(enemyAimLine)
				-- 判断是否朝向球门
				local isToGoal = -param.penaltySegment-200<tPos:y() and tPos:y()<param.penaltySegment+200

				if isToGoal then
					local tP = tPos+Utils.Polar2Vector(-goalieRadius, enemyDir)
					if flag==0 then
						tP = goalieMoveLine:segmentsIntersectPoint(enemyDirLine)
					elseif flag==1 then
						tP = tPos+Utils.Polar2Vector(-goalieRadius, enemyDir)
					end
					-- goaliePoint = tP
					goaliePoint = CGeoPoint:new_local((tP:x()+goaliePoint:x())/2, (tP:y()+goaliePoint:y())/2)
				end
				debugEngine:gui_debug_x(goaliePoint)
			end
			local idir = player.toPointDir(enemyPos, role)
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos }
		end
	end
end



--[[ 盯防 ]]
function defender_marking(role)
	return function()
		
	end
end

--[[ 防守 ]]
function defender_defence(role)
	return function()

		local mexe, mpos = nil, nil
		local ipos, idir = "Defender" == role and DEFENDER_INITPOS_DEFENDER or DEFENDER_INITPOS_TIER,
			player.toBallDir(role)

		local ROLE_DEFENDER = "Defender"
		local ROLE_TIER = "Tier"
		local role_major = player.toBallDist(ROLE_DEFENDER) < player.toBallDist(ROLE_TIER) and ROLE_DEFENDER
			or ROLE_TIER -- defender
		local role_minor = role_major == ROLE_DEFENDER and ROLE_TIER
			or ROLE_DEFENDER -- tier

		role = player.name(role)

		if player.toBallDist(role) < DEFENDER_SAFEDISTANCE / 2 or ball.pos():x() < -param.pitchLength / 2 + param.penaltyDepth then -- 可抢球机会
			if role == role_major then
				local ipos = pos.theirGoal()
				-- NOTE: 会有更好的解决办法防止卡禁区 2/2
				local idir = function(runner) return (_c(ipos) - player.pos(runner)):dir() end
				-- if ball.pos():x() < -param.pitchLength / 2 + param.penaltyDepth then idir = 0 end -- FIXME: idir=0的时候会报错，但是可能会卡禁区
				local mexe, mpos = Touch { pos = ipos, useInter = ifInter }
				local ipower = function()
					return power or 127
				end
				return { mexe, mpos, mode and kick.flat or kick.chip, idir, pre.low, ipower, cp.full, flag.nothing }
			end
		elseif player.toBallDist(role) < DEFENDER_SAFEDISTANCE * 2 then -- 准备防御
			-- local distanceDT = Utils.DEFENDER_ComputeDistance(hitPoint)
			local line = CGeoLine:new_local(ball.pos(), ball.velDir()) -- 球的朝向
			local hitPoint = Utils.DEFENDER_ComputeCrossPenalty(vision, line) -- 可能的射击朝向与禁区线的预测点
			local POS_NULL = CGeoPoint:new_local(0, 0)

			-- -- FIXME: 如果球权不在自己手上，提前朝向对面瞄准位置，现在不瞄准了，甚至还会跑路
			-- if GlobalMessage.Tick.ball.rights ~= 1 then --如果球权不在自己手上
			-- 	local theirAttacker = Utils.closestPlayerNoToPoint(vision,
			-- 		CGeoPoint:new_local(ball.posX(), ball.posY()), 2) -- 获取离球最近的敌人

			-- 	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(DEFENDER_DEBUG_POSITION_X, DEFENDER_DEBUG_POSITION_Y),
			-- 	-- type(ball.pos()))

			-- 	line = CGeoLine:new_local(player.pos(theirAttacker), player.dir(theirAttacker))
			-- 	hitPoint = Utils.DEFENDER_ComputeCrossPenalty(vision, line)
			-- end

			if hitPoint ~= POS_NULL then -- 有防御交点
				if role == role_major then
					ipos = hitPoint
				elseif role == role_minor then
					local closestEnemy = -- 最近的敌人位置，但是排除了守门员
						Utils.closestPlayerToPoint(vision,
							role_minor == ROLE_DEFENDER and DEFENDER_INITPOS_DEFENDER or DEFENDER_INITPOS_TIER, 2,
							player.num(role))

					if nil ~= closestEnemy then                                          -- 如果检测到有可能有敌人出现，那么需要回防
						if player.toPointDist(role, closestEnemy) < DEFENDER_SAFEDISTANCE then -- 并且可能产生威胁 NOTE: 可以继续升级算法
							ipos = closestEnemy +
								Utils.Polar2Vector(DEFENDER_SAFEDISTANCE / 4, (ball.pos() - closestEnemy):dir()) -- 盯防一波
						else                                                             -- 不然就跟着 role_major
							ipos = CGeoPoint:new_local(player.pos(role_major):x(),
								player.pos(role_major):y() + (role == ROLE_TIER and -DEFENDER_DEFAULT_DISTANCE_MIN
									or DEFENDER_DEFAULT_DISTANCE_MIN))
						end
					end
				end
			end

			mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
			return { mexe, mpos }
			-- end
		else
			-- NOTE: 可以更加智能一些
			mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
			return { mexe, mpos }
		end
	end
end



function Dfenending( role )
	local ballPos = CGeoPoint(ball.posX(),ball.posY())
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end
	-- 球在后场
	if( ballPos:x() < 0) then



	-- 球在前场
	else

	end
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
	return { mexe, mpos }
end
----------------------------------------- 其他动作 --------------------------------------------

-- p为朝向，如果p传的是pos的话，不需要根据ball.antiY()进行反算
function goBackBall(p, d)
	local mexe, mpos = GoCmuRush { pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = flag.dodge_ball }
	return { mexe, mpos }
end

-- 带避车和避球
function goBackBallV2(p, d)
	local mexe, mpos = GoCmuRush { pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = bit:_or(flag.allow_dss, flag.dodge_ball) }
	return { mexe, mpos }
end

function stop()
	local mexe, mpos = Stop {}
	return { mexe, mpos }
end

function continue()
	return { ["name"] = "continue" }
end

------------------------------------ 测试相关的skill ---------------------------------------

function openSpeed(vx, vy, vw, iflag)
	local mexe, mpos = OpenSpeed { speedX = vx, speedY = vy, speedW = vw, flag = iflag }
	return { mexe, mpos }
end

function getInitData(role, p)
	return function()
		debugEngine:gui_debug_msg(p, "targetIsHere")
		if player.pos(role):dist(p) < 10 and player.velMod(role) < 11 then
			p = CGeoPoint:new_local(math.random(-3200, 3200), math.random(-2500, 2500))
		end
		idir = player.toPointDir(p, role)
		local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }

		return { mexe, mpos }
	end
end

kickPower = {}
minPower = 1000
maxPower = 6000
powerStep = 100
playerCount = 0
fitPlayerLen = 0
fitPlayerList = {}
fitPlayer1 = -1
fitPlayer2 = -1

-- isFitfinshed = false
function fitPower(i)
	return function()
		return kickPower[i]
	end
end

function getFitData_runToPos(role)
	return function()
		-- 当前角色
		local playerNum = player.num(role)
		fitPlayerLen = 0
		fitPlayerList = {}
		local i = 0
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 2800-(200*playerNum)),string.format("%s playerNum:            %d", role, playerNum))
		for i=0,param.maxPlayer-1 do
			-- debugEngine:gui_debug_msg(CGeoPoint(-4500, 2800-(200*i)),"kickPower: "..tostring(kickPower[i]).."  "..tostring(i))
			if kickPower[i] < 0 or kickPower[i] > maxPower then
				-- continue
			else
				fitPlayerList[fitPlayerLen] = i
				fitPlayerLen = fitPlayerLen + 1
			end
		end
		-- debugEngine:gui_debug_msg(CGeoPoint(100, 100), tostring(fitPlayerList[0]))
		-- 角色选择器
		if fitPlayerLen > 1 then
			fitPlayer1 = fitPlayerList[0]
			fitPlayer2 = fitPlayerList[1] 
		elseif playerCount >= 1 then
			fitPlayer1 = fitPlayerList[0]
			for i=0,param.maxPlayer-1 do
				if kickPower[i] < 0 then
					-- continue
				else
					fitPlayer2 = i
					break
				end
			end
		-- elseif fitPlayerLen == 0 then
		-- 	-- debugEngine:gui_debug_msg(CGeoPoint(-3000, -3000), "车不够多") 
		-- 	isFitfinshed = true
		end
    	
    	if playerNum == fitPlayer1 or playerNum == fitPlayer2 then
    		-- 跑去接踢位

    		-- 标记踢球人 1 - 踢球		-1 - 接球
    		local flag = playerNum == fitPlayer1 and 1 or -1
    		-- 拿球点
    		-- p0 = CGeoPoint:new_local(ball.posX(), ball.posY())
    		local rolePos = CGeoPoint:new_local(player.posX(fitPlayer1), player.posY(fitPlayer1))
    		local p0 = Utils.GetBestInterPos(vision, rolePos, 3, 1)
	    	-- 踢球车的准备点
	    	local p1 = CGeoPoint:new_local(flag*param.FIT_PLAYER_POS_X, flag*param.FIT_PLAYER_POS_Y)

    		if player.infraredCount(role) < 10 and flag == 1 then
    			-- 踢球人如果没有拿到球，就去拿球
	    		local idir = player.toPointDir(p0, role)
				local mexe, mpos = GoCmuRush { pos = p0, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif player.toPointDist(role, p1) > param.playerRadius or ball.velMod() > 20  then
				-- ::TODO there has some bugs
				-- 非踢球人去固定点
	    		local idir = (player.pos(fitPlayer2)- player.pos(role)):dir()
	    		if playerNum == fitPlayer2 then
		    		idir = (player.pos(fitPlayer1)- player.pos(role)):dir()
	    		end
				local mexe, mpos = GoCmuRush { pos = p1, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif flag == 1 then
				-- 踢球
				-- kickPower[fitPlayer1] = kickPower[fitPlayer1] + powerStep
				local ipos = CGeoPoint:new_local(0, 0)
				local idir = function(runner)
					return (_c(ipos) - player.pos(runner)):dir()
				end
				local mexe, mpos = Touch { pos = ipos, useInter = ifInter }
				local ipower = function()
					return kickPower[fitPlayer1]
				end
				return { mexe, mpos, kick.flat, idir, pre.low, ipower, ipower, 0x00000000 }
    		end
		else
    		-- 跑去待机位
    		local p = CGeoPoint(param.pitchWidth/2-param.playerRadius*3*playerNum, param.pitchLength/2-1500)
    		local idir = 0
			local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
			return { mexe, mpos }
    	end
	end
end

function getFitData_recording(role)
	return function()
		-- 当前角色
		local playerNum = player.num(role)

		if playerNum == fitPlayer2 then
			local rolePos = CGeoPoint:new_local(player.posX(role), player.posY(role))
			local getBallPos = Utils.GetBestInterPos(vision, rolePos, 3, 1)
			if getBallPos:x() < 0 or getBallPos:y() < 0 then
				-- 踢球
				local p = player.pos(fitPlayer1)
				local kp = 1
				local ipos = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
				local idir = function(runner)
					return (player.pos(fitPlayer1) - player.pos(runner)):dir()
				end
				local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }


				return { mexe, mpos, kick.flat, idir, pre.low, power(p, kp), power(p, kp), 0x00000000 }
			end

		elseif playerNum ~= fitPlayer1 then
			-- 跑去待机位
    		local p = CGeoPoint(param.pitchWidth/2-param.playerRadius*3*playerNum, param.pitchLength/2-1500)
    		local idir = 0
			local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
			return { mexe, mpos }
		end

	end
end