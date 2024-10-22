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

function get_best_point()
	x = GlobalMessage.Tick().best_point.x
	y = GlobalMessage.Tick().best_point.y
	return CGeoPoint:new_local(x, y)
end

gPlayTable.CreatePlay{

firstState = "run1",

["run1"] = {
	
	switch = function()
		

	end,
	Assister = task.goCmuRush(get_best_point(),0, nil, DSS_FLAG),
	match = "[A]"
},


name = "TestRun",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
