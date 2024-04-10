
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end

playerPos = function ()
	return CGeoPoint:new_local( player.pos("Assister"):x(),player.pos("Assister"):y())
end
shoot_pos = CGeoPoint:new_local(4500,0)
error_dir = 8
KP = 0.01

gPlayTable.CreatePlay{

firstState = "readyShoot",


-- ["touch"] = {
-- 	switch = function()
-- 		-- Utils.UpdataTickMessage(vision,1,2)
-- 		-- Utils.GlobalComputingPos(vision)

-- 	end,
-- 	Assister = task.touchKick("Assister",CGeoPoint(4500,0)),

-- 	match = "[AKS]{TDG}"
-- },

["readyShoot"] = {
	switch = function()
		local pos1 = Utils.GetBestInterPos(vision,playerPos(),3,0)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),pos1:x() .. "  " .. pos1:y())
		-- Utils.UpdataTickMessage(vision,1,2)
		-- Utils.GlobalComputingPos(vision)
		-- player.canTouch("Assister",CGeoPoint:new_local(4500,0))

		-- if(player.infraredCount("Assister") > 30) then 
		-- 	return "Shoot"
		-- end
	end,
	Assister = task.stop(),--task.GetBallV2("Assister",CGeoPoint(4500,0)),

	match = "[AKS]{TDG}"
},
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
