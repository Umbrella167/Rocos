
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end

gPlayTable.CreatePlay{

firstState = "readyShoot",
["readyShoot"] = {
	switch = function()
		-- Utils.UpdataTickMessage(vision,1,2)
		-- Utils.GlobalComputingPos(vision)
		if player.infraredCount("Assister") > 60 then
			return "Shoot"
		end
	end,
	Assister = task.GetBallV2("Assister",CGeoPoint(4500,0)),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "[AKS]{TDG}"
},
["Shoot"] = {
	switch = function()
		-- Utils.UpdataTickMessage(vision,1,2)
		-- Utils.GlobalComputingPos(vision)
		if(player.kickBall("Assister")) then 
			return "readyShoot"
		end
	end,
	Assister = task.ShootdotV2(CGeoPoint(4500,0),1.5,8,kick.flat),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "[AKS]{TDG}"
},



name = "testSkill",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
