
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

local resShootPos = CGeoPoint(param.pitchLength / 2,0)

local debugMesg = function ()
	if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
		debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),1)
	else
		debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),4)
	end
		debugEngine:gui_debug_msg(CGeoPoint(0,-2400),"RawBallPos: " .. ball.rawPos():x() .. "    " .. ball.rawPos():y() ,3,0,param.debugSize)
		debugEngine:gui_debug_msg(CGeoPoint(0,-2200),"BallPos: " .. GlobalMessage.Tick().ball.pos:x() .. "    " .. GlobalMessage.Tick().ball.pos:y() ,4,0,param.debugSize)
		debugEngine:gui_debug_msg(CGeoPoint(0,-2000),"BallVel: " .. ball.velMod() ,4,0,param.debugSize)
		debugEngine:gui_debug_msg(CGeoPoint(0,-1600),"BallValid: " .. tostring(ball.valid()) ,4,0,param.debugSize)
		
		debugEngine:gui_debug_x(resShootPos,6,0,param.debugSize)
		debugEngine:gui_debug_msg(resShootPos,"rotCompensatePos",6,0,param.debugSize)
		debugEngine:gui_debug_x(param.shootPos,6,0,param.debugSize)
		debugEngine:gui_debug_msg(param.shootPos,"ShootPos",6,0,param.debugSize)
end
return {

firstState = "Init",

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
        print(args.pos)
        shoot_pos = args.pos
    end,



["Init"] = {
	switch = function()
		if player.num("Assister") ~= -1 then
			return "getball"
		end
	end,
	Assister = task.getball_dribbling("Assister"),
	match = "[A]"
},


["getball"] = {
	switch = function()
		debugMesg()
		local toballDir = (param.shootPos - ball.pos()):dir()
		local playerDir = player.dir("Assister")
		local subDir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
		local drbblingRate = math.ceil((0 * Utils.NumberNormalize(subDir,120,30)))
		if(player.myinfraredCount("Assister") > 5 + drbblingRate) then
			return "turnToPoint"
		end
		local Vy = player.rotVel("Assister")
		local ToTargetDist = player.toPointDist("Assister",param.shootPos)
		resShootPos = task.compensateAngle("Assister",Vy,param.shootPos,ToTargetDist * param.rotCompensate(player.num("Assister")))
	end,
	Assister = task.getball(function() return shoot_pos end,param.playerVel,param.getballMode),
	match = "[A]"
},

["turnToPoint"] = {
	switch = function()
		--  
		-- if(not bufcnt(player.infraredOn("Assister"),1)) then
		-- 	return "ready1"
		-- end
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
		debugMesg()


		if(bufcnt(player.myinfraredCount("Assister") < 1,4)) then
			return "getball"
		end
		local Vy = player.rotVel("Assister")
		local ToTargetDist = player.toPointDist("Assister",param.shootPos)
		resShootPos = task.compensateAngle("Assister",Vy,param.shootPos,ToTargetDist * param.rotCompensate(player.num("Assister")))

		if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
			return "shoot"
		end

	end,
	Assister = function() return task.TurnToPointV2("Assister", function() return resShootPos end,param.rotVel(player.num("Assister"))) end,
	match = "{A}"
},

["shoot"] = {
	switch = function()
		--  
		debugMesg()	
		if(bufcnt(player.myinfraredCount("Assister") < 1,1)) then
			return "getball"
	end

		if(task.playerDirToPointDirSub("Assister",resShootPos) > param.shootError) then 
			return "getball"
		end
		
	end,
	Assister = task.ShootdotV2(function() return resShootPos end, param.shootError, kick.flat ),
	match = "{A}"
},
	
["touch"] = {
	switch = function()
		--  
	end,
	Assister = task.touch(),
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

