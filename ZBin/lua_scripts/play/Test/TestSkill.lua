local f = flag.dribbling
local p = CGeoPoint:new_local(4500,0)
gPlayTable.CreatePlay{

firstState = "t",
["t"] = {
	switch = function()
	end,
	Leader = task.stop(),
	match = "[L]"
},

name = "TestSkill",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
