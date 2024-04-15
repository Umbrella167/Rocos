
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end

gPlayTable.CreatePlay{

firstState = "ready1",
["ready1"] = {
	switch = function()
	end,

	Assister = task.TurnRun( CGeoPoint(150,120),5),
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
