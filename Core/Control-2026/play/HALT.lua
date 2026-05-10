gPlayTable.CreatePlay{
firstState = "halt",
switch = function()
	-- debugEngine:gui_debug_msg(CGeoPoint(0,0),task.getManMarkEnemy())
	-- return "halt"
	debugEngine:gui_debug_msg(CGeoPoint(-2000,0),"暂停-不许动 ",1,0,500)

end,
["halt"] = {

	["Kicker"]   = task.stop(),
	["Special"]  = task.stop(),
	["Assister"] = task.stop(),
	["Center"] = task.stop(),
	["Defender"]   = task.stop(),
	["Goalie"]   = task.stop(),
	match = "[AKSC]{DG}"
},

name = "HALT",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
