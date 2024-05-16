local DSS_FLAG = flag.allow_dss + flag.dodge_ball
local p1 = CGeoPoint(- param.pitchLength / 2 + 300,param.pitchWidth / 2 - 300)
local p2 = CGeoPoint(- param.pitchLength / 2 + 300,param.pitchWidth / 2 - 600)
local p3 = CGeoPoint(- param.pitchLength / 2 + 300, -param.pitchWidth / 2 + 300)
local p4 = CGeoPoint(- param.pitchLength / 2 + 300,-param.pitchWidth / 2 + 600)
local p5 = CGeoPoint(- param.pitchLength / 2 , 0)
local shootThreshold = 2000

local canShoot = function(role,ishootThreshold)
	if ball.posX() > ishootThreshold then
		return true
	else
		return false
	end
end

local theirGoalie = function()
	for i=0,param.maxPlayer do
		if enemy.valid(i) then
			if enemy.pos(i):x() > ball.posX() then
				return i
			end
		end
	end
	return -1
end
local shoot_flag = 1
local shootFlag = function(role)
	print(player.pos(role):dist(enemy.pos(theirGoalie())))
	if player.pos(role):dist(enemy.pos(theirGoalie())) < 1000 then
		return kick.chip()
	else
		return kick.flat()
	end
end

local Power = function(role,shoot_flag,ishootThreshold)
	local ipower = 110
	local ishoot_falg
	if type(shoot_flag) == 'function' then
		ishoot_falg = shoot_flag()
	else
		ishoot_falg = shoot_flag
	end
	if ball.posX() > ishootThreshold then
		if (ishoot_falg == kick.chip()) then
			ipower = 3000
		end 
	else
		if (ishoot_falg == kick.chip()) then
			ipower = 3000
		end 
	end
	return ipower
end

--射门阈值
return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
firstState = "Init1",

["Init1"] = {
	switch = function()
		shoot_flag = shootFlag("Assister")
		gSubPlay.new("ShootPoint", "Nor_Shoot",{pos = function() return shoot_pos end})
		return "Init"
	end,
	Assister = task.goCmuRush(function() return player.pos(param.LeaderNum) end, player.toBallDir("Assister"), a, DSS_FLAG),
    Kicker = task.goCmuRush(function() return player.pos(param.LeaderNum) end, 0, a, DSS_FLAG, r, v, s, force_manual),
    Special = task.goCmuRush(function() return player.pos(param.LeaderNum) end, 0, a, DSS_FLAG, r, v, s, force_manual),
    Center = task.goCmuRush(p3, 0, a, DSS_FLAG, r, v, s, force_manual),
    Defender = task.goCmuRush(p4, 0, a, DSS_FLAG, r, v, s, force_manual),
    Goalie = task.goCmuRush(p5, 0, a, DSS_FLAG, r, v, s, force_manual),
    match = "[A][KSC]{DG}"
},


["Init"] = {
	switch = function()
		shoot_flag = shootFlag("Assister")
		param.shootPos = Utils.GetShootPoint(vision,player.num("Assister"))
		if cond.isNormalStart() then
			return "getball"
		end
		print(vision:gameState():gameOff())
	end,
	Assister = function() return task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-180,0) end, player.toBallDir("Assister"), a, DSS_FLAG) end,
    Kicker = task.goCmuRush(p1, 0, a, DSS_FLAG, r, v, s, force_manual),
    Special = task.goCmuRush(p2, 0, a, DSS_FLAG, r, v, s, force_manual),
    Center = task.goCmuRush(p3, 0, a, DSS_FLAG, r, v, s, force_manual),
    Defender = task.goCmuRush(p4, 0, a, DSS_FLAG, r, v, s, force_manual),
    Goalie = task.goCmuRush(p5, 0, a, DSS_FLAG, r, v, s, force_manual),
    match = "{AKSCDG}"

},

["getball"] = {
	switch = function()

		shoot_flag = shootFlag("Assister")
		param.shootPos = Utils.GetShootPoint(vision,player.num("Assister"))
		if player.myinfraredCount("Assister") > 5 then
			if shoot_flag == 2 then
				return "shoot_dribbling"
			else
				return "turnToPoint"
			end
		end
	end,
	Assister = task.getball_dribbling("Assister"),
    match = "{A}"
},
["turnToPoint"] = {
	switch = function()
		shoot_flag = shootFlag("Assister")
		if ball.posX() > shootThreshold then
			return "shoot_point"
		end
		if(bufcnt(player.myinfraredCount("Assister") < 1,4)) then
			return "getball"
		end
		local Vy = player.rotVel("Assister")
		local ToTargetDist = player.toPointDist("Assister",param.shootPos)
		if(task.playerDirToPointDirSub("Assister",param.shootPos) < param.shootError) then 
			if canShoot("Assister",shootThreshold) then
				return "shoot_point"
			else
				return "shoot_dribbling"
			end
		end
	end,
	Assister = function() return task.TurnToPointV2("Assister", function() return param.shootPos end,4) end,
	match = "{A}"
},
["shoot_dribbling"] = {
	switch = function()
		if ball.posX() > shootThreshold then
			return "shoot_point"
		end
		param.shootPos = Utils.GetShootPoint(vision,player.num("Assister"))
		shoot_flag = shootFlag("Assister")
		debugEngine:gui_debug_msg(CGeoPoint(0,0),shoot_flag)
		if player.myinfraredCount("Assister") < 1 then
			return "getball"
		end
	end,
	Assister = task.ShootdotDribbling(param.shootError + 10,function() return shoot_flag end ,function() return  Power("Assister",function() return shoot_flag end ,shootThreshold) end),
    match = "{A}"
},

["shoot_point"] = {
	switch = function()
		param.shootPos = Utils.GetShootPoint(vision,player.num("Assister"))
		shoot_flag = shootFlag("Assister")
		if(bufcnt(player.myinfraredCount("Assister") < 1,1)) then
			return "getball"
		end
	end,
	Assister = gSubPlay.roleTask("ShootPoint", "Assister"),
    match = "{A}"
},
name = "our_Penalty",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
