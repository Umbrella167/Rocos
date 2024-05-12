
local ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
local balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end
local shoot_pos = CGeoPoint:new_local(param.pitchLength / 2,0)
local error_dir = 8
local KP = 0.00000002
local defendPos = function(role)
	return function()
		local posdefend = enemy.pos(role) + Utils.Polar2Vector(300,(ball.pos() - enemy.pos(role)):dir())
		return CGeoPoint:new_local(posdefend:x(),posdefend:y() )
	end
end
local run_pos = CGeoPoint:new_local(0,0)
local resPos = CGeoPoint(param.pitchLength / 2,0)

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
		local playerPos = CGeoPoint(player.posX("Assister"),player.posY("Assister"))
		local ballRightBuffer = 120
		
		debugEngine:gui_debug_msg(CGeoPoint(0,2800),"BallRights: " .. GlobalMessage.Tick.ball.rights)
		debugEngine:gui_debug_msg(CGeoPoint(0,2600),"InfraredCount: " .. player.myinfraredCount("Assister"),2)


		debugEngine:gui_debug_msg(CGeoPoint(0,2400),"BallPos: " .. ball.pos():x() .. "    " .. ball.pos():y() ,3)
		debugEngine:gui_debug_msg(CGeoPoint(0,2200),"ToBallDist: " .. player.toBallDist("Assister") ,4)
		
		debugEngine:gui_debug_msg(CGeoPoint(0,2000),"BallValid: " .. tostring(ball.valid()),5)

		debugEngine:gui_debug_arc(ball.pos(),47,0,360,4)
		debugEngine:gui_debug_x(ball.pos(),4,0,15)
		debugEngine:gui_debug_arc(player.pos("Assister"),ballRightBuffer,0,360,4)

		local confidence_getball = Utils.ConfidenceGetBall(vision,player.num("Assister"));
		debugEngine:gui_debug_msg(CGeoPoint(0,1800),"ConfidenceGetBall: " .. tostring(confidence_getball),6)


		local getballPos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,param.getballMode,0,param.V_DECAY_RATE)
		debugEngine:gui_debug_x(getballPos,4)
		debugEngine:gui_debug_msg(getballPos,"GetballPos ",4)
		local playerPos = CGeoPoint:new_local(player.pos("Assister"):x(),player.pos("Assister"):y()) 
		local mouthPos = playerPos + Utils.Polar2Vector(param.playerFrontToCenter,player.dir("Assister"))
		debugEngine:gui_debug_x(mouthPos,4)

	end,

	Assister = task.stop(), 
	-- Assister = task.getball(function() return shoot_pos end,param.playerVel,param.getballMode),
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
