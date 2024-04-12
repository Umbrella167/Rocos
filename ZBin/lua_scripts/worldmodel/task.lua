module(..., package.seeall)

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

-- dribbling_player_num = 1
-- ballRights = -1
-- shoot_pos = CGeoPoint:new_local(0,0)
-- function UpdataTickMessage(defend_num1,defend_num2)
-- 	GlobalMessage.Tick = Utils.UpdataTickMessage(vision,defend_num1,defend_num2)
-- 	dribbling_player_num = GlobalMessage.Tick.our.dribbling_num
-- 	ball_rights = GlobalMessage.Tick.ball.rights
-- 	if ball_rights == 1 then
-- 		shoot_pos = GlobalMessage.Tick.task[dribbling_player_num].shoot_pos
-- 		shoot_pos = CGeoPoint(shoot_pos:x(),shoot_pos:y())
-- 	end
-- end
-- function getShootPos()
-- 	return shoot_pos
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
			local flag = inter_flag or 0
			local playerPos = CGeoPoint:new_local( player.pos(role):x(),player.pos(role):y())
			local inter_pos = Utils.GetBestInterPos(vision,playerPos,playerVel,flag)
			
			local idir = player.toBallDir(role)
			local ipos = ball.pos()
			if inter_pos:x()  ==  param.INF or inter_pos:y()  == param.INF then
				ipos = ball.pos()
			else
				ipos = inter_pos
			end
			local endvel = Utils.Polar2Vector(800,player.toBallDir(role))
			ipos = CGeoPoint:new_local(ipos:x(),ipos:y())
			local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = endvel }
				return { mexe, mpos }
		else
			local idir = (p1 - player.pos(role)):dir()
			local pp = player.pos(role) + Utils.Polar2Vector(0 + 10, idir)
			local mexe, mpos = GoCmuRush { pos = pp, dir = idir, acc = 50, flag = 0x00000100 + 0x04000000, rec = 1, vel = v }
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

		if res > 7000 then
			res = 7000
		end
		if res < 3400 then
			res = 3400
		end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4300,-2000),"Power" .. res,3)
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

function Getballv4(role, p)
	--参数说明
	--role   使用这个函数的角色
	--p	     等待位置
	return function()
		local p1 = p
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end
		if ball.velMod() > 1000 then
			local ball_line = CGeoLine:new_local(ball.pos(), ball.velDir())
			local target_pos = ball_line:projection(player.pos(role))
			local mexe, mpos = GoCmuRush { pos = target_pos, dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
			-- elseif ball.velMod() > 2000 and ball.velMod() < 2000  and (ball.pos() - player.pos(role)):mod() > 150 then
			-- 	local mexe, mpos = GoCmuRush{pos = ball.pos() + Utils.Polar2Vector(100,(player.pos(role) - ball.pos()):dir()), dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
			-- 	return {mexe, mpos}
		else
			local mexe, mpos = GoCmuRush { pos = p1, dir = (ball.pos() - player.pos(role)):dir(), acc = 1300, flag = 0x00000100, rec = r, vel = v }
			return { mexe, mpos }
		end
	end
end


function GetBallV5(role, p, target)
--参数说明
--role  	  使用这个函数的角色
--p      	  拿到球后跑去目标点
--target      朝向的点
    return function()
        local minDist = 9999999
        local ballspeed = 800

        if type(p) == 'function' then
            p = p()
        end
        if type(target) == 'function' then
            target = target()
        end

        
        if(player.infraredCount(role) < 20) then 
        	-- 拿球
            local idir = (ball.pos() - player.pos(role)):dir()
            local pp = ball.pos() + Utils.Polar2Vector(10,idir)
            if ball.velMod() > ballspeed and minDist > 180 then
                pp = ball.pos() + Utils.Polar2Vector(350,idir)
            end
            local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
            return {mexe, mpos}
        else

        	if player.toPointDist(role, p) > 10 then
        	 	-- 拿到球后跑点
	            local idir = (ball.pos() - player.pos(role)):dir()
	            local pp = p
	            local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
            	return {mexe, mpos}
        	else
        		-- 到点后指向
        		local idir = (target - player.pos(role)):dir()
	            local pp = p
	            local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
	            return {mexe, mpos}
        	end

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
			speed = 300
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
		-- NOTE: 这里两个if都不成立时没有写额外的操作，需要自行判断退出
	end
		
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

function Shootdot(p, Kp, error_, flag)
	--将球射向某一个点（会动态规划射门力度）
	--p 目标点
	--ifInter参数就填false
	--Kp 力度系数
	--error_ 误差
	--flag:kick.chip or kick.flat By Umbrella 2022 07
	return function()
		local p1
		if type(p) == 'function' then
			p1 = p()
		else
			p1 = p
		end

		local ipos = p1 or pos.theirGoal()
		local idir = function(runner)
			return (ipos - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
		local mexe, mpos = Touch { pos = p, useInter = false }
		return { mexe, mpos, flag, idir, error__, power(p, Kp), power(p, Kp), 0x00000000 }
	end
end

function playerDirToPointDirSub(role, p) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
		p1 = p()
	else
		p1 = p
	end

	local playerDir = player.dir(role) * 57.3 + 180
	local playerPointDit = (p1 - player.pos(role)):dir() * 57.3 + 180
	local sub = math.abs(playerDir - playerPointDit)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000, 0), sub)
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

function goalie()
	local mexe, mpos = Goalie()
	return { mexe, mpos }
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
	local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
	return { mexe, mpos, ikick, idir, pre.low, kp.specified(ipower), cp.full, flag.nothing }
end

------------------------------------ 防守相关的skill ---------------------------------------
-- Defender

function trackingDefenderPos(posType)
	return function()
		local mexe, mpos = nil, nil
		local p, idir = nil, dir.shoot()
		local hitPoint = Utils.ComputeCrossPENALTY()
		local distanceDT = Utils.ComputeDistance(hitPoint)
		local POS_NULL = CGeoPoint:new_local(0, 0)

		debugEngine:gui_debug_msg(
			CGeoPoint:new_local(DEFENDER_DEBUG_POSITION_X,
				DEFENDER_DEBUG_POSITION_Y),
			tostring(distanceDT))

		if hitPoint ~= POS_NULL then
			if "l" == posType then
				p = CGeoPoint:new_local(hitPoint:x(),
					hitPoint:y() + distanceDT / 2 < 2000 and hitPoint:y() + distanceDT / 2 or 2000)
			elseif "m" == posType then
				p = CGeoPoint:new_local(hitPoint:x(), hitPoint:y())
			elseif "r" == posType then
				p = CGeoPoint:new_local(hitPoint:x(),
					hitPoint:y() - distanceDT / 2 > -2000 and hitPoint:y() - distanceDT / 2 or -2000)
			end

			mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v, speed = s, force_manual = force_manual }
			return { mexe, mpos }
		end
	end
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
maxPower = 1000
powerStep = 200
playerCount = 0
fitPlayer1 = -1
fitPlayer2 = -1
function fitPower(i)
	return function()
		return kickPower[i]
	end
end

function getFitData_runToPos(role)
	return function()
		-- 当前角色
		local playerNum = player.num(role)
		local fitPlayerLen = 0
		local fitPlayerList = {}
		
		local i = 0
		-- debugEngine:gui_debug_msg(CGeoPoint(-3000, 2800-(200*playerNum)),string.format("%s playerNum:            %d", role, playerNum))
		for i=0,param.maxPlayer-1 do
			debugEngine:gui_debug_msg(CGeoPoint(-4500, 2800-(200*i)),"kickPower: "..tostring(kickPower[i]).."  "..tostring(i))
			if kickPower[i] < 0 or kickPower[i] > maxPower then
				-- continue
			else
				fitPlayerList[fitPlayerLen] = i
				fitPlayerLen = fitPlayerLen + 1
			end
		end

		-- debugEngine:gui_debug_msg(CGeoPoint(100, 100), tostring(fitPlayerList[0]))


		-- 打印需要测试的车
		-- for i=0, fitPlayerLen-1 do
		-- 	debugEngine:gui_debug_msg(CGeoPoint(-6000, 2800-(200*i)),"player: "..tostring(fitPlayerList[i]).."  "..tostring(i))
		-- end

		-- 角色选择器
		if fitPlayerLen > 1 then
			fitPlayer1 = fitPlayerList[0]
			fitPlayer2 = fitPlayerList[1] 
		elseif playerCount > 1 then
			-- 这个还没有测试过
			fitPlayer1 = fitPlayerList[0]
			for i=0,param.maxPlayer-1 do
				if kickPower[i] < 0 then
					-- continue
				else
					fitPlayer2 = i
					break
				end
			end
		else
			debugEngine:gui_debug_msg(CGeoPoint(-3000, -3000), "车不够多") 
			-- 测到最后一台车的时候fitPlayer2会为空，要额外判断, 还没写
		end
    	
    	if playerNum == fitPlayer1 or playerNum == fitPlayer2 then
    		-- 跑去接踢位

    		-- 标记踢球人 1 - 踢球		-1 - 接球
    		flag = playerNum == fitPlayer1 and 1 or -1
    		-- 拿球点
    		p0 = CGeoPoint:new_local(ball.posX(), ball.posY())
	    	-- 踢球车的准备点
	    	p1 = CGeoPoint:new_local(flag*param.pitchLength/2-flag*param.penaltyDepth-flag*param.penaltySegment, 0)

    		if player.infraredCount(role) < 10 and flag == 1 then
    			-- 踢球人如果没有拿到球，就去拿球
	    		local idir = player.toPointDir(p0, role)
				local mexe, mpos = GoCmuRush { pos = p0, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif player.toPointDist(role, p1) > param.playerRadius then
				-- 非踢球人去固定点
	    		local idir = (CGeoPoint(0, 0) - player.pos(role)):dir()
				local mexe, mpos = GoCmuRush { pos = p1, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif ball.velMod() > 20 then
				-- 稳定球
				local idir = (CGeoPoint(0, 0) - player.pos(role)):dir()
				local mexe, mpos = GoCmuRush { pos = p1, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
				return { mexe, mpos }
			elseif flag == 1 then


				kickPower[fitPlayer1] = kickPower[fitPlayer1] + powerStep

				-- 踢球
				debugEngine:gui_debug_msg(CGeoPoint(-4000, -4500), "role: "..role)
				-- local idir = (CGeoPoint(0, 0) - player.pos(role)):dir()
				-- local error__ = function()
				-- 	return error_ * math.pi / 180.0
				-- end
				debugEngine:gui_debug_msg(CGeoPoint(-4000, -4000), "fitPower: "..tostring(kickPower[playerNum]))
				-- local mexe, mpos, flag, idir, t_low, t_p, t_p, t_f = shoot(p1, idir, kick.flat, fitPower(playerNum))
				-- return { mexe, mpos, kick.flat, idir, t_low, fitPower(playerNum), fitPower(playerNum), 0x00000000 }

    		





    		end
		else
    		-- 跑去待机位
    		p = CGeoPoint(param.pitchWidth/2-param.playerRadius*3*playerNum, param.pitchLength/2-1500)
    		idir = 0
			local mexe, mpos = GoCmuRush { pos = p, dir = idir, acc = a, flag = f, rec = r, vel = v }
			return { mexe, mpos }
    	end
	end
end
