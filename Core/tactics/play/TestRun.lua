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


firstState = "run1",
["run1"] = {
	switch = function()
		Utils.GlobalComputingPos(vision)

		-- return "run11"
	end,
	Assister = task.getball("Assister",3,inter_flag,CGeoPoint:new_local(0,0)),
	Kicker = task.stop(),
	match = "[AK]"
},




["run2"] = {
	switch = function()
		if bufcnt(player.toTargetDist("Kicker")<5,time) then
			return "run"..1
		end
	end,
	Kicker = task.goCmuRush(testPos[3],math.pi, _, DSS_FLAG),
	-- Kicker = task.goBezierRush(testPos[4],math.pi, _, DSS_FLAG, _, vel),
	match = ""
},
["run3"] = {
	switch = function()
		if bufcnt(player.toTargetDist("Kicker")<5,time) then
			return "run"..4
		end
	end,
	Kicker = task.goCmuRush(testPos[2],0, _, DSS_FLAG),
	-- Kicker = task.goBezierRush(testPos[1],0, _, DSS_FLAG, _, vel),
	match = ""
},
["run4"] = {
	switch = function()
		if bufcnt(player.toTargetDist("Kicker")<5,time) then
			return "run"..1--math.random(4)
		end
	end,
	Kicker = task.goCmuRush(testPos[4],math.pi, _, DSS_FLAG),
	-- Kicker = task.goBezierRush(testPos[2],math.pi, _, DSS_FLAG, _, vel),
	match = ""
},

name = "TestRun",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
