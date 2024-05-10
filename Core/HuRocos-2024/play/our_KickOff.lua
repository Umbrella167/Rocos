local temp01 = CGeoPoint:new_local(-1000,1000)
local temp02 = CGeoPoint:new_local(-1000,-1000)
local temp03 = CGeoPoint:new_local(-1000,0)
local temp04 = CGeoPoint:new_local(-1500,500)
local theirgoal = CGeoPoint:new_local(4500,0)
local target = CGeoPoint:new_local(3000,2000)
local target2 = CGeoPoint:new_local(-2500,1500)
local target3 = CGeoPoint:new_local(0,0)
local p1 = CGeoPoint:new_local(-120,-170)
local p2 = CGeoPoint:new_local(-250,-2000)
local p3 = CGeoPoint:new_local(-200,1500)
local p4 = CGeoPoint:new_local(-2200,100)
local p5 = CGeoPoint:new_local(-2200,-100)
local p6 = CGeoPoint:new_local(-3000,-800)
local p7 = CGeoPoint:new_local(-3000,800)
local Dir_ball = function(role)
	return function()
		return (ball.pos() - player.pos(role)):dir()
	end
end

local pos_self = function(role)
	return function()
		return player.pos(role)
	end
end
local pos_ = function(ppp)
	return function()
		return ppp
	end
end


local debugStatus = function()
	for num,i in pairs(GlobalMessage.attackPlayerRunPos) do
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,num * 200),
			tostring(GlobalMessage.attackPlayerRunPos[num].num)     ..
			" " 											        ..
			"(" 											        .. 
			tostring(GlobalMessage.attackPlayerRunPos[num].pos:x()) .. 
			"," 												    ..
			tostring(GlobalMessage.attackPlayerRunPos[num].pos:y()) ..
			")"
		,6)
	end
	for num,i in pairs(GlobalMessage.attackPlayerStatus) do 
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,num * -200), 
		tostring(i.num) 		..
		"  " 					.. 
		tostring(i.status),3)
	end
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,-2000),ball_rights)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4300,-2000),dribbling_player_num,3)
end

local closures_point = function(point)
	return function()
		return CGeoPoint:new_local(point:x(),point:y())
	end
end
local playerPos = function(role) 
	return function()
		return CGeoPoint:new_local(player.posX(role),player.posY(role))
	end
end
-- dir:pos1  ->  pos2
local closures_dir = function(pos1,pos2)
	return function()
		return (pos2 - pos1):dir()
	end
end

local closures_dir_ball = function(role)
    return function()
        return player.toBallDir(role)
    end
end

local ballPos = function()
	return function()
		return CGeoPoint:new_local(ball.pos():x(),ball.pos():y())
	end
end

local shootPos = function()
	return function()
		return shoot_pos
	end
end
local passPos = function()
	return function()
		return CGeoPoint:new_local(player.posX(pass_player_num),player.posY(pass_player_num))
	end
end
local function correctionPos()
	return function()
		return CGeoPoint:new_local(correction_pos:x(),correction_pos:y())
	end
end

-- 校正返回的脚本
correction_state = "Shoot"
-- 角度误差常数
error_dir = 4
-- 校正坐标初始化
correction_pos = CGeoPoint:new_local(0,0)
-- 带球车初始化
dribbling_player_num = 1
-- 球权初始化
ballRights = -1
-- 射门坐标初始化
shoot_pos = CGeoPoint:new_local(4500,0)
-- 被传球机器人
pass_player_num = 0

-- touch power
touchPower = 4000

-- 后卫号码
defend_num1 = 1
defend_num2 = 2

-- 射门Kp
shootKp = 0.0001
-- Touch pos
touchPos = CGeoPoint:new_local(0,0)
-- Touch 角度
canTouchAngle = 30

-- 传球角度
pass_pos = CGeoPoint:new_local(4500,-999)


runPosKicker = CGeoPoint(0,0)
runPosSpecial = CGeoPoint(0,0)
runPosAssister = CGeoPoint(0,0)
shootPosKicker = CGeoPoint(0,0)
shootPosAssister = CGeoPoint(0,0)

local UpdataTickMessage = function()
	Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
	--GetAttackPos(const CVisionModule *pVision,int num ,CGeoPoint shootPos,CGeoPoint startPoint,CGeoPoint endPoint,double step,double ballDist)
	shootPosKicker = Utils.GetShootPoint(vision,player.num("Kicker"))
	shootPosAssister = Utils.GetShootPoint(vision,player.num("Assister"))
	runPosAssister = Utils.GetAttackPos(vision,player.num("Assister"),shootPosAssister,CGeoPoint(3500,1350),CGeoPoint(4000,1000),300)
	runPosKicker = Utils.GetAttackPos(vision,player.num("Kicker"),shootPosKicker,CGeoPoint(1200,-100),CGeoPoint(1800,-800),300)
	runPosSpecial = Utils.GetAttackPos(vision,player.num("Special"),runPosKicker,CGeoPoint(500,2500),CGeoPoint(1000,1900),300)
end

local runPos_Assister = function(dist)
	return function()
		local new_pos = runPosAssister + Utils.Polar2Vector(dist,(ball.pos() - runPosAssister):dir())
		new_pos = CGeoPoint:new_local(new_pos:x(),new_pos:y())
		return new_pos
	end
end
local runPos_Kicker = function(dist)
	return function()
		local new_pos = runPosKicker + Utils.Polar2Vector(dist,(ball.pos() - runPosKicker):dir())
		new_pos = CGeoPoint:new_local(new_pos:x(),new_pos:y())
		return new_pos
	end
end
local runPos_Special = function(dist)
	return function()
		local new_pos = runPosSpecial + Utils.Polar2Vector(dist,(ball.pos() - runPosSpecial):dir())
		new_pos = CGeoPoint:new_local(new_pos:x(),new_pos:y())
		return new_pos
	end
end

local KickerShootPos = function()
	return function()
		return shootPosKicker
	end
end
local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
gPlayTable.CreatePlay{
firstState = "ready",
["ready"] = {
	switch = function ()
		UpdataTickMessage()
		if cond.isNormalStart() then
			return "OtherRunPos"
		elseif cond.isGameOn() then
		 	return "OtherRunPos"
		end
	end,
	Assister   = task.goCmuRush(p1, Dir_ball("Assister")),
	Special  = task.goCmuRush(p3, Dir_ball("Special")),
	Kicker = task.goCmuRush(p2, Dir_ball("Kicker")),
	Tier = task.goCmuRush(p7, Dir_ball("Tier")),
	Defender = task.goCmuRush(p6, Dir_ball("Defender")),
    Goalie = task.goalie("Goalie"),
    match = "[ASK]{TDG}"
},

["OtherRunPos"] = {
	switch = function ()
		local tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
		if tick.ball.rights == -1 then 
			return "exit"
		end

		if(player.kickBall("Assister")) then
			return "SpecialTouch"
		end
	end,
	Assister = task.Shootdot("Assister",runPos_Special(-400), shootKp, 5, kick.flat),
	Special = task.goCmuRush(runPos_Special(-400), Dir_ball("Special"), a, f, r, v),
	Kicker = task.goCmuRush(runPos_Kicker(-400), Dir_ball("Kicker"), a, f, r, v),
	-- Tier = task.Shootdot("Tier",playerPos("Special"), shootKp, 5, kick.flat),
	-- Defender = task.defender_defence("Defender"),
    Goalie = task.goalie("Goalie"),
	match = "{ASKTDG}"
},
["SpecialTouch"] = {
	switch = function ()
		local tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
		if tick.ball.rights == -1 then 
			return "exit"
		end
		if(player.kickBall("Special")) then
			return "KickerTouch"
		end
	end,
	Assister = task.goCmuRush(runPos_Assister(-400), Dir_ball("Assister"), a, DSS_FLAG, r, v),
	Special = task.touchKick(runPos_Kicker(0), false, param.shootKp, kick.flat),
	Kicker = task.goCmuRush(runPos_Kicker(-400), Dir_ball("Kicker"), a, f, r, v),
	-- Tier = task.defender_defence("Tier"),
	-- Defender = task.defender_defence("Defender"),
    Goalie = task.goalie("Goalie"),
	match = "{ASKTDG}"
},


["KickerTouch"] = {
	switch = function ()
		local tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
		if tick.ball.rights == -1 then 
			return "exit"
		end
		if(player.toBallDist("Kicker") < 300) then
			return "exit"
		end
	end,
	Assister = task.goCmuRush(runPos_Assister(-400), Dir_ball("Assister"), a, DSS_FLAG, r, v),
	Special = task.goCmuRush(runPos_Special(-400), Dir_ball("Special"), a, f, r, v),
	Kicker = task.getball(_, param.playerVel, param.getballMode, KickerShootPos()),
	-- Tier = task.defender_defence("Tier"),
	-- Defender = task.defender_defence("Defender"),
    Goalie = task.goalie("Goalie"),
	match = "{ASKTDG}"
},



["shoot"] = {
	switch = function ()
		local tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
		if tick.ball.rights == -1 then 
			return "exit"
		end
	end,
	Assister = task.goCmuRush(runPos_Assister(-400), Dir_ball("Assister"), a, DSS_FLAG, r, v),
	Special = task.goCmuRush(runPos_Special(-400), Dir_ball("Special"), a, f, r, v),
	Kicker = task.getball("Kicker", param.playerVel, param.getballMode, KickerShootPos()),
	-- Tier = task.defender_defence("Tier"),
	-- Defender = task.defender_defence("Defender"),
    Goalie = task.goalie("Goalie"),
	match = "{ASKTDG}"
},


name = "our_KickOff",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
