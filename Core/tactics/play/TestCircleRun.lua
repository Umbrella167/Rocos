
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end


local rotNewPos = function()


end 


gPlayTable.CreatePlay{

firstState = "ready1",
["ready1"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
	end,

	Assister = task.TurnRun(CGeoPoint(80,80),4),
	match = "[A]"
},


name = "TestCircleRun",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
