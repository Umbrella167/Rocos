local DSS_FLAG = flag.allow_dss + flag.dodge_ball
local p1 = CGeoPoint(- param.pitchLength / 2 + 300,param.pitchWidth / 2 - 300)
local p2 = CGeoPoint(- param.pitchLength / 2 + 300,param.pitchWidth / 2 - 600)
local p3 = CGeoPoint(- param.pitchLength / 2 + 300, -param.pitchWidth / 2 + 300)
local p4 = CGeoPoint(- param.pitchLength / 2 + 300,-param.pitchWidth / 2 + 600)
local p5 = CGeoPoint(- param.pitchLength / 2 , 0)
local canShoot = function(role,shootThreshold)
	if ball.posX() > shootThreshold then
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
	if player.pos(role):dist(enemy.pos(theirGoalie())) < 500 then
		return kick.chip()
	else
		return kick.flat()
	end
end

local Power = function(role,shoot_flag,shootThreshold)
	local ipower = 100
	local ishoot_falg
	if type(shoot_flag) == 'function' then
		ishoot_falg = shoot_flag()
	else
		ishoot_falg = shoot_flag
	end
	local realRate = 15
	if param.isReality then
		realRate = 1
	end
	if ball.posX() > shootThreshold then
		if (ishoot_falg == kick.flat()) then
			ipower = 310 * realRate
		else
			ipower = 500 * realRate
		end 
	else
		if (ishoot_falg == kick.flat()) then
			ipower = 110 * realRate
		else
			ipower = 300 * realRate
		end 
	end
end

local match_pos = function(role)
	return function()
		return 
	end
end 
--射门阈值
local shootThreshold = 3000
gPlayTable.CreatePlay{
firstState = "Init1",

["Init1"] = {
	switch = function()
		return "Init"
	end,
	Assister = task.goCmuRush(function() return player.pos(param.LeaderNum) end, player.toBallDir("Assister"), a, DSS_FLAG),
    Kicker = task.goCmuRush(function() return player.pos(param.LeaderNum) end, 0, a, DSS_FLAG, r, v, s, force_manual),
    Special = task.goCmuRush(function() return player.pos(param.LeaderNum) end, 0, a, DSS_FLAG, r, v, s, force_manual),
    Tier = task.goCmuRush(p3, 0, a, DSS_FLAG, r, v, s, force_manual),
    Defender = task.goCmuRush(p4, 0, a, DSS_FLAG, r, v, s, force_manual),
    Goalie = task.goCmuRush(p5, 0, a, DSS_FLAG, r, v, s, force_manual),
    match = "[A][KS]{TDG}"
},



["Init"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		if cond.isNormalStart() then
			return "getball"
		end
	end,
	Assister = function() return task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-180,0) end, player.toBallDir("Assister"), a, DSS_FLAG) end,
    Kicker = task.goCmuRush(p1, 0, a, DSS_FLAG, r, v, s, force_manual),
    Special = task.goCmuRush(p2, 0, a, DSS_FLAG, r, v, s, force_manual),
    Tier = task.goCmuRush(p3, 0, a, DSS_FLAG, r, v, s, force_manual),
    Defender = task.goCmuRush(p4, 0, a, DSS_FLAG, r, v, s, force_manual),
    Goalie = task.goCmuRush(p5, 0, a, DSS_FLAG, r, v, s, force_manual),
    match = "{AKSTDG}"
},

["getball"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		if player.myinfraredCount("Assister") > 15 and (not canShoot("Assister",shootThreshold)) then
			return "shoot_dribbling"
		end
	end,
	Assister = task.getball(function() return shoot_pos end,playerVel,getballMode),
    match = "{A}"
},

["shoot_dribbling"] = {
	switch = function()
		shoot_flag = shootFlag("Assister")
		if(bufcnt(player.myinfraredCount("Assister") < 1,1)) then
			return "getball"
		end
	end,
	Assister = task.ShootdotDribbling(param.shootError,function() return shoot_flag end,Power("Assister",function() return shoot_flag end,shootThreshold)),
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
