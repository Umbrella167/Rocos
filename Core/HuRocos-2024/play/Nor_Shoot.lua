
local ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
local balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end

local runPos = function()
	return function()
		return CGeoPoint:new_local(run_pos:x(),run_pos:y())
	end
end


local shoot_kp = param.shootKp
local resShootPos = CGeoPoint(param.pitchLength / 2,0)

local debugMesg = function ()
	if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
		debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),1)
	else
		debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),4)
	end
		debugEngine:gui_debug_msg(CGeoPoint(0,-2800),"ballRights: " .. GlobalMessage.Tick.ball.rights)
		if player.myinfraredCount("Assister") > 0 then
			debugEngine:gui_debug_msg(CGeoPoint(0,-2600),"myInfraredCount: " .. player.myinfraredCount("Assister").. "    InfraredCount: " .. player.infraredCount("Assister") .. "    InfraredOffCount:" .. player.myinfraredOffCount("Assister") ,2)
		end
		debugEngine:gui_debug_msg(CGeoPoint(0,-2400),"RawBallPos: " .. ball.rawPos():x() .. "    " .. ball.rawPos():y() ,3)
		debugEngine:gui_debug_msg(CGeoPoint(0,-2200),"BallPos: " .. ball.pos():x() .. "    " .. ball.pos():y() ,4)
		debugEngine:gui_debug_msg(CGeoPoint(0,-2000),"BallVel: " .. ball.velMod() ,4)
		debugEngine:gui_debug_msg(CGeoPoint(0,-1600),"BallValid: " .. tostring(ball.valid()) ,4)
		debugEngine:gui_debug_msg(CGeoPoint(0,-1400),"shoot_kp: " .. shoot_kp ,4)
		
		debugEngine:gui_debug_x(resShootPos,6)
		debugEngine:gui_debug_msg(resShootPos,"rotCompensatePos",6)
		debugEngine:gui_debug_x(param.shootPos,6)
		debugEngine:gui_debug_msg(param.shootPos,"ShootPos",6)

end
return {

firstState = "getball",

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
        print(args.pos)
        shoot_pos = args.pos
    end,





["getball"] = {
	switch = function()
		GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
		debugMesg()
		if(player.myinfraredCount("Assister") > 15) then
			return "turnToPoint"
		end
	end,
	Assister = task.getball(function() return shoot_pos end,param.playerVel,param.getballMode),
	match = "[A]"
},

["turnToPoint"] = {
	switch = function()
		GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
		-- if(not bufcnt(player.infraredOn("Assister"),1)) then
		-- 	return "ready1"
		-- end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
		debugMesg()
		if param.shootPos:x() == param.pitchLength / 2 then
			shoot_kp = 10000
		else
			shoot_kp = param.shootKp
		end

		if(bufcnt(player.myinfraredCount("Assister") < 1,4)) then
			return "getball"
		end
		local Vy = player.rotVel("Assister")
		local ToTargetDist = player.toPointDist("Assister",param.shootPos)
		resShootPos = task.compensateAngle("Assister",Vy,param.shootPos,ToTargetDist * param.rotCompensate)
		debugEngine:gui_debug_msg(CGeoPoint(0,-3000),shoot_kp)
		if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
			return "shoot"
		end

	end,
	Assister = function() return task.TurnToPointV2("Assister", function() return resShootPos end,param.rotVel) end,
	match = "{A}"
},

["shoot"] = {
	switch = function()
		GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
		debugMesg()	
		if(bufcnt(player.myinfraredCount("Assister") < 1,1)) then
			return "getball"
		end
	end,
	Assister = task.ShootdotV2(function() return resShootPos end,function() return shoot_kp end, param.shootError, kick.flat),
	match = "{A}"
},
	
["touch"] = {
	switch = function()

	end,
	Assister = task.touchKick(function() return resShootPos end, false, function() return shoot_kp end, kick.flat),
	match = "[A]"
},


name = "Nor_Shoot",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}

