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
	return CGeoPoint:new_local(player.posX(role),player.posY(role))
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

local shootGen = function(dist)
	return function()
		local goalPos = CGeoPoint(param.pitchLength/2,0)
		local pos = ball.pos() + Utils.Polar2Vector(dist,(ball.pos() - goalPos):dir())
		return pos
	end
end
gPlayTable.CreatePlay{


firstState = "initPos",
["initPos"] = {
	switch = function()
		Utils.InitFitFunction(vision)


		-- return "run11"
	end,
	-- Assister = 
	Assister = task.staticGetBall(),
	Kicker = task.goCmuRush(CGeoPoint(-4000, -2000)),
	match = "[AK]"
},
-- ["run11"] = {
-- 	switch = function()

-- 		Utils.InitFitFunction()
-- 		if (player.kickBall("Assister")) then --bufcnt(a,b) 当表达式a为true时 连续累积 b帧 返回true
-- 			return "run1"
-- 		end
-- 	end,
-- 	Assister = task.stop(),--task.shoot(shootGen(0),dir1("Assister"),_,320),

-- 	match = "[AK]"
-- 	-- ()  []  {}
-- },


name = "TestFit",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
