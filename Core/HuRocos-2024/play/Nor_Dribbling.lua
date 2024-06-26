
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


local dribblingDir = function(role)
    return function()
        local playerPos = CGeoPoint(player.posX(role),player.posY(role))
        return  (playerPos - show_dribbling_pos):dir()
    end
end
local dribblingCount = 0
local dribblingVel = 1900
local canShootAngle = 30
local showPassPos = param.shootPos
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
		
		if(player.myinfraredCount("Assister") > 5) then
			return "dribbling"
		end
	end,
	Assister = task.getball(function() return shoot_pos end,playerVel,getballMode),
	match = "[A]"
},

-- 带球
["dribbling"] = {
    switch = function()
		dribblingCount = dribblingCount + 1
		
		if player.myinfraredOffCount("Assister") > 20 then
			return "getball"
		end
		
		local StartPos = CGeoPoint(player.posX("Assister"),player.posY("Assister"))
		local endPos = CGeoPoint(player.posX("Assister"),player.posY("Assister"))
		local dribbleLimitDist = GlobalMessage.Tick().ball.first_dribbling_pos:dist(player.pos("Assister"))
		-- showPassPos = Utils.GetAttackPos(vision,player.num("Assister"),param.shootPos,CGeoPoint(param.pitchLength / 2 * 0.9, param.pitchWidth / 2 * 0.85),CGeoPoint( 0 , -1 * param.pitchWidth / 2 * 0.85),300,200)
		if dribblingCount > 30 then
			show_dribbling_pos = Utils.GetShowDribblingPos(vision,CGeoPoint(player.posX("Assister"),player.posY("Assister")),showPassPos);
			dribblingCount = 0
		end
		local playerToBallDir = player.toBallDir("Assister")
		local playerToShootPosDir = (showPassPos - player.pos("Assister")):dir()
		local SubDir = math.abs(Utils.angleDiff(playerToBallDir,playerToShootPosDir) * 57.3)
		debugEngine:gui_debug_msg(CGeoPoint(0,-1200),"PlayerToShootPosAngle: "..SubDir,6)
		local inMyMouse = player.myinfraredCount("Assister") > 30 and true or false
		if  (inMyMouse and dribbleLimitDist > 800) or (Utils.isValidPass(vision,StartPos,showPassPos,param.enemy_buffer) and SubDir < canShootAngle) then
			-- return "shoot"
		end
		
    end,
    --dribbling_target_pos
    Assister = task.goCmuRush(function() return show_dribbling_pos end, dribblingDir("Assister"),dribblingVel,flag.dribbling),

    match = "[A]"
},
["shoot"] = {
	switch = function()
		 
		if(bufcnt(player.myinfraredCount("Assister") < 1,1)) then
			return "getball"
		end
	end,
	Assister = task.ShootdotDribbling(100, kick.flat),
	match = "[A]"
},

name = "Nor_Dribbling",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}

