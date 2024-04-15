
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end

runPos = function()
	return function()
		return CGeoPoint:new_local(run_pos:x(),run_pos:y())
	end
end
local shoot_pos = CGeoPoint(0,0)
return {

firstState = "ready1",


["ready1"] = {
	switch = function()
		if(player.infraredCount("Assister") > 5) then
			return "shoot"
		end
	end,
	Assister = task.getball("Assister",param.playerVel,param.getballMode,CGeoPoint:new_local(0,0)),
	-- match = "[AKS]{TDG}"
	match = "[A]"
},

["shoot"] = {
	switch = function()
		if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
		if(task.playerDirToPointDirSub("Assister",shoot_pos) < 4) then 
			return "shoot1"
		end
	end,
	Assister = task.TurnToPointV2("Assister", shoot_pos,param.rotVel),
	match = "[A]"
},

["shoot1"] = {
	switch = function()
if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
	end,
	Assister = task.ShootdotV2(shoot_pos,10,8,kick.flat),
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


name = "shootPoint",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}

