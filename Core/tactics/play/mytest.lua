

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
local function runPos(role)
	return function()
		for num,i in pairs(GlobalMessage.attackPlayerRunPos) do
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,-500 * num),i.num)
			if player.num(role) == i.num then
				-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,-2000),i.pos:x().."  ".. i.pos:y())
				return CGeoPoint:new_local(i.pos:x(),i.pos:y())
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

-- 后卫号码
defend_num1 = 1
defend_num2 = 2

-- 射门Kp
shootKp = 0.0001

canTouchAngle = 60
pass_pos = CGeoPoint:new_local(4500,-999)
function UpdataTickMessage(defend_num1,defend_num2)
	GlobalMessage.Tick = Utils.UpdataTickMessage(vision,defend_num1,defend_num2)
	status.getGlobalStatus(0)  -- 获取全局状态，进攻状态为传统
	dribbling_player_num = -1
	ball_rights = GlobalMessage.Tick.ball.rights
	if ball_rights == 1 then
		dribbling_player_num = GlobalMessage.Tick.our.dribbling_num
		pass_player_num = GlobalMessage.Tick.task[dribbling_player_num].max_confidence_pass_num
		pass_pos = CGeoPoint:new_local(player.posX(pass_player_num),player.posY(pass_player_num))
		shoot_pos = GlobalMessage.Tick.task[dribbling_player_num].shoot_pos
		shoot_pos = CGeoPoint:new_local(shoot_pos:x(),shoot_pos:y())
		dribblingStatus = status.getPlayerStatus(dribbling_player_num)	-- 获取带球机器人状态
		status.getPlayerRunPos()	-- 获取跑位点
	end
	
	debugStatus()
end



gPlayTable.CreatePlay{

firstState = "Init",


["Init"] = {
	switch = function()
		
		if bufcnt(true,20) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.stop(),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "[A][KS]{TDG}"
},

["GetGlobalMessage"] = {
	switch = function()
		
		UpdataTickMessage(defend_num1,defend_num2) 	  -- 更新帧信息
		status.debugStatus()
		if task.ball_rights == 1 then	-- 我方球权的情况 获取进攻状态
		-- 	-- dribblingStatus -> [shoot,dribbling,XXpassToPlayerXX]
			
			debugEngine:gui_debug_msg(CGeoPoint(3000,2800),dribbling_player_num .. "   ".. dribblingStatus)
			if dribblingStatus == "NOTHING"  or dribblingStatus == "Run" or  dribblingStatus == "Getball" then
				UpdataTickMessage(defend_num1,defend_num2)
			else
				return dribblingStatus
			end

		elseif ball_rights == -1 then   	-- 敌方球权情况，一个抢球，其余防守
			return "defendNormalState"
		elseif ball_rights == 2 then								-- 顶牛 或 未定义情况 一个抢球，其余跑位
			return "defendOtherState"
		end
		runPos("Special")
		-- debugStatus()
	end,
	Assister = task.GetBallV2("Assister",ballPos()),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),

	-- Assister = task.stop(),
	-- Kicker = task.stop(),
	-- Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "[A][KS]{TDG}"
},

-- 射门
["Shoot"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(player.infraredCount("Assister") < 20) then
			return "defendOtherState"
		end
		if(task.playerDirToPointDirSub("Assister",shoot_pos) > error_dir) then 
			correction_pos = shoot_pos
			correction_state = "Shoot"
			return "Correction"
		end

		if(player.kickBall("Assister"))then 
			return "GetGlobalMessage"
		end
	end,
	Assister = task.ShootdotV2(shootPos(),shootKp,error_dir,kick.flat),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},

-- 射门
["Touch"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		-- if(bufcnt(true,300))then 
		-- 	return "GetGlobalMessage"
		-- end
		if(player.kickBall("Assister"))then 
			return "GetGlobalMessage"
		end
	end,
	Assister = task.touchKick(correctionPos(),_,500,kick.flat),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "[AKS]{TDG}"
},

-- 传球 
["passToPlayer"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(player.kickBall("Assister")) then
			local getballPlayer = player.name(pass_player_num)
			return getballPlayer .. "getBall" 
		end
		if(task.playerDirToPointDirSub("Assister",shoot_pos) > error_dir) then 
			correction_pos = pass_pos
			correction_state = "passToPlayer"
			return "Correction"
		end

	end,
	Assister = task.Shootdot(passPos(),shootKp,error_dir,kick.flat),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},

-- 接球
["KickergetBall"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		correction_pos = Utils.GetShootPoint(vision,player.num("Kicker"))
		if (player.canTouch("Kicker",correction_pos,canTouchAngle)) then
			return "Touch"
		end
		if(player.toBallDist("Kicker") < 100) then 
			return "GetGlobalMessage"
		end
		if (bufcnt(true,100)) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.goCmuRush(runPos("Assister"),closures_dir_ball("Assister")),
	Kicker = task.Getballv4("Kicker",runPos("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},
["SpecialgetBall"] = {
	switch = function()

		UpdataTickMessage(defend_num1,defend_num2)
		correction_pos = Utils.GetShootPoint(vision,player.num("Special"))
		if (player.canTouch("Special",correction_pos,canTouchAngle)) then
			return "Touch"
		end
		if(player.toBallDist("Special") < 100) then 
			return "GetGlobalMessage"
		end
		if (bufcnt(true,100)) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.goCmuRush(runPos("Assister"),closures_dir_ball("Assister")),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.Getballv4("Special",runPos("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},


-- 带球
["Dribbling"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		return "GetGlobalMessage"
	end,
	Assister = task.stop(),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},


-- 防守 - 顶牛
["defendOtherState"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(player.infraredCount("Assister") > 10) then
			return "GetGlobalMessage"
		end
		if (bufcnt(true,100)) then
			return "GetGlobalMessage"
		end
		-- debugEngine:gui_debug_msg(passPos,dribblingStatus)
	end,
	Assister = task.GetBallV2("Assister",CGeoPoint:new_local(0,0),8,3000),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},

-- 防守 盯防
["defendNormalState"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(player.infraredCount("Assister") > 10) then
			return "GetGlobalMessage"
		end
		if (bufcnt(true,100)) then
			return "GetGlobalMessage"
		end
		-- debugEngine:gui_debug_msg(passPos,dribblingStatus)
	end,
	Assister = task.GetBallV2("Assister",CGeoPoint:new_local(0,0),8,3000),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},


-- 方向校正
["Correction"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(task.playerDirToPointDirSub("Assister",correction_pos) < error_dir) then 
				return correction_state
		end
		if (bufcnt(true,100)) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.getball("Assister",4,1,correctionPos()),--task.GetBallV2("Assister",correctionPos()),

	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "{AKSTDG}"
},

name = "mytest",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
