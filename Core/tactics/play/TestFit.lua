local testPos  = {
	CGeoPoint:new_local(1000,1000),
	CGeoPoint:new_local(-1000,1000),
	CGeoPoint:new_local(-1000,-1000),
	CGeoPoint:new_local(1000,-1000)
}
local vel = CVector:new_local(0, 0)
local maxvel=0
local time = 120
local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)

playerpos = function (role)
	return function()
		return CGeoPoint:new_local(player.posX(role),player.posY(role))
	end
end
pos1 = function()
	return function()
		return task.InterPos
	end
end
-- 闭包
dir1 = function(role)
	return function(role)
		return (ball.pos() - player.pos(role)  ):dir()
	end
end
toBallDir = function(role)
	return player.toBallDir(role)
end
ballPos = function()
	return ball.pos()
end



local shootGen = function(dist)
	return function()
		local goalPos = CGeoPoint(param.pitchLength/2,0)
		local pos = ball.pos() + Utils.Polar2Vector(dist,(ball.pos() - goalPos):dir())
		return pos
	end
end
local shootTo = function(role1, role2)
	return function()
		local goalPos = player.pos(role2)
		local pos = ball.pos() + Utils.Polar2Vector(dist,(ball.pos() - goalPos):dir())
		return pos
	end
end



-- 有用到的

max_power = 6000 		--最大力度
min_power = 2000 		--最小力度
split_num = 10   		--分割次数
label = 0

power = function(i)
	t = (max_power - min_power) / split_num
	return min_power + t*i
end

toPlayerDir = function(role1, role2)
	return player.toPlayerDir(role1, role2)
end

-- 判断是否对准
local function judgePlayerDir(role,targetPos,error)
	local p = targetPos
	if type(p) == 'function' then
	  	p = p()
	else
	  	p = p
	end

    if math.abs(player.dir(role) - (p - player.pos( role )):dir()) < error then
        return true
    else 
        return false
    end
end
-- 准备的点
readyPos = function(role)
	return function()
		if player.toPointDist(role, CGeoPoint(4000, 2000)) < player.toPointDist(role, CGeoPoint(-4000, -2000)) then
			return CGeoPoint(4000, 2000)
		else
			return CGeoPoint(-4000, -2000)
		end
	end
end


gPlayTable.CreatePlay{

firstState = "init",
["init"] = {
	switch = function()
		if player.toBallDist("Assister") < player.toBallDist("Kicker") then
			return "A_run_to_pos"
		else
			return "K_run_to_pos"
		end
	end,
	Assister = task.stop(),
	Kicker = task.stop(),
	match = "(AK)"
},
["A_run_to_pos"] = {
	switch = function()
		if judgePlayerDir("Assister", readyPos("Kicker"), 0.08) and player.toTargetDist("Assister") < 10 then
			return "ready_to_shoot"
		end
	end,
	Assister = task.GetBallV5("Assister", readyPos("Assister"), readyPos("Kicker")),
	Kicker = task.goCmuRush(readyPos("Kicker"), toPlayerDir("Kicker", "Assister")),
	match = "{AK}"
},
["K_run_to_pos"] = {
	switch = function()
		-- Utils.InitFitFunction(vision)
		if judgePlayerDir("Kicker", readyPos("Assister"), 0.08) and player.toTargetDist("Kicker") < 10 then
			return "ready_to_shoot"
		end
	end,
	Assister = task.goCmuRush(readyPos("Assister"), toPlayerDir("Assister", "Kicker")),
	Kicker = task.GetBallV5("Kicker", readyPos("Kicker"), readyPos("Assister")),
	match = "{AK}"
},
["ready_to_shoot"] = {
	switch = function()
		if bufcnt(true, "slow") then
			if player.toBallDist("Assister") < player.toBallDist("Kicker") then
				return "A_shoot_ball"
			else
				return "K_shoot_ball"
			end
		end
		
	end,
	Assister = task.stop(),
	Kicker = task.stop(),
	match = "{AK}"
},
["A_shoot_ball"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0), label)
		debugEngine:gui_debug_msg(CGeoPoint(100,100), power(label))
		if player.kickBall("Assister") then
			label = label + 1
			return "recording"
		end
	end,
	Assister = task.shoot(readyPos("Assister"),toPlayerDir("Kicker"),_,power(label)),
	Kicker = task.Getballv4("Kicker", readyPos("Kicker")),
	match = "{AK}"
},
["K_shoot_ball"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0), label)
		debugEngine:gui_debug_msg(CGeoPoint(100,100),power(label))
		if player.kickBall("Kicker") then
			label = label + 1
			return "recording"
		end
	end,
	Assister = task.Getballv4("Assister", readyPos("Assister")),
	Kicker = task.shoot(readyPos("Kicker"), toPlayerDir("Assister"),_,power(label)),
	match = "{AK}"
},
["recording"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0), label)
		debugEngine:gui_debug_msg(CGeoPoint(100,100), power(label))
		if ball.velMod() < 100 then
			return "init"
		end
	end,
	Assister = task.Getballv4("Assister", readyPos("Assister")),
	Kicker = task.Getballv4("Kicker", readyPos("Kicker")),
	match = "{AK}"
},
name = "TestFit",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
