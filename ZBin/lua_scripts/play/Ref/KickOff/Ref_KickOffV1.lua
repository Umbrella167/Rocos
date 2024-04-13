local temp01 = CGeoPoint:new_local(-1000,1000)
local temp02 = CGeoPoint:new_local(-1000,-1000)
local temp03 = CGeoPoint:new_local(-1000,0)
local temp04 = CGeoPoint:new_local(-1500,500)
local theirgoal = CGeoPoint:new_local(4500,0)
local target = CGeoPoint:new_local(3000,2000)
local target2 = CGeoPoint:new_local(-2500,1500)
local target3 = CGeoPoint:new_local(0,0)
local p1 = CGeoPoint:new_local(-100,130)
local p2 = CGeoPoint:new_local(-250,-2000)
local p3 = CGeoPoint:new_local(-200,1500)
local p4 = CGeoPoint:new_local(-2200,100)
local p5 = CGeoPoint:new_local(-2200,-100)
local p6 = CGeoPoint:new_local(-3000,0)

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
local function runPos(role,touch_pos_flag)
	return function()
		local touch_pos_flag = touch_pos_flag or false
		for num,i in pairs(GlobalMessage.attackPlayerRunPos) do
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,-500 * num),i.num)
			if player.num(role) == i.num then
				if (touch_pos_flag == true and touchPos:x() ~= 0 and touchPos:y() ~= 0) then 
					return CGeoPoint:new_local(touchPos:x(),touchPos:y())
				else
				-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,-2000),i.pos:x().."  ".. i.pos:y())
					return CGeoPoint:new_local(i.pos:x(),i.pos:y())
				end
			end
		end
		return CGeoPoint:new_local(0,0)
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

-- 此脚本的全局更新
function UpdataTickMessage(defend_num1,defend_num2)
	-- 获取 Tick 信息
	GlobalMessage.Tick = Utils.UpdataTickMessage(vision,defend_num1,defend_num2)

	-- 获取全局状态，进攻状态为传统
	status.getGlobalStatus(0)  

	-- 带球机器人初始化
	dribbling_player_num = -1

	-- 获取球权
	ball_rights = GlobalMessage.Tick.ball.rights
	if ball_rights == 1 then
		dribbling_player_num = GlobalMessage.Tick.our.dribbling_num
		pass_player_num = GlobalMessage.Tick.task[dribbling_player_num].max_confidence_pass_num
		pass_pos = CGeoPoint:new_local(player.posX(pass_player_num),player.posY(pass_player_num))
		shoot_pos = GlobalMessage.Tick.task[dribbling_player_num].shoot_pos
		shoot_pos = CGeoPoint:new_local(shoot_pos:x(),shoot_pos:y())
		dribblingStatus = status.getPlayerStatus(dribbling_player_num)	-- 获取带球机器人状态
		status.getPlayerRunPos()	-- 获取跑位点
		touchPos = Utils.GetTouchPos(vision,CGeoPoint:new_local(player.posX(dribbling_player_num),player.posY(dribbling_player_num)),canTouchAngle)
	end
	debugStatus()
end
runPosKicker = CGeoPoint(0,0)
runPosSpecial = CGeoPoint(0,0)
shoot_pos = CGeoPoint(0,0)

gPlayTable.CreatePlay{
firstState = "ready",
["ready"] = {
	switch = function ()
		if cond.isNormalStart() then
			return "exit"
		elseif cond.isGameOn() then
		 	return "OtherRunPos"
		end
		Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
		--GetAttackPos(const CVisionModule *pVision,int num ,CGeoPoint shootPos,CGeoPoint startPoint,CGeoPoint endPoint,double step,double ballDist)
		shoot_pos = Utils.GetShootPoint(vision,player.num("Kicker"))
		runPosKicker = Utils.GetAttackPos(vision,player.num("Kicker"),shoot_pos,CGeoPoint(2000,0),CGeoPoint(4000,-2500),300)
		runPosSpecial = Utils.GetAttackPos(vision,player.num("Special"),runPosKicker,CGeoPoint(1200,2500),CGeoPoint(2500,800),300)
	end,
	Assister   = task.goCmuRush(p1, Dir_ball("Assister"), a, f, r, v),
	Special  = task.goCmuRush(p2, Dir_ball("Leader"), a, f, r, v),
	Kicker = task.goCmuRush(p3, Dir_ball("Kicker"), a, f, r, v),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie(),
    match = "[A][KS]{TDG}"
},


["OtherRunPos"] = {
	switch = function ()
		


	end,
	Assister   = task.goCmuRush(p1, Dir_ball("Assister"), a, f, r, v),
	Leader  = task.goCmuRush(p2, Dir_ball("Leader"), a, f, r, v),
	Kicker = task.goCmuRush(p3, Dir_ball("Kicker"), a, f, r, v),
	Tier = task.stop,
	Receiver   = task.stop,
	Goalie  = task.goalie(),
	match = "[ALK]{TR}"
},

name = "Ref_KickOffV1",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
