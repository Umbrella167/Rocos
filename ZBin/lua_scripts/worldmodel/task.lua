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

function getball(role, playerVel, inter_flag, target_point)
	return function()
		if player.infraredCount(role) < 5 then
			local flag = inter_flag or 0
			local playerPos = CGeoPoint:new_local(player.pos(role):x(), player.pos(role):y())
			local inter_pos = Utils.GetBestInterPos(vision, playerPos, playerVel, flag)

			local idir = player.toBallDir(role)
			local ipos = ball.pos()
			if inter_pos:x() == -param.INF or inter_pos:y() == -param.INF then
				ipos = ball.pos()
			else
				ipos = inter_pos
			end
			ipos = CGeoPoint:new_local(ipos:x(), ipos:y())
			local mexe, mpos = GoCmuRush { pos = ipos, dir = idir, acc = a, flag = 0x00000100, rec = r, vel = v }
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
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4300, -2000), res, 3)
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

function TurnToPoint(role, p)
	--参数说明
	--role   使用这个函数的角色
	--p	     指向坐标
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

--[[ 盯防 ]]
function defender_marking(role)
	return function()
		Utils.UpdataTickMessage(vision, DEFENDER_NUM1, DEFENDER_NUM2)

		local mexe, mpos = nil, nil
		local ipos, idir = "Defender" == role and DEFENDER_INITPOS_DEFENDER or DEFENDER_INITPOS_TIER,
			player.toBallDir(role)

		local ROLE_DEFENDER = "Defender"
		local ROLE_TIER = "Tier"
		local role_major = player.toBallDist(ROLE_DEFENDER) < player.toBallDist(ROLE_TIER) and ROLE_DEFENDER
			or ROLE_TIER -- defender
		-- FIXME: 这里容易出一个bug，如果在运动中导致两个后卫距离 ball 的距离差不多，会导致两个后卫被“互相卡住”
		local role_minor = role_major == ROLE_DEFENDER and ROLE_TIER
			or ROLE_DEFENDER -- tier

		if player.toBallDist(role) < 500 then
			local ipos = pos.theirGoal()
			-- NOTE: 会有更好的解决办法放置卡禁区 1/2
			local idir = function(runner) return (_c(ipos) - player.pos(runner)):dir() end
			local mexe, mpos = Touch { pos = ipos, useInter = ifInter }
			local ipower = function()
				return power or 127
			end
			return { mexe, mpos, mode and kick.flat or kick.chip, idir, pre.low, ipower, cp.full, flag.nothing }
		else
			local closestEnemy = -- 最近的敌人位置，但是排除了守门员
				Utils.closestPlayerToPoint(vision,
					role_minor == ROLE_DEFENDER and DEFENDER_INITPOS_DEFENDER or DEFENDER_INITPOS_TIER, 2,
					player.num(role))


			if nil ~= closestEnemy then                                                -- 如果检测到有可能有敌人出现，那么需要回防
				if player.toPointDist(role, closestEnemy) < DEFENDER_SAFEDISTANCE then -- 并且可能产生威胁 NOTE: 可以继续升级算法 1/2
					ipos = closestEnemy +
						Utils.Polar2Vector(DEFENDER_SAFEDISTANCE / 4, (ball.pos() - closestEnemy):dir()) -- 盯防一波
				end
			end
			ipos = enemy.pos(role) + Utils.Polar2Vector(300, (ball.pos() - enemy.pos(role)):dir())
			mexe, mpos = GoCmuRush { pos = ipos, dir = idir }
		end
		return { mexe, mpos }
	end
end

--[[ 防守 ]]
function defender_defence(role)
	return function()
		Utils.UpdataTickMessage(vision, DEFENDER_NUM1, DEFENDER_NUM2)

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
				-- NOTE: 会有更好的解决办法放置卡禁区 2/2
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
			local hitPoint = Utils.DEFENDER_ComputeCrossPenalty()
			local POS_NULL = CGeoPoint:new_local(0, 0)

			if hitPoint ~= POS_NULL then
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

-- debugEngine:gui_debug_msg(CGeoPoint:new_local(DEFENDER_DEBUG_POSITION_X, DEFENDER_DEBUG_POSITION_Y),
-- 	closestEnemy:x() .. ", " .. closestEnemy:y())

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
