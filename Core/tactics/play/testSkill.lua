
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end
shoot_pos = CGeoPoint:new_local(4500,0)
error_dir = 8
KP = 0.01
defendPOs = function(role)
	return function()
		local posdefend = enemy.pos(role) + Utils.Polar2Vector(300,(ball.pos() - enemy.pos(role)):dir())
		return CGeoPoint:new_local( posdefend:x(),posdefend:y() )
	end
end
run_pos = CGeoPoint:new_local(0,0)

runPos = function()
	return function()
		return CGeoPoint:new_local(run_pos:x(),run_pos:y())
	end
end
gPlayTable.CreatePlay{

firstState = "ready1",
["ready1"] = {
	switch = function()
		Utils.UpdataTickMessage(vision,2,4,1)
		Utils.GetAttackPos(vision,2 ,CGeoPoint(0,0),CGeoPoint(1000,2000),CGeoPoint(4000,-1900),350);
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.toBallDist("Assister"))
		if(player.infraredCount("Assister") > 5) then
			-- return "shoot"
		end
	end,
	 -- = task.TurnRun("Assister"),
	Assister = task.stop,--task.getball("Assister",4,1,CGeoPoint:new_local(0,0)),
	-- match = "[AKS]{TDG}"
	match = "[A]"
},


-- ["shoot"] = {
-- 	switch = function()
-- 		if(not bufcnt(player.infraredOn("Assister"),1)) then
-- 			return "ready1"
-- 		end
-- 		if(task.playerDirToPointDirSub("Assister",CGeoPoint:new_local(0,0)) < 4) then 
-- 			return "shoot32"
-- 		end
-- 	end,
-- 	 -- = task.TurnRun("Assister"),
-- 	Assister = task.TurnToPoint("Assister", CGeoPoint:new_local(0,0),800),
-- 	-- match = "[AKS]{TDG}"
-- 	match = "[A]"
-- },

["shoot"] = {
	switch = function()
		if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
		if(task.playerDirToPointDirSub("Assister",shoot_pos) < 4) then 
			return "shoot1"
		end
	end,
	 -- = task.TurnRun("Assister"),
	Assister = task.TurnToPointV2("Assister", shoot_pos,param.rotVel),
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
	Assister = task.ShootdotV2(shoot_pos,10,8,kick.flat),
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
