module(..., package.seeall)

--~		Play中统一处理的参数（主要是开射门）
--~		1 ---> task, 2 ---> matchpos, 3---->kick, 4 ---->dir,
--~		5 ---->pre,  6 ---->kp,       7---->cp,   8 ---->flag
------------------------------------- 射门相关的skill ---------------------------------------
-- TODO
------------------------------------ 跑位相关的skill ---------------------------------------
--~ p为要走的点,d默认为射门朝向


InterPos = CGeoPoint:new_local(0,0)
function Inter(ourSpeed)
	InterPos = Utils.GetInterPos(vision,playerpos("Assister"),ourSpeed)
end

function goalie()
	local mexe, mpos = Goalie()
	return {mexe, mpos}
end
function touch()
	local ipos = pos.ourGoal()
	local mexe, mpos = Touch{pos = ipos}
	return {mexe, mpos}
end
function touchKick(p,ifInter,power,mode)
	local ipos = p or pos.theirGoal()
	local idir = function(runner)
		return (_c(ipos) - player.pos(runner)):dir()
	end
	local mexe, mpos = Touch{pos = ipos, useInter = ifInter}
	local ipower = function()
		return power or 127
	end
	return {mexe, mpos, mode and kick.flat or kick.chip, idir, pre.low, ipower, cp.full, flag.nothing}
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
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = iflag}
	return {mexe, mpos}
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

	local mexe, mpos = SimpleGoto{pos = p, dir = idir, flag = iflag}
	return {mexe, mpos}
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

	local mexe, mpos = RunMultiPos{ pos = p, close = c, dir = idir, flag = f, dist = d, acc = a}
	return {mexe, mpos}
end

function staticGetBall(target_pos, dist)
	local idist = dist or 140
	local p = function()
		local target = _c(target_pos) or pos.theirGoal()
		return ball.pos() + Utils.Polar2Vector(idist,(ball.pos()-target):dir())
	end
	local idir = function()
		local target = _c(target_pos) or pos.theirGoal()
		return (target - ball.pos()):dir()
	end
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, flag = flag.dodge_ball}
	return {mexe, mpos}
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
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v, speed = s, force_manual = force_manual}
	return {mexe, mpos}
end

function forcekick(p,d,chip,power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos, ikick, idir, pre.low, kp.specified(ipower), cp.full, flag.forcekick}
end





function shoot(p,d,chip,power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos, ikick, idir, pre.low, kp.specified(ipower),kp.specified(ipower), flag.nothing}
end
------------------------------------ 防守相关的skill ---------------------------------------
-- TODO
----------------------------------------- 其他动作 --------------------------------------------

-- p为朝向，如果p传的是pos的话，不需要根据ball.antiY()进行反算
function goBackBall(p, d)
	local mexe, mpos = GoCmuRush{ pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = flag.dodge_ball}
	return {mexe, mpos}
end

-- 带避车和避球
function goBackBallV2(p, d)
	local mexe, mpos = GoCmuRush{ pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = bit:_or(flag.allow_dss,flag.dodge_ball)}
	return {mexe, mpos}
end

function stop()
	local mexe, mpos = Stop{}
	return {mexe, mpos}
end

function continue()
	return {["name"] = "continue"}
end

------------------------------------ 测试相关的skill ---------------------------------------

function openSpeed(vx, vy, vw, iflag)
	local mexe, mpos = OpenSpeed{speedX = vx, speedY = vy, speedW = vw, flag = iflag}
	return {mexe, mpos}
end


------------------------------------ 接球相关的skill ---------------------------------------



--V4 使用条件：当球在运动过程时       效果：能够精准的到合适的地方接球   通常用在传球的时候接球人上
function Getballv4(role,p)
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
			local ball_line = CGeoLine:new_local(ball.pos(),ball.velDir())
			local target_pos = ball_line:projection(player.pos(role))
			local mexe, mpos = GoCmuRush{pos = target_pos, dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
			return {mexe, mpos}
		else 
			local mexe, mpos = GoCmuRush{pos = p1, dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
			return {mexe, mpos}
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