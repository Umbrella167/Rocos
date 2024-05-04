
local ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
local balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end
local shoot_pos = CGeoPoint:new_local(4500,0)
local error_dir = 8
local KP = 0.00000002
local defendPos = function(role)
	return function()
		local posdefend = enemy.pos(role) + Utils.Polar2Vector(300,(ball.pos() - enemy.pos(role)):dir())
		return CGeoPoint:new_local(posdefend:x(),posdefend:y() )
	end
end
local run_pos = CGeoPoint:new_local(0,0)
local resPos = CGeoPoint(4500,0)

local runPos = function()
	return function()
		return CGeoPoint:new_local(run_pos:x(),run_pos:y())
	end
end

gPlayTable.CreatePlay{

firstState = "ready1",

["ready1"] = {
	switch = function()

		GlobalMessage.Tick = Utils.UpdataTickMessage(vision,0,1,2)
		debugEngine:gui_debug_msg(CGeoPoint(0,2800),"ballRights: " .. GlobalMessage.Tick.ball.rights)
		debugEngine:gui_debug_msg(CGeoPoint(0,2600),"InfraredCount: " .. player.myinfraredCount(0),2)
		debugEngine:gui_debug_msg(CGeoPoint(0,2400),"RawBallPos: " .. ball.rawPos():x() .. "    " .. ball.rawPos():y() ,3)
		debugEngine:gui_debug_msg(CGeoPoint(0,2200),"BallPos: " .. ball.pos():x() .. "    " .. ball.pos():y() ,4)
	end,

	Assister = task.stop(), 
	match = "[A]"
},



name = "TestballRightAndInfraed",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
