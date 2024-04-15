return {
-- gPlayTable.CreatePlay{
firstState = "Init",

["Init"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(CGeoPoint(0, 0), enemy.closestBall())
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1300), enemy.atBallLine())
		-- if bufcnt(true,20) then
		return "run1"
		-- end 
	end,
	-- Assister = task.stop(),
	-- Kicker = task.stop(),
	-- Special = task.stop(),
	-- Tier = task.stop(),
	-- Defender = task.stop(),
	Goalie = task.goalie("Goalie"),
	match = "[A][KS]{TDG}"
},
["run1"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(CGeoPoint(0, 0), enemy.closestBall())
		-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1300), enemy.atBallLine())
		-- if bufcnt(true,20) then
		-- return "run1"
		-- end 
	end,
	-- Assister = task.stop(),
	-- Kicker = task.stop(),
	-- Special = task.stop(),
	-- Tier = task.defender("Tier"),
	-- Defender = task.defender("Defender"),
	Goalie = task.goalie("Goalie"),
	-- Goalie = task.goCmuRush(runPos, 0, nil, DSS_FLAG),
	match = "[A][KS]{TDG}"
},

name = "mytest3",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
