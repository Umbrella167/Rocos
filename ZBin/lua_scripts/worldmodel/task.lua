module(..., package.seeall)

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---
local bufcnt_Infield = 0
function getBall_BallPlacement(role)
	return function()
		local ballPos = GlobalMessage.Tick().ball.pos
		debugEngine:gui_debug_x(ballPos,3)
		debugEngine:gui_debug_msg(ballPos,"BallPos",3)
		local placementflag = bit:_or(flag.dribbling, flag.our_ball_placement)
		local ballPlacementPos = CGeoPoint(ball.placementPos():x(),ball.placementPos():y())
		local ipos = ballPos
		local idir = player.toBallDir(role)
		local ia = 1600
		--如果球在场地内，机器人就可以走到球后面然后推着球走
		if Utils.InField(ballPos) then
			bufcnt_Infield  = bufcnt_Infield + 1
		else 
			bufcnt_Infield = 0
		end
		if bufcnt_Infield > 60 then 
			local toballDir = math.abs((ball.pos() - player.rawPos(role)):dir())
			local playerDir = math.abs(player.dir(role))
			local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
			if bufcnt (Subdir < 30 and player.toBallDist(role) < 200,60) then
				debugEngine:gui_debug_msg(CGeoPoint(0,0),"1")
				placementflag = flag.our_ball_placement + flag.dribbling
				idir =  (ballPlacementPos - player.pos(role)):dir()
				ipos = ballPlacementPos + Utils.Polar2Vector(-90,idir)
			else
				debugEngine:gui_debug_msg(CGeoPoint(0,0),"2")
				local DSS_FLAG = flag.our_ball_placement + flag.dodge_ball + flag.allow_dss
				placementflag =  DSS_FLAG
				ipos = ballPos + Utils.Polar2Vector(-120, (ballPlacementPos - ballPos):dir())
			end
		else
			-- debugEngine:gui_debug_msg(CGeoPoint(100,1000),player.myinfraredCount(role))
			if player.myinfraredCount(role) < 20 then
				local toballDir = math.abs((ball.pos() - player.rawPos(role)):dir())
				local playerDir = math.abs(player.dir(role))
				local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
				if bufcnt( Subdir < 30 and player.toBallDist(role) < 200,60) then
					debugEngine:gui_debug_msg(CGeoPoint(0,0),"3")
					placementflag = flag.our_ball_placement + flag.dribbling
					idir =  (player.pos(role) - ballPlacementPos ):dir()
					ipos = ballPos + Utils.Polar2Vector(-param.playerFrontToCenter,idir)
				else
					debugEngine:gui_debug_msg(CGeoPoint(0,0),"4")
					local DSS_FLAG = flag.our_ball_placement + flag.dodge_ball + flag.dribbling
					placementflag =  DSS_FLAG
					idir = player.toBallDir(role)
					ipos = ballPos + Utils.Polar2Vector(-120,(ballPos - ballPlacementPos):dir())
					ia = 2000

				end
				-- if not ball.valid() then
				-- 	ipos = ballPos + Utils.Polar2Vector(20,player.toBallDir(role))
				-- 	local DSS_FLAG = flag.our_ball_placement + flag.dribbling
				-- 	placementflag =  DSS_FLAG
				-- 	ia = 500
				-- end

			else
				debugEngine:gui_debug_msg(CGeoPoint(0,0),"5")
				idir =  (player.pos(role) - ballPlacementPos ):dir()
				ipos = ballPlacementPos + Utils.Polar2Vector(0,idir)
				if not ball.valid() then
					local DSS_FLAG = flag.our_ball_placement + flag.dodge_ball + flag.dribbling
					placementflag =  DSS_FLAG
					ipos = CGeoPoint(0,0)
				end
			end

		end
		local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = ia, flag = placementflag, rec = r, vel = v, speed = 1, force_manual = force_manual }
		return { mexe, mpos }
	end
end

function angleDiff(angle1,  angle2)
    return math.atan2(math.sin(angle2 - angle1), math.cos(angle2 - angle1));
end
function compensateAngle(role,robotRotVel,Pos,Kp)

	local iPos
	if type(Pos) == "function" then
		iPos = Pos()
	else
		iPos = Pos
	end
	local new_pos = iPos + Utils.Polar2Vector(robotRotVel * Kp, (iPos - player.pos(role)):dir() + math.pi / 2)
	return new_pos
end

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
	local endvel = Utils.Polar2Vector(player.toPointDist(role, p)*1, (player.pos(role) - p):dir())

	-- local endvel = Utils.Polar2Vector(100,(player.pos(role) - p):dir())
	-- if player.toPointDist(role, p) > param.playerRadius then
	-- 	endvel = Utils.Polar2Vector(-1200,(player.pos(role) - p):dir())
	-- end
	return endvel
end

function TurnRun(pos,vel)
	local ipos = pos or  CGeoPoint:new_local(0,80)  --自身相对坐标 旋转
	local ivel = vel -- 旋转速度 -+ 改变方向
	local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
	return { mexe, mpos }
end


function getball_dribbling(role)
	return function()
		local idir = player.toBallDir(role)
		local p = ball.pos() + Utils.Polar2Vector(-10,idir)
		local endVel = Utils.Polar2Vector(ball.velMod() + 100,idir)
		local toballDir = math.abs((ball.pos() - player.rawPos(role)):dir())
		local playerDir = math.abs(player.dir(role))
		local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
		local iflag = flag.dribbling + flag.allow_dss
		local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
		if Subdir > 15 and player.toBallDist(role) < 150 then 
			iflag =  DSS_FLAG
		else
			iflag = flag.dribbling + flag.allow_dss
		end
		local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = iflag, rec = r, vel = endVel, speed = s, force_manual = force_manual }
		return { mexe, mpos }
	end
end

function getball(shootPos_,playerVel, inter_flag, permissions)
	return function()
		-- 解决敌人过近的问题
		-- if GlobalMessage.Tick().ball.rights == -1 or GlobalMessage.Tick().ball.rights == 2 then
			local minEnemyDistNum1 = {}
			for i = 0 ,param.maxPlayer -1 do 
				if enemy.valid(i) then
					if enemy.pos(i):dist(ball.pos()) < 200 then
						table.insert(minEnemyDistNum1,i)
					end
					if #minEnemyDistNum1 == 2 then
						break
					end
				end
			end
			print("minEnemyDistNum1:" .. #minEnemyDistNum1)
			if (#minEnemyDistNum1 > 0 ) then
				local toballDir = (ball.pos() - enemy.pos(GlobalMessage.Tick().their.dribbling_num)):dir()
				local playerDir = (enemy.pos(GlobalMessage.Tick().their.dribbling_num) - player.pos("Assister") ):dir()
				local Subdir = Utils.angleDiff(toballDir,playerDir) * 180/math.pi
				local dist_ = -param.playerFrontToCenter + 40
				local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick().their.dribbling_num)

				if math.abs(Subdir) > 165 then
					local inter_pos = ball.pos() + Utils.Polar2Vector(dist_,(theirDribblingPlayerPos - ball.pos()):dir())
					local idir = (theirDribblingPlayerPos - ball.pos()):dir()
					local iflag = flag.dribbling
					local mexe, mpos = SimpleGoto { pos = inter_pos, dir = idir, flag = iflag }
					return { mexe, mpos }
				end
			end
		-- end

		local ishootpos
		if type(shootPos_) == "function" then
			ishootpos = shootPos_()
		else
			ishootpos = shootPos_
		end
		local ipermissions = permissions or 0
		local mexe, mpos = Getball {shootPos = ishootpos,permissions = ipermissions ,inter_flag = inter_flag, pos = pp, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
		return { mexe, mpos }
	end
end

function getballV2(role, playerVel, inter_flag, target_point, permissions)
	return function()
		local p1
		if type(target_point) == 'function' then
			p1 = target_point()
		else
			p1 = target_point
		end
		if permissions == nil then
			permissions = 0
		end

		if player.myinfraredCount(role) < 5 then
			local qflag = inter_flag or 0
			local playerPos = CGeoPoint:new_local( player.pos(role):x(),player.pos(role):y())
			local inter_pos = stabilizePoint(Utils.GetBestInterPos(vision,playerPos,playerVel,qflag,permissions,param.V_DECAY_RATE))
			
			local idir = player.toBallDir(role)
			local ipos = ball.pos()
			if inter_pos:x()  ==  param.INF or inter_pos:y()  == param.INF then
				ipos = ball.pos()
			else
				ipos = inter_pos
			end
			
			-- local toballDir = math.abs(player.toBallDir(role))  * 57.3
			local toballDir = math.abs((ball.pos() - player.rawPos(role)):dir())
			local playerDir = math.abs(player.dir(role))
			local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
			local subPlayerBallToTargetDir = toballDir - playerDir 
			local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
			if Subdir > 20 then 
				  --自身相对坐标 旋转

				if subPlayerBallToTargetDir < 0 then
					local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
					local ivel = 10 * -1
					local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
					return { mexe, mpos }
				else
					
					local ipos = param.rotPos  --自身相对坐标 旋转
					local ivel = 10
					local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
					return { mexe, mpos }
				end
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
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = iflag, rec = r, vel = v }
			return { mexe, mpos }
		end
	end
end
minDist_Power = 0
maxDist_Power = 6000
playerPowerONE = 
{
	-- [num] = {minist,maxDist,minPower, maxPower, ShootPower,chipPower} 
	[0] = {minDist_Power,maxDist_Power,200,330,400,7000},
	[1] = {minDist_Power,maxDist_Power,120,330,350,7000},
	[2] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[3] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[4] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[5] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[6] = {minDist_Power,9000,135,330,350,7000},
	[7] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[8] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[9] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[10] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[11] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[12] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[14] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[15] = {minDist_Power,maxDist_Power,135,330,350,7000},
	[16] = {minDist_Power,maxDist_Power,135,330,350,7000},

}
playerPowerTWO = {
	-- [num] = {minist,maxDist,minPower, maxPower, ShootPower,chipPower} 
	[0] = {minDist_Power,maxDist_Power,200,330,400,7000}, 
	[1] = {minDist_Power,maxDist_Power,120,330,315,7000},-- 可以挑球 ，吸球还行
	[2] = {minDist_Power,maxDist_Power,120,330,315,7000}, 
	[3] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[4] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[5] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[6] = {minDist_Power,maxDist_Power,120,330,450,7000}, -- 带球超强 ,挑球一般
	[7] = {minDist_Power,maxDist_Power,120,330,315,7000}, -- 红外偶尔有问题
	[8] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[9] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[10] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[11] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[12] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[14] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[15] = {minDist_Power,maxDist_Power,120,330,315,7000},
	[16] = {minDist_Power,maxDist_Power,120,330,315,7000},
}

playerPower = (param.Team == "ONE") and playerPowerONE or playerPowerTWO
function power(p, num,shootFlag)
	return function()
		local iflag
		if type(shootFlag) == 'function' then
			iflag = shootFlag()
		else
			iflag = shootFlag
		end
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local shootPos = function()return param.shootPos end
		local isShoot = shootPos():x() == param.pitchLength / 2 and true or false
		local playerNum
		if type(num) == 'function' then
			playerNum = num()
		else
			playerNum = num
		end
		local dist = (p1 - ball.pos()):mod()
		if playerNum == -1 or playerNum == nil then
			playerNum = 16
		end
		local res = Utils.map(dist,playerPower[playerNum][1],playerPower[playerNum][2],playerPower[playerNum][3],playerPower[playerNum][4])

		if iflag == kick.chip() then
			res = playerPower[playerNum][6]
		elseif iflag == kick.flat() and isShoot == true then
			res = playerPower[playerNum][5]
		end
		---仿真的力度
		
		if not param.isReality then
			local SimulationRate = 15
			res = res * SimulationRate
			if iflag == kick.chip() then
				res = 3500
			end
		end	
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
		if (player.myinfraredCount(role) < 20) then
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

function TurnToPointV1(role, p, speed)
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
	-- 逆时针旋转
	local idirLeft = (playerDir+param.PI/2)>param.PI and playerDir-(3/2)*param.PI or playerDir+param.PI/2 
	-- 顺时针旋转
	local idirRight = (playerDir-param.PI/2)>param.PI and playerDir+(3/2)*param.PI or playerDir-param.PI/2
	
	local Subdir = math.abs(Utils.angleDiff(playerToTargetDir,playerDir))

	if Subdir > 0.14 then
		if subPlayerBallToTargetDir > 0 then
			-- 逆时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "0")
			local target_pos = playerPos+Utils.Polar2Vector(speed, idirLeft)+Utils.Polar2Vector(2*playerToBallDist, playerToBallDir)
			debugEngine:gui_debug_x(target_pos)
			local mexe, mpos = GoCmuRush { pos = target_pos, dir = playerToBallDir, acc = a, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
		end
		-- 顺时针旋转
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "1")
		local target_pos = playerPos+Utils.Polar2Vector(speed, idirRight)+Utils.Polar2Vector(2*playerToBallDist, playerToBallDir)
		debugEngine:gui_debug_x(target_pos)
		local mexe, mpos = GoCmuRush { pos = target_pos, dir = playerToBallDir, acc = a, flag = 0x00000100, rec = r, vel = v }
		return { mexe, mpos }
	-- else
	-- elseif playerToBallDist > 1 then
	-- 	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000, 1000), "2")
	-- 	local mexe, mpos = GoCmuRush { pos = ballPos, dir = playerToTargetDir, acc = a, flag = 0x00000100, rec = r, vel = v }
	-- 	return { mexe, mpos }
	-- else
	-- 	local idir = (p1 - player.pos(role)):dir()
	-- 	local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
	-- 	local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
	-- 	return { mexe, mpos }  
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
	debugEngine:gui_debug_x(p1,6)

		-- local toballDir = (p1 - player.rawPos(role)):dir() * 57.3
		-- local playerDir = player.dir(role) * 57.3
		-- local subPlayerBallToTargetDir = toballDir - playerDir 

		
		local toballDir = (p1 - player.rawPos(role)):dir()
		local playerDir = player.dir(role)
		local subPlayerBallToTargetDir = Utils.angleDiff(toballDir,playerDir) * 180/math.pi
		-- local Subdir = math.abs(toballDir-playerDir)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,380),toballDir .. "                     " .. playerDir,4)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,220),math.abs(toballDir-playerDir) .. "                     " .. subPlayerBallToTargetDir,3)
	if math.abs(subPlayerBallToTargetDir) > 4 then
		if subPlayerBallToTargetDir > 0 then
			-- 顺时针旋转
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "顺时针".. subPlayerBallToTargetDir)

			local ipos = CGeoPoint(param.rotPos:x(), param.rotPos:y() * -1)  --自身相对坐标 旋转
			local ivel = speed * -1
			local mexe, mpos = CircleRun {pos = ipos , vel = ivel}
			return { mexe, mpos }
		else
			-- 逆时针旋转
			-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "逆时针")
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), "逆时针".. subPlayerBallToTargetDir)

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
end

function ShootdotV2(p, error_, flag_,role)
	return function()
		local irole = role or "Assister"
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

		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = v }
		return { mexe, mpos, flag_, idir, error__, power(p,player.num(irole),flag_), power(p, player.num(irole),flag_), flag.dribbling }
	end
end


function ShootdotDribbling(error_, flag_,power)
	return function()
		local ipower
		if type(power) == 'function' then
			ipower = power()
		else
			ipower = power
		end
		local irole = role or "Assister"
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		local shootpos = function(runner)
			return ball.pos() + Utils.Polar2Vector(-50, player.toBallDir(runner))
		end
		local idir = function(runner)
			return player.toBallDir(runner)
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
		ipower = param.isReality and ipower or ipower * 15
		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = v }
		return { mexe, mpos, flag_, idir, error__,kp.specified(ipower) , kp.specified(ipower), flag.dribbling }
	end
end


function Shootdot(role,p, error_, flagShoot) --
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
		local toballDir = math.abs((ball.pos() - player.rawPos(role)):dir())
		local playerDir = math.abs(player.dir(role))
		local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
		local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
		if Subdir > error_ then 
			local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
			iflag =  DSS_FLAG
			shootpos = ball.pos() + Utils.Polar2Vector(-300, (p1 - ball.pos()):dir())

		else
			iflag = flag.dribbling
		end
		local mexe, mpos = GoCmuRush { pos = shootpos, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
		return { mexe, mpos, flagShoot, idir, error__, power(p,player.num(role),flag_), power(p, player.num(role),flag_), 0x00000000 }
	end
end


function playerDirToPointDirSub(role, p) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end
	local toballDir = (p1 - ball.pos()):dir()
	local playerDir = player.dir(role)
	local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
	local playerDir = player.dir(role) * 57.3 + 180
	local playerPointDit = (p1 - player.rawPos(role)):dir() * 57.3 + 180
	local Subdir = math.abs(playerDir - playerPointDit)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -4000),  "AngleError: ".. Subdir)
	return Subdir
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

function touch()
	local ipos = function()  return CGeoPoint( ball.posX(),ball.posY()) + Utils.Polar2Vector(500,(ball.pos() - GlobalMessage.Tick().ball.pos_move_befor):dir()) end
	local mexe, mpos = Touch { pos = ipos }
	return { mexe, mpos }
end

function touchKick(p, ifInter,mode)
	return function(runner)
		local ipos 
		local idir = function(runner)
			return (_c(p) - player.pos(runner)):dir()
		end
		local mexe, mpos = Touch { pos = p, useInter = ifInter }
		return { mexe, mpos, mode and kick.flat or kick.chip, idir, pre.low, power(p,runner,mode and kick.flat or kick.chip), power(p,runner,mode and kick.flat or kick.chip), flag.nothing }
	end
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

function isBallPassingToOurArea()
	local aimLine = CGeoSegment(CGeoPoint:new_local(param.defenderAimX, param.INF), CGeoPoint:new_local(param.defenderAimX, -param.INF))
	local ballPos = CGeoPoint:new_local(ball.rawPos():x(), ball.rawPos():y())
	local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ball.velDir()))
	local tp = aimLine:segmentsIntersectPoint(ballLine)
	if Utils.InField(tp) then
		return true
	end
	-- debugEngine:gui_debug_x(tp, param.GREEN)
	-- debugEngine:gui_debug_line(CGeoPoint:new_local(param.defenderAimX, param.INF), CGeoPoint:new_local(param.defenderAimX, -param.INF))
	-- debugEngine:gui_debug_line(ballPos, ballPos+Utils.Polar2Vector(param.INF, ball.velDir()))
	return false
end

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

defenderCount = 0
defenderNums = {}
function getDefenderCount()
	defenderCount = 0
	for i=0, param.maxPlayer-1 do
		playerName = player.name(i)
		if player.valid(i) and (playerName == "Tier" or playerName == "Defender") then
			defenderNums[defenderCount] = i
			defenderCount = defenderCount + 1
		end
	end
	return defenderCount
end

-- defender who is the cloest the point 
function isClosestPointDefender(role, p)
	local minCatchBallDist = param.INF
	local roleNum = -1
	for i=0, defenderCount-1 do
		local playerPos = CGeoPoint:new_local(player.rawPos(defenderNums[i]):x(), player.rawPos(defenderNums[i]):y())
		if playerPos:dist(p) < minCatchBallDist then
			minCatchBallDist = playerPos:dist(p)
			roleNum = defenderNums[i]
		end
	end
	return player.num(role)==roleNum and true or false
end


-- 得到目标线与defender框相交的点
-- 第一个是要盯的点，第二个为基准点（基准角度）
function getLineCrossDefenderPos(pos_, posOrDir_)
	local resPos = CGeoPoint(param.INF, param.INF)
	local minDist = param.INF
	local line_ = CGeoSegment(pos_, pos_)
	if type(posOrDir_) == 'number' then
		line_ = CGeoSegment(pos_, pos_+Utils.Polar2Vector(param.INF, posOrDir_))
		-- debugEngine:gui_debug_line(pos_, pos_+Utils.Polar2Vector(param.INF, posOrDir_))
	elseif type(posOrDir_) == 'userdata' then
		local idir = (pos_ - posOrDir_):dir()
		local tPos = posOrDir_ + Utils.Polar2Vector(param.INF, idir)
		line_ = CGeoSegment(tPos, posOrDir_)
		-- debugEngine:gui_debug_line(tPos, posOrDir_)
	end
	-- 打印defender行走的框
	debugEngine:gui_debug_line(param.defenderTopRightPos, param.defenderButtomRightPos,8)
	debugEngine:gui_debug_line(param.defenderTopPos, param.defenderTopRightPos,8)
	debugEngine:gui_debug_line(param.defenderButtomPos, param.defenderButtomRightPos,8)

	local defenderTopLine = CGeoSegment(param.defenderTopPos, param.defenderTopRightPos)
	local defenderMiddleLine = CGeoSegment(param.defenderTopRightPos, param.defenderButtomRightPos)
	local defenderButtomLine = CGeoSegment(param.defenderButtomPos, param.defenderButtomRightPos)
	local tPos = line_:segmentsIntersectPoint(defenderTopLine)
	if pos_:dist(tPos) < minDist then
		resPos = tPos
		minDist = pos_:dist(tPos)
	end
	-- debugEngine:gui_debug_x(tPos, 0)
	local tPos = line_:segmentsIntersectPoint(defenderMiddleLine)
	if pos_:dist(tPos) < minDist then
		resPos = tPos
		minDist = pos_:dist(tPos)
	end
	-- debugEngine:gui_debug_x(tPos, 0)
	local tPos = line_:segmentsIntersectPoint(defenderButtomLine)
	if pos_:dist(tPos) < minDist then
		resPos = tPos
		minDist = pos_:dist(tPos)
	end
	-- debugEngine:gui_debug_x(tPos, 0)
	return resPos
end

function isCrossPenalty(rolePos, targetPos)
	local line_ = CGeoSegment(rolePos, targetPos)
	local tPos = line_:segmentsIntersectPoint(param.penaltyMiddleLine)
	-- debugEngine:gui_debug_x(tPos)
	-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), tPos:x().."  "..tPos:y())
	if tPos == CGeoPoint(9999, 9999) then
		return false
	end
	return true
end

-- 用于禁区前快速运动
function simpleMoveTargetPos(rolePos, targetPos)
	local tPosX = targetPos:x()
	local tPosY = targetPos:y()
	-- debugEngine:gui_debug_msg(CGeoPoint(-2000, 2000), "x: "..math.abs(rolePos:x() - targetPos:x()))
	-- debugEngine:gui_debug_msg(CGeoPoint(-2000, 2200), "y: "..math.abs(rolePos:y() - targetPos:y()))
	-- debugEngine:gui_debug_msg(CGeoPoint(0,0), tostring(isCrossPenalty(rolePos, targetPos)))
	
	if math.abs(rolePos:x() - targetPos:x()) > 100 and math.abs(rolePos:y() - targetPos:y()) > 100 or isCrossPenalty(rolePos, targetPos) then
		tPosX = param.defenderTopRightPos:x()
		if math.abs(rolePos:y() - param.defenderTopRightPos:y()) < 100 and math.abs(rolePos:x() - param.defenderTopRightPos:x()) > param.defenderBuf then
			tPosY = param.defenderTopRightPos:y()
			-- tPosY = rolePos:y()
		end
		if math.abs(rolePos:y() - param.defenderButtomRightPos:y()) < 100 and math.abs(rolePos:x() - param.defenderButtomRightPos:x()) > param.defenderBuf  then
			tPosY = param.defenderButtomRightPos:y()
			-- tPosY = rolePos:y()
		end
	end

	return CGeoPoint(tPosX, tPosY)
end

-- 尽量避免撞车
function eschewingOurCar(role, targetPos, ourBuf, enemyBuf)
	if ourBuf == nil then
		ourBuf = param.playerRadius*3
	end

	if enemyBuf == nil then
		enemyBuf = param.playerRadius*2
	end

	-- 避免干扰己方车辆
	for i=0, param.maxPlayer-1 do
		-- debugEngine:gui_debug_msg(CGeoPoint(0, 150*player.num(role)), player.num(role))
        if player.valid(i) and i ~= player.num(role) then
        	if player.pos(i):dist(targetPos) < ourBuf then
        		local tPos = player.pos(i)+Utils.Polar2Vector(ourBuf, (player.pos(role)-player.pos(i)):dir())
        		debugEngine:gui_debug_x(tPos, 2)
        		return tPos
        	end
        end
    end

    -- 避免顶撞敌方车辆
	for i=0, param.maxPlayer-1 do
		-- debugEngine:gui_debug_msg(CGeoPoint(0, 150*player.num(role)), player.num(role))
        if enemy.valid(i) then
        	if enemy.pos(i):dist(targetPos) < enemyBuf then
        		local tPos = enemy.pos(i)+Utils.Polar2Vector(enemyBuf, (player.pos(role)-enemy.pos(i)):dir())
        		debugEngine:gui_debug_x(tPos, 2)
        		return tPos
        	end
        end
    end

    return targetPos
end

-- 检查周围是否有敌人
function isCloseEnemy(role, buf)
	if buf == nil then
		buf = param.playerRadius * 4
	end
	for i=0, param.maxPlayer-1 do
		if enemy.valid(i) and enemy.pos(i):dist(player.pos(role)) <= buf then
	    	return true
	    end
	end
	return false
end


-- defender_norm script 
-- mode: 0 upper area, 1 down area, 2 middle
-- flag: 0 aim the ball, 1 aim the enemy
function defend_normV2(role, mode, flag)
	-- debugEngine:gui_debug_x(getLineCrossDefenderPos(ball.pos(), ball.velDir()), 3)
	-- debugEngine:gui_debug_x(getLineCrossDefenderPos(ball.pos(), param.ourGoalPos), 3)
	getDefenderCount()
	if defenderCount == 1 then
		mode = 2
	end
	if flag == nil then
		flag = 0
	end
	local enemyNum = getManMarkEnemy()
	local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
	local goalieToEnemyDir = (enemy.pos(enemyNum) - player.rawPos("Goalie")):dir()
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local ballPos = CGeoPoint:new_local(ball.rawPos():x(), ball.rawPos():y())
	local basePos = param.ourGoalPos
	local targetPos = ballPos

	if mode == 0 then
		basePos = param.ourTopGoalPos
	elseif mode == 1 then
		basePos = param.ourButtomGoalPos
	elseif mode == 2 then
		basePos = param.ourGoalPos
	end

	if flag == 0 then
		targetPos = ballPos
	elseif flag == 1 then
		targetPos = enemyPos
	end
	
	local defenderPoint = getLineCrossDefenderPos(targetPos, basePos)
	if defenderPoint == CGeoPoint(9999, 9999) then
		defenderPoint = rolePos
	end
	defenderPoint = simpleMoveTargetPos(rolePos, defenderPoint)
	debugEngine:gui_debug_x(defenderPoint, 0)

	local idir = player.toPointDir(enemyPos, role)
	local mexe, mpos = SimpleGoto { pos = eschewingOurCar(role, defenderPoint, param.playerRadius*2), dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
	if not isCloseEnemy(role) then
		mexe, mpos = GoCmuRush { pos = eschewingOurCar(role, defenderPoint), dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
	end
	return { mexe, mpos }
end



-- defender_norm script 
-- mode: 0 upper area, 1 down area, 2 middle
-- flag: 0 aim the ball, 1 aim the enemy
function defend_norm(role, mode, flag)
	getDefenderCount()
	if defenderCount == 1 then
		mode = 2
	end
	if flag == nil then
		flag = 0
	end
	local enemyNum = getManMarkEnemy()
	local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
	local goalieToEnemyDir = (enemy.pos(enemyNum) - player.rawPos("Goalie")):dir()
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local ballPos = CGeoPoint:new_local(ball.rawPos():x(), ball.rawPos():y())
	local basePos = param.ourGoalPos
	local targetPos = ballPos
	if mode == 0 then
		basePos = param.ourTopGoalPos
	elseif mode == 1 then
		basePos = param.ourButtomGoalPos
	elseif mode == 2 then
		basePos = param.ourGoalPos
	end
	if flag == 0 then
		targetPos = ballPos
	elseif flag == 1 then
		targetPos = enemyPos
	end
	local baseDir = (targetPos - basePos):dir()
	-- use the math formula to calc the run pos
	local distX = basePos:x() - param.ourGoalPos:x()
	local distY = basePos:y() - param.ourGoalPos:y()
	local dist = math.sqrt(distX*distX + distY*distY)
	local angle = math.atan2(distY, distX)
	local dist = dist * math.cos(baseDir - angle) - param.defenderRadius
	-- debugEngine:gui_debug_msg(CGeoPoint(2000, 2000+(150*mode)), role.."  mode:"..mode)
	-- debugEngine:gui_debug_arc(param.ourGoalPos, param.defenderRadius, 0, 360)
	local defenderPoint = basePos+Utils.Polar2Vector(-dist, baseDir)
	local idir = player.toPointDir(enemyPos, role)
	local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, defenderPoint) }
	return { mexe, mpos }
end


-- TODO：模式暂定，这样写可能会有很多问题，先完成其他功能
-- 当敌人靠近我方时，defender的行动模式
-- aimMode 盯防模式 0-离我方球门最近的敌人，1-拥有球权的敌人
-- defender1,2的区分方式为离aimEnenmy的距离
-- defender1Mode 防御者的模式 0
function defend_front(role, aimMode, defender1Mode, defender2Mode)
	getDefenderCount()
	-- 防御离球门最近的敌人
	local enemyNum = enemy.closestGoal()
	local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
	local enemyToGoalDir = (param.ourGoalPos - enemyPos):dir()
	local defenderPoint = enemyPos + Utils.Polar2Vector(3*param.playerRadius, enemyToGoalDir)
	if isClosestPointDefender(role, defenderPoint) then
		-- defener1
		local idir = player.toPointDir(enemyPos, role)
		local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, defenderPoint) }
		return { mexe, mpos }
	else
		-- defener2
		local tTable = defend_norm(role, 2)
		return tTable
	end
end

function defend_kick(role)
	getDefenderCount()
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local defenderPoint = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 2,0,param.V_DECAY_RATE)
	local targetPos = ball.rawPos() --改了可能会出bug
	if isClosestPointDefender(role, defenderPoint) then
		local idir = function(runner)
			return (targetPos - player.pos(runner)):dir()
		end
		debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), player.dir(role))
		local mexe, mpos = GoCmuRush { pos = defenderPoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, defenderPoint) }
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), math.abs(player.dir(role)))
		
		if math.abs(player.dir(role)) > math.pi/2 then
			return { mexe, mpos, param.defenderShootMode, idir, pre.low, kp.specified(0), kp.specified(0), 0x00000000 }
		end
		return { mexe, mpos, param.defenderShootMode, idir, pre.low, power(targetPos,player.num(role) ,param.defenderShootMode), power(targetPos,player.num(role) ,param.defenderShootMode), 0x00000000 }
	else
		local tTable = defend_norm(role, 2)
		return tTable
	end
end

-- 守门员skill
-- 守门员的预备状态
-- mode 防守模式选择, 0-goalie路线为球门前直线, 1-goalie的路线为球门半径画圆, 默认为1
function goalie_norm(role, mode)
	if mode==nil then
		mode = 0
	end
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local enemyNum = getManMarkEnemy()
	if enemyNum == -1 then
		-- return Stop {}
		local mexe, mpos = SimpleGoto { pos = param.ourGoalPos, dir = (param.theirGoalPos - param.ourGoalPos):dir(), flag = 0x00000100 }
		return {mexe, mpos}
		-- return GoCmuRush { pos = param.ourGoalPos, dir = (param.theirGoalPos - param.ourGoalPos):dir(), acc = a, flag = 0x00000100, rec = r, vel = v }
	end
	local enemyDir = enemy.dir(enemyNum)
	local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
	local enemyDirLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
	local enemyToGoalDist = (enemyPos-param.ourGoalPos):mod()
	local goalToEnemyLine = CGeoSegment(param.ourGoalPos, enemyPos)
	local goalToEnemyDir = (enemyPos - param.ourGoalPos):dir()
	local goalieMoveLine = param.goalieMoveLine
	local goalLine = param.ourGoalLine

	-- 准备状态
	-- 这里是当球没有朝球门飞过来的时候，需要提前到达的跑位点
	local goaliePoint = param.ourGoalPos+Utils.Polar2Vector(param.goalieRadius, goalToEnemyDir)
	-- local goaliePoint = param.ourGoalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
	if mode==0 then
		goaliePoint = CGeoPoint(param.goalieMoveX, (enemyPos:y()/param.pitchWidth)*param.goalWidth)
		-- goaliePoint = goalieMoveLine:segmentsIntersectPoint(goalToEnemyLine)
	elseif mode==1 then
		goaliePoint = param.ourGoalPos+Utils.Polar2Vector(param.goalieRadius, goalToEnemyDir)
	end
	if enemyToGoalDist<param.goalieAimDirRadius then
		-- 近处需要考虑敌人朝向的问题
		local enemyAimLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
		local tPos = goalLine:segmentsIntersectPoint(enemyAimLine)
		-- 判断是否朝向球门
		local isToGoal = -param.enemyAimBuf<tPos:y() and tPos:y()<param.enemyAimBuf
		if isToGoal then
			local tP = tPos+Utils.Polar2Vector(-param.goalieRadius, enemyDir)
			if mode==0 then
				tP = goalieMoveLine:segmentsIntersectPoint(enemyDirLine)
			elseif mode==1 then
				tP = tPos+Utils.Polar2Vector(-param.goalieRadius, enemyDir)
			end
			-- goaliePoint = tP
			goaliePoint = CGeoPoint:new_local((tP:x()+goaliePoint:x())/2, (tP:y()+goaliePoint:y())/2)
		end
	-- debugEngine:gui_debug_x(goaliePoint, param.WHITE)
	end
	local idir = player.toPointDir(enemyPos, role)
	local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, goaliePoint) }
	return { mexe, mpos }
end

function goalie_getBall(role)
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)
	local ballPos = ball.pos()
	local ballToRoleDir = (rolePos - ballPos):dir()
	local idir = function(runner)
		return (ballPos - player.pos(runner)):dir()
	end
	-- debugEngine:gui_debug_x(param.goalieStablePoint)
	local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
	local a = 4000
	if ball.velMod() < 800 and player.myinfraredCount(role) < param.goalieReadyFrame then
		-- goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y()) + Utils.Polar2Vector(param.playerRadius-30, ballToRoleDir)
		goaliePoint = ballPos + Utils.Polar2Vector(param.playerFrontToCenter, ballToRoleDir)
	elseif param.goalieReadyFrame <= player.myinfraredCount(role) and player.myinfraredCount(role) <= param.goalieDribblingFrame then
		-- local playerToStablePointDir = (param.goalieStablePoint-rolePos):dir()
		-- goaliePoint = ballPos + Utils.Polar2Vector(param.playerRadius, ballToRoleDir) + Utils.Polar2Vector(50, playerToStablePointDir)
		a = param.goalieDribblingA
		goaliePoint = param.goalieStablePoint
		local fungoalieTargetPos = function()
			return param.goalieTargetPos
		end
		idir = (fungoalieTargetPos() - rolePos):dir()
	elseif player.myinfraredCount(role) > param.goalieDribblingFrame then
		-- 一般这个状态就跳到kick去了
		-- goaliePoint = ballPos + Utils.Polar2Vector(param.playerRadius, ballToRoleDir)
		goaliePoint = rolePos
	end
	-- local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = endVelController(role, goaliePoint), speed = s, force_manual = force_manual }
	
	local mexe, mpos = SimpleGoto { pos = goaliePoint, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = endVelController(role, goaliePoint), speed = s, force_manual = force_manual }
	if a ~= 4000 then
		mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = flag.dribbling, rec = r, vel = endVelController(role, goaliePoint), speed = s, force_manual = force_manual }
	end
	return { mexe, mpos }
end

function goalie_kick(role)
	local fungoalieTargetPos = function()
		return param.goalieTargetPos
	end
	local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
	local ballPos = ball.pos()
	local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)
	local roleToBallTargetDir = math.abs((ballPos - rolePos):dir())
	local ballToTargetDir = math.abs((fungoalieTargetPos() - ballPos):dir())

	local kp = shootKp
	if param.goalieShootMode() == 1 then
		kp = shootKp
	elseif param.goalieShootMode() == 2 then
		kp = 9999
	end
	local idir = function(runner)
		return (fungoalieTargetPos() - rolePos):dir()
	end
	local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y()) + Utils.Polar2Vector(param.playerFrontToCenter, ballToTargetDir)
	local Subdir = math.abs(Utils.angleDiff(ballToTargetDir,roleToBallTargetDir))
	local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
	if Subdir > 0.14 then 
		local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
		iflag =  DSS_FLAG
	else
		iflag = bit:_or(flag.allow_dss,flag.dribbling) 
	end

	local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
	-- return { mexe, mpos, kick.chip, idir, pre.low, power(param.goalieTargetPos, kp), power(param.goalieTargetPos, kp), 0x00000000 }
	-- return { mexe, mpos, param.goalieShootMode, idir, pre.low, power(fungoalieTargetPos(), kp, player.num(role)), power(fungoalieTargetPos(), kp, player.num(role)), 0x00000000 }
	return { mexe, mpos, param.goalieShootMode, idir, pre.low, power(fungoalieTargetPos(),player.num(role),param.goalieShootMode), power(fungoalieTargetPos(),player.num(role),param.goalieShootMode), 0x00000000 }
end


function goalie_catchBall(role)
	local rolePos = player.pos(role)
	local playerToBallDir = (ball.pos()-rolePos):dir()
	local ballPos = ball.pos()


	local getBallPos =  ballPos + Utils.Polar2Vector(param.playerFrontToCenter, playerToBallDir)
	local idir = playerToBallDir
	local iflag = flag.dribbling


	local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ball.velDir()))
	local tdist = (ballLine:projection(rolePos)-rolePos):mod()
	if tdist > 500 then
		idir = ball.velDir() + math.pi
		iflag =  flag.dodge_ball
		getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)
	end

	




	-- if rolePos:dist(ballPos) < 300 then
		-- iflag = flag.dribbling
		-- idir = playerToBallDir
		-- getBallPos = ballPos + Utils.Polar2Vector(param.playerFrontToCenter, playerToBallDir)
	-- end



	local mexe, mpos = GoCmuRush { pos = getBallPos, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
	return { mexe, mpos }
end



-- 守门员skill(目前已弃用)
-- 当球进禁区时要踢到的目标点
-- TODO：
-- 这个mode的用法不对，在更换到新的goalie子脚本中会修复
-- mode 防守模式选择, 0在球射向球门时选择防守线(x=-param.pitchLength/2-param.playerRadius)上的点, 1在球射向球门使用bestinterpos的点
function goalie(role, target, mode)
	return function()
		if mode==nil then
			mode = 1
		end

		local rolePos = CGeoPoint:new_local(player.rawPos(role):x(), player.rawPos(role):y())
		local ballPos = ball.pos()
		local ballVelDir = ball.velDir()
		local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ballVelDir))
		local enemyNum = getManMarkEnemy()
		local enemyDir = enemy.dir(enemyNum)
		local enemyPos = CGeoPoint:new_local(enemy.posX(enemyNum), enemy.posY(enemyNum))
		local enemyDirLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
		
		local goalToEnemyDir = (enemyPos - param.ourGoalPos):dir()
		local goalToEnemyLine = CGeoSegment(param.ourGoalPos, enemyPos)
		local goalLine = param.ourGoalLine
		local goalieMoveLine = CGeoSegment(CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, -param.INF), CGeoPoint:new_local(-param.pitchLength/2+param.playerRadius*2, param.INF))
		local tPos = goalLine:segmentsIntersectPoint(ballLine)
		-- 判断是否踢向球门
		local isShooting = -param.penaltyRadius-100<tPos:y() and tPos:y()<param.penaltyRadius+100
		local getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE))
		if mode == 0 then
			getBallPos = goalieMoveLine:segmentsIntersectPoint(ballLine)
		elseif mode == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE))
		end

		if ball.velMod() < 1000 and mode == 1 then
			getBallPos = stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE))
		end

		-- if (isShooting or ball.velMod() < 1000) and Utils.InExclusionZone(getBallPos) then
		if isShooting and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
			-- 当敌方射门的时候或球滚到禁区内停止时
			local kp = 1
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y())
			local idir = function(runner)
				return (ballPos - player.pos(runner)):dir()
			end
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = endVelController(role, goaliePoint) }
			-- return { mexe, mpos, kick.chip, idir, pre.low, power(ballPos, kp), power(ballPos, kp), 0x00000000 }
			return { mexe, mpos, kick.flat, idir, pre.low, power(ballPos,player.num(role) ,kick.flat), power(ballPos,player.num(role),kick.flat) ,0x00000000 }
		elseif ball.velMod() < 1000 and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
			-- 球滚到禁区内停止
			local kp = 1
			-- 守门员需要踢向哪个点
			local targetPos = CGeoPoint(0, 0)

			local idir = function(runner)
				return (targetPos - player.pos(runner)):dir()
			end

			local roleToBallTargetDir = math.abs((ballPos - rolePos):dir())
			local ballToTargetDir = math.abs((targetPos - ballPos):dir())	
			local goaliePoint = CGeoPoint:new_local(getBallPos:x(), getBallPos:y()) + Utils.Polar2Vector(-param.playerRadius+10, ballToTargetDir)
			local Subdir = math.abs(ballToTargetDir-roleToBallTargetDir)
			local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
			if Subdir > 0.14 then 
				local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
				iflag =  DSS_FLAG
			else
				iflag = bit:_or(flag.allow_dss,flag.dribbling) 
			end

			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = iflag, rec = r, vel = v }
			-- return { mexe, mpos, kick.chip, idir, pre.low, power(targetPos, kp), power(targetPos, kp), 0x00000000 }
			return { mexe, mpos, kick.flat, idir, pre.low, power(targetPos, player.num(role) , kick.flat), power(targetPos, player.num(role) ,kick.flat), 0x00000000 }
		else
			-- 准备状态
			-- 这里是当球没有朝球门飞过来的时候，需要提前到达的跑位点
			local roleToEnemyDist = (enemyPos-rolePos):mod()
			local goaliePoint = param.ourGoalPos+Utils.Polar2Vector(param.goalieRadius, goalToEnemyDir)
			-- local goaliePoint = param.ourGoalPos+Utils.Polar2Vector(goalieRadius, goalToEnemyDir)
			if mode==0 then
				goaliePoint = goalieMoveLine:segmentsIntersectPoint(goalToEnemyLine)
			elseif mode==1 then
				goaliePoint = param.ourGoalPos+Utils.Polar2Vector(param.goalieRadius, goalToEnemyDir)
			end
			if roleToEnemyDist<param.goalieAimDirRadius then
				-- 近处需要考虑敌人朝向的问题
				local enemyAimLine = CGeoSegment(enemyPos, enemyPos+Utils.Polar2Vector(param.INF, enemyDir))
				local tPos = goalLine:segmentsIntersectPoint(enemyAimLine)
				-- 判断是否朝向球门
				local isToGoal = -param.penaltySegment-500<tPos:y() and tPos:y()<param.penaltySegment+500

				if isToGoal then
					local tP = tPos+Utils.Polar2Vector(-param.goalieRadius, enemyDir)
					if mode==0 then
						tP = goalieMoveLine:segmentsIntersectPoint(enemyDirLine)
					elseif mode==1 then
						tP = tPos+Utils.Polar2Vector(-param.goalieRadius, enemyDir)
					end
					-- goaliePoint = tP
					-- goaliePoint = CGeoPoint:new_local((tP:x()+goaliePoint:x())/2, (tP:y()+goaliePoint:y())/2)
					goaliePoint = tP
				end
			debugEngine:gui_debug_x(goaliePoint, param.WHITE)
			end
			local idir = player.toPointDir(enemyPos, role)
			local mexe, mpos = GoCmuRush { pos = goaliePoint, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endVelController(role, goaliePoint) }
			return { mexe, mpos }
		end
	end
end





--[[ 盯防 ]]
markingTable = {}
markingTableLen = 0


function defender_marking(role,pos)
	local enemyDribblingNum = GlobalMessage.Tick().their.dribbling_num
	local p
	markingTable = {}
	markingTableLen = 0
	if type(pos) == "function" then
		p = pos()
	else
		p = pos 
	end
	local idir = player.toBallDir(role)
		-- 初始化 获取需要盯防的对象 <= 2
	-- if markingTableLen == 0 and ball.rawPos():x() > param.markingThreshold then 
		for i=0,param.maxPlayer-1 do
			if enemy.valid(i) and i ~= enemyDribblingNum and enemy.posX(i) < param.markingThreshold  then
				markingTable[markingTableLen] = i
				markingTableLen = markingTableLen + 1
				if markingTableLen > 1 then
					break
				end
			end
		end
	-- end
	-- 如果 敌人在前场 ,我方正常跑位
	if markingTableLen == 0 or (markingTableLen == 1 and role == "Special" )  then 
		local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = flag.allow_dss + flag.dodge_ball, rec = r, vel = v }
		return { mexe, mpos }
	else

		if (role == "Kicker") then
			minDistEnemyNum = markingTable[0]
		elseif markingTableLen > 1 then 
			minDistEnemyNum = markingTable[1]
		end
		local ballToEnemyDist = (enemy.pos(minDistEnemyNum) - ball.rawPos()):mod()
		local ballToEnemyDir = (enemy.pos(minDistEnemyNum) - ball.rawPos()):dir()
		if(markingTableLen ~= 0) then
			local dirFlag = enemy.pos(minDistEnemyNum):y() < 0 and 1 or -1
			local markingPos = enemy.pos(minDistEnemyNum) + 
			Utils.Polar2Vector(ballToEnemyDist*param.markingPosRate1, ballToEnemyDir + dirFlag * math.pi / 2 ) + 
			Utils.Polar2Vector(-param.minMarkingDist-ballToEnemyDist*param.markingPosRate2, ballToEnemyDir)
			debugEngine:gui_debug_x(markingPos,4)
			debugEngine:gui_debug_msg(markingPos,"markingPos",4)
			if(not Utils.InField(markingPos)) then
				markingPos = CGeoPoint (player.posX(role),player.posY(role))
			end

			local mexe, mpos = GoCmuRush { pos = markingPos, dir = idir, acc = a, flag = flag.allow_dss, rec = r, vel = v }
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
    		local p0 = Utils.GetBestInterPos(vision, rolePos, 3, 1,0,param.V_DECAY_RATE)
	    	-- 踢球车的准备点
	    	local p1 = CGeoPoint:new_local(flag*param.FIT_PLAYER_POS_X, flag*param.FIT_PLAYER_POS_Y)

    		if player.myinfraredCount(role) < 10 and flag == 1 then
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
			local getBallPos = Utils.GetBestInterPos(vision, rolePos, 3, 1,0,param.V_DECAY_RATE)
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
