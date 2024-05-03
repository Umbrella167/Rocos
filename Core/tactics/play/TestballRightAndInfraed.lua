
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
		return CGeoPoint:new_local( posdefend:x(),posdefend:y() )
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
		debugEngine:gui_debug_msg(CGeoPoint(1000, 1000), player.dir("Goalie"))

		GlobalMessage.Tick = Utils.UpdataTickMessage(vision,0,1,2)
		-- debugEngine:gui_debug_msg(CGeoPoint(0,0),task.angleDiff((ball.pos() - player.pos("Assister")):dir(),(player.pos("Assister") - CGeoPoint(0,0)):dir()))
		-- if(player.infraredCount("Assister") > 5) then
		-- 	return "shoot"
		-- end
		
	end,

	Assister = task.goCmuRush(CGeoPoint(3671,1148)), 
	-- Assister = task.getballV2("Assister", param.playerVel, 1, CGeoPoint(0, 0), 0),
	-- Kicker = task.getball("Assister",param.playerVel,param.getballMode,CGeoPoint:new_local(0,0)), 
	-- Kicker = function() return task.defender_marking("Kicker",CGeoPoint(0,0)) end,
	match = "[A]"
},



["shoot"] = {
	switch = function()
		if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
		local Vy = player.rotVel("Assister")
		local ToTargetDist = player.toPointDist("Assister",shoot_pos)
		resPos = task.compensateAngle(Vy,shoot_pos,ToTargetDist * 0.07)
		
		if(task.playerDirToPointDirSub("Assister",resPos) < 4) then 
			return "shoot1"
		end

		
	end,
	 -- = task.TurnRun("Assister"),
	Assister = function() return (task.TurnToPointV2("Assister",function() return resPos end ,param.rotVel)) end,
	-- match = "[AKS]{TDG}"
	match = "[A]"
},


["shoot1"] = {
	switch = function()
if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
	end,
	 -- = task.TurnRun("Assister"),
	Assister = task.ShootdotV2(function() return resPos end,10,8,kick.flat),
	-- match = "[AKS]{TDG}"
	match = "[A]"
},
["dribbling"] = {
	switch = function()
		Utils.UpdataTickMessage(vision,1,2)
		run_pos = Utils.GetShowDribblingPos(vision,CGeoPoint:new_local(player.pos("Assister"):x(),player.pos("Assister"):y()),CGeoPoint(0,0))

		if(bufcnt(true,35)) then 
			return "ready"
		end
	end,
	Assister = task.goCmuRush(runPos(),balldir(),800,flag.dribbling),

	match = "[AKS]{TDG}"
},


-- ["touch"] = {
-- 	switch = function()
-- 		-- Utils.UpdataTickMessage(vision,1,2)
-- 		-- Utils.GlobalComputingPos(vision)

-- 	end,
-- 	Assister = task.touchKick("Assister",CGeoPoint(4500,0)),

-- 	match = "[AKS]{TDG}"
-- },

-- ["readyShoot"] = {
-- 	switch = function()
-- 		Utils.GetTouchPos(vision,CGeoPoint:new_local(ball.posX(),ball.posY()))
-- 		-- local pos1 = Utils.GetBestInterPos(vision,playerPos(),4,2)
-- 		-- debugEngine:gui_debug_x(pos1,3)
-- 		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),pos1:x() .. "  " .. pos1:y())
-- 		-- Utils.UpdataTickMessage(vision,1,2)
-- 		-- Utils.GlobalComputingPos(vision)
-- 		-- aa = player.canTouch("Assister",CGeoPoint:new_local(4500,0))
-- 		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),tostring(aa))
-- 		-- if(player.infraredCount("Assister") > 30) then 
-- 		-- 	return "Shoot"
-- 		-- end
-- 	end,
-- 	Assister = task.goCmuRush(defendPOs(4)),--task.touchKick(_,_,500,kick.flat);--task.getball("Assister",6,2),--task.GetBallV2("Assister",CGeoPoint(4500,0)),
-- 	Kicker = task.goCmuRush(defendPOs(5)),

-- 	match = "(AK)"
-- },
-- ["Shoot"] = {
-- 	switch = function()
-- 		-- Utils.UpdataTickMessage(vision,1,2)
-- 		-- Utils.GlobalComputingPos(vision)
-- 		if(player.kickBall("Assister")) then 
-- 			return "readyShoot"
-- 		end
-- 	end,
-- 	Assister = task.ShootdotV2(CGeoPoint(4500,0),KP,error_dir,kick.flat),

-- 	match = "[AKS]{TDG}"
-- },


name = "testSkill",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
