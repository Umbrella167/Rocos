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

local shootFlag = function(role)
	if player.pos(role):dist(enemy.pos(theirGoalie)) < 500 then
		
	end
end
gPlayTable.CreatePlay{
firstState = "Init",

["Init"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		if cond.isNormalStart() then
			return "Getball"
		end
	end,
	Leader = function() return task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-180,0) end, player.toBallDir("Leader"), a, DSS_FLAG) end,
    Kicker = task.goCmuRush(p1, 0, a, DSS_FLAG, r, v, s, force_manual),
    Special = task.goCmuRush(p2, 0, a, DSS_FLAG, r, v, s, force_manual),
    Tier = task.goCmuRush(p3, 0, a, DSS_FLAG, r, v, s, force_manual),
    Defender = task.goCmuRush(p4, 0, a, DSS_FLAG, r, v, s, force_manual),
    Goalie = task.goCmuRush(p5, 0, a, DSS_FLAG, r, v, s, force_manual),
    match = "{L}[KS]{TDG}"
},

["Getball"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		if player.myinfraredCount > 15 and (not canShoot) then
			return "shoot_dribbling"
		end
	end,
	Leader = task.getball(function() return shoot_pos end,playerVel,getballMode),
    match = "{L}"
},


["shoot_dribbling"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		if player.myinfraredCount > 15 and (not canShoot) then
			return "closeTheir"
		end
		
	end,
    match = "{L}"
},
name = "our_Penalty",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
