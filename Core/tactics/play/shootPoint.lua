
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

local shootPosFun = function()
	if type(param.shootPos) == "function" then
		return param.shootPos()
	else
		return param.shootPos
	end
end


local shoot_kp = param.shootKp
local resShootPos = CGeoPoint(4500,0)
local shootKPFun = function()
	return function()
		return shoot_kp
	end
end
local debugMesg = function ()
	if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
		debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),1)
	else
		debugEngine:gui_debug_line(player.pos("Assister"),player.pos("Assister") + Utils.Polar2Vector(9999,player.dir("Assister")),4)
	end
		debugEngine:gui_debug_x(resShootPos,6)

end
return {

firstState = "ready1",

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
        print(args.pos)
        shoot_pos = args.pos
    end,

["ready1"] = {
	switch = function()
		debugMesg()
		shoot_pos = shootPosFun()

		if(player.infraredCount("Assister") > 5) then
			return "shoot"
		end
	end,
	Assister = task.getball("Assister",param.playerVel,param.getballMode,CGeoPoint:new_local(0,0)),
	match = "[A]"
},

["shoot"] = {
	switch = function()
		-- if(not bufcnt(player.infraredOn("Assister"),1)) then
		-- 	return "ready1"
		-- end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
		debugMesg()
		if shootPosFun():x() == param.pitchLength / 2 then
			shoot_kp = 10000
		else
			shoot_kp = param.shootKp
		end
		local Vy = player.rotVel("Assister")
		local ToTargetDist = player.toPointDist("Assister",param.shootPos)
		resShootPos = task.compensateAngle("Assister",Vy,param.shootPos,ToTargetDist * 0.07)
		debugEngine:gui_debug_msg(CGeoPoint(0,-3000),shoot_kp)
		if(task.playerDirToPointDirSub("Assister",resShootPos) < param.shootError) then 
			return "shoot1"
		end

	end,
	Assister = function() return task.TurnToPointV2("Assister", function() return resShootPos end,param.rotVel) end,
	match = "{A}"
},

["shoot1"] = {
	switch = function()
		debugMesg()	
		if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
	end,
	Assister = task.ShootdotV2(function() return resShootPos end, shootKPFun() , param.shootError, kick.flat),
	match = "{A}"
},



name = "shootPoint",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}

