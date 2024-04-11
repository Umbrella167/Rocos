
ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
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
		Utils.GetTouchPos(vision,CGeoPoint:new_local(ball.posX(),ball.posY()))
		-- local pos1 = Utils.GetBestInterPos(vision,playerPos(),4,2)
		-- debugEngine:gui_debug_x(pos1,3)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),pos1:x() .. "  " .. pos1:y())
		-- Utils.UpdataTickMessage(vision,1,2)
		-- Utils.GlobalComputingPos(vision)
		-- aa = player.canTouch("Assister",CGeoPoint:new_local(4500,0))
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),tostring(aa))
		-- if(player.infraredCount("Assister") > 30) then 
		-- 	return "Shoot"
		-- end
	end,
	Assister = task.goCmuRush(defendPOs(4)),--task.touchKick(_,_,500,kick.flat);--task.getball("Assister",6,2),--task.GetBallV2("Assister",CGeoPoint(4500,0)),
	Kicker = task.goCmuRush(defendPOs(5)),

	match = "(AK)"
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
