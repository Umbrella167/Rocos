
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end

gPlayTable.CreatePlay{

firstState = "test",
["test"] = {
	switch = function()
		-- Utils.UpdataTickMessage(vision,1,2)
		-- Utils.GlobalComputingPos(vision)
	end,
	Assister = task.goCmuRush(ball.pos),
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
