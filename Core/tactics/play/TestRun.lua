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

gPlayTable.CreatePlay{

firstState = "run1",

["run1"] = {
	switch = function()
		task.Inter()
		-- if ball.velMod() / 1000 > 2 then
		-- 	task.Inter()
		-- 	return "run11"
		-- end
		--debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),Utils.GetInterPos(vision,playerpos("Assister"),3):y())
	end,
	Assister = task.stop(),
	match = "[A]"
},



["run11"] = {
	switch = function()

		--debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),Utils.GetInterPos(vision,playerpos("Assister"),3):y())
	end,
	Assister = task.goCmuRush(pos1()),
	match = "[A]"
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
