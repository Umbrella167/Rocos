gPlayTable.CreatePlay{
firstState = "halt",
switch = function()
	-- debugEngine:gui_debug_msg(CGeoPoint(0,0),task.getManMarkEnemy())
	-- return "halt"
end,
["halt"] = {
	
	["Leader"]   = task.stop(),
	["Special"]  = task.stop(),
	["Assister"] = task.stop(),
	["Defender"] = task.stop(),
	["Middle"]   = task.stop(),
	["Center"]   = task.stop(),
	["Breaker"]  = task.stop(),
	["Goalie"]   = task.stop(),
	match = "[LSADMCB]"
},

name = "HALT",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
