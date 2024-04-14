gPlayTable.CreatePlay{

firstState = "Init",


["Init"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(CGeoPoint(0, 0), enemy.closestBall())
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1300), enemy.atBallLine())
		-- if bufcnt(true,20) then
		-- 	return "GetGlobalMessage"
		-- end 
	end,
	Assister = task.stop(),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie("Goalie"),
	match = "[A][KS]{TDG}"
},


name = "mytest2",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
