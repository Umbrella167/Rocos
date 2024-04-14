local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
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
error_dir = 2
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
-- 守门员号码
our_goalie_num =0
-- 后卫号码
defend_num1 = 1
defend_num2 = 2
-- 射门Kp
shootKp = 1.5
-- Touch pos
touchPos = CGeoPoint:new_local(0,0)
-- Touch 角度
canTouchAngle = 60
-- 传球角度
pass_pos = CGeoPoint:new_local(4500,-999)
-- getball参数
playerVel = 4
getballMode = 1
-- 带球速度
dribblingVel = 2000

-- dribblingPos 带球目标坐标
dribbling_target_pos = CGeoPoint:new_local(0,0)
show_dribbling_pos = CGeoPoint:new_local(0,0)

local ShowDribblingPos = function ()
	return function()
		return CGeoPoint:new_local(show_dribbling_pos:x(),show_dribbling_pos:y())
	end
end
local dribblingDir = function(role)
	return function()
		local playerPos = CGeoPoint(player.posX(role),player.posY(role))
		return  (playerPos - show_dribbling_pos):dir()
	end
end

-- 此脚本的全局更新
local UpdataTickMessage = function (defend_num1,defend_num2)
	-- 获取 Tick 信息
	GlobalMessage.Tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(4500,-3000),GlobalMessage.Tick.our.player_num)
	-- 获取全局状态，进攻状态为传统
	status.getGlobalStatus(1)  
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
		dribbling_target_pos = shoot_pos
		dribblingStatus = status.getPlayerStatus(dribbling_player_num)	-- 获取带球机器人状态
		status.getPlayerRunPos()	-- 获取跑位点
		touchPos = Utils.GetTouchPos(vision,CGeoPoint:new_local(player.posX(dribbling_player_num),player.posY(dribbling_player_num)),canTouchAngle)
	end
	show_dribbling_pos = Utils.GetShowDribblingPos(vision,CGeoPoint(player.posX("Assister"),player.posY("Assister")),dribbling_target_pos);
	-- debugStatus()
end



gPlayTable.CreatePlay{

firstState = "Init",


["Init"] = {
	switch = function()
		return "GetGlobalMessage"
	end,
	Assister = task.stop(),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie("Goalie"),
	match = "[A][KS]{TDG}"
},

["GetGlobalMessage"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2) 	  -- 更新帧信息
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,200),tostring(GlobalMessage.Tick.our.goalie_num))
		-- status.debugStatus()
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,-2000),GlobalMessage.Tick.our.defend_num1)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,-2100),GlobalMessage.Tick.our.defend_num2,3)
		if task.ball_rights == 1 then	-- 我方球权的情况 获取进攻状态
			-- dribblingStatus -> [shoot,dribbling,XXpassToPlayerXX]
			if dribblingStatus == "NOTHING"  or dribblingStatus == "Run" or  dribblingStatus == "Getball" then
				UpdataTickMessage(defend_num1,defend_num2)
			else
				return dribblingStatus
			end
		elseif ball_rights == -1 then   	-- 敌方球权情况，一个抢球，其余防守
			return "defendNormalState"
		elseif ball_rights == 2 then   	--顶牛
			return "Dribbling"
		else	-- 未定义情况 一个抢球，其余跑位
			return "defendOtherState"
		end
		debugStatus()
	end,
	Assister = task.getball("Assister",playerVel,playerMod,ballPos()),
	--Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
	--Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie("Goalie"),
	match = "[A][KS]{TDG}"
},

-- 射门
["Shoot"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(not player.infraredOn("Assister")) then
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
	Assister = task.ShootdotV2(shootPos(),shootKp * 10,error_dir,kick.flat),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie("Goalie"),
	match = "(AKS){TDG}"
},


-- 射门
["KickerTouch"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(bufcnt(true,100))then 
			return "GetGlobalMessage"
		end

		if(GlobalMessage.Tick.ball.rights == -1)then 
			return "GetGlobalMessage"
		end
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,-3000),)
		if(player.kickBall("Kicker"))then 
			return "GetGlobalMessage"
		end
	end,
	Assister = task.goCmuRush(runPos("Assister"),closures_dir_ball("Assister"),_,DSS_FLAG),
	Kicker = task.touchKick(correctionPos(),_,touchPower,kick.flat),--task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker")),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{ASKTDG}"
},
["SpecialTouch"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(bufcnt(true,100))then 
			return "GetGlobalMessage"
		end
		if(GlobalMessage.Tick.ball.rights == -1)then 
			return "GetGlobalMessage"
		end
		if(player.kickBall("Special"))then 
			return "GetGlobalMessage"
		end
	end,
	Assister = task.goCmuRush(runPos("Assister"),closures_dir_ball("Assister"),_,DSS_FLAG),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.touchKick(correctionPos(),_,touchPower,kick.flat),--task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{ASKTDG}"
},
-- 传球 
["passToPlayer"] = {
	switch = function()
		-- UpdataTickMessage(defend_num1,defend_num2)
		if(player.kickBall("Assister")) then
			local getballPlayer = player.name(pass_player_num)
			debugEngine:gui_debug_msg(CGeoPoint:new_local(-4500,-3000),getballPlayer)
			-- 补丁： 修复传球给Goalie 或者 Defender
			if getballPlayer == "Kicker" or getballPlayer == "Special" then
				return getballPlayer .. "getBall" 
			else
				return "GetGlobalMessage"
			end
			
		end-- [0,1,2]

		-- 如果角度不正确 那么传入校正脚本
		if(task.playerDirToPointDirSub("Assister",shoot_pos) > error_dir and (GlobalMessage.Tick.ball.rights == 2 or GlobalMessage.Tick.ball.rights == 1)) then 
			correction_pos = pass_pos
			correction_state = "passToPlayer"
			debugEngine:gui_debug_msg(CGeoPoint:new_local(-4500,-3000),correction_state)
			return "Correction"
		end


		if (bufcnt(true,130)) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.ShootdotV2(passPos(),shootKp,error_dir,kick.flat),
	Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{AKSTDG}"
},

-- 接球
["KickergetBall"] = {
	switch = function()
		-- UpdataTickMessage(defend_num1,defend_num2)
		local tick = Utils.UpdataTickMessage(vision,our_goalie_num,defend_num1,defend_num2)

		-- 补丁：修复  传球后被敌方拦截傻等的情况
		if tick.ball.rights == -1 then
			return "GetGlobalMessage"
		end
		correction_pos = Utils.GetShootPoint(vision,player.num("Kicker"))
		if (player.canTouch("Kicker",correction_pos,canTouchAngle)) then
			return "KickerTouch"
		end
		if(player.toBallDist("Kicker") < 100) then 
			return "GetGlobalMessage"
		end
		if (bufcnt(true,130)) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.goCmuRush(runPos("Assister"),closures_dir_ball("Assister"),_,DSS_FLAG),
	Kicker =   task.getball("Kicker",playerVel,1,ballPos()),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{AKSTDG}"
},
["SpecialgetBall"] = {
	switch = function()

		UpdataTickMessage(defend_num1,defend_num2)
		correction_pos = Utils.GetShootPoint(vision,player.num("Special"))
		if (player.canTouch("Special",correction_pos,canTouchAngle)) then
			return "SpecialTouch"
		end
		if(player.toBallDist("Special") < 100) then 
			return "GetGlobalMessage"
		end
		if (bufcnt(true,100)) then
			return "GetGlobalMessage"
		end
	end,
	Assister = task.goCmuRush(runPos("Assister"),closures_dir_ball("Assister"),_,DSS_FLAG),
	Kicker = task.goCmuRush(runPos("Kicker"),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.getball("Special",playerVel,1,ballPos()),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{AKSTDG}"
},


-- 带球
["Dribbling"] = {
	switch = function()
		-- UpdataTickMessage(defend_num1,defend_num2)
		if bufcnt(true,30) then 
			return "GetGlobalMessage"
		end
	end,
	--dribbling_target_pos
	Assister = task.goCmuRush(ShowDribblingPos(), dribblingDir("Assister"),dribblingVel,flag.dribbling),
	Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{AKSTDG}"
},


-- 防守 - 顶牛
["defendOtherState"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(player.infraredOn("Assister")) then
			return "GetGlobalMessage"
		end
		if (bufcnt(true,50)) then
			return "GetGlobalMessage"
		end
		-- debugEngine:gui_debug_msg(passPos,dribblingStatus)
	end,
	Assister = task.getball("Assister",playerVel,playerMod,ballPos()),
	Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "(AKS){TDG}"
},

-- 防守 盯防
["defendNormalState"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
		if(player.infraredOn("Assister")) then
			return "GetGlobalMessage"
		end
		if (bufcnt(true,50)) then
			return "GetGlobalMessage"
		end
		-- debugEngine:gui_debug_msg(passPos,dribblingStatus)
	end,
	Assister = task.getball("Assister",playerVel,playerMod,ballPos()),
	Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "(AKS){TDG}"
},

-- 方向校正
["Correction"] = {
	switch = function()
		UpdataTickMessage(defend_num1,defend_num2)
        if(task.playerDirToPointDirSub("Assister",correction_pos) < error_dir and (GlobalMessage.Tick.ball.rights ~= 0 or GlobalMessage.Tick.ball.rights ~= 1)) then 
            return correction_state
        end
        local ballposlocal = CGeoPoint(ball.posX(),ball.posY())
        if (Utils.InExclusionZone(ballposlocal) or not Utils.InField(ballposlocal)) then
        	return "Dribbling"
        end
        if (GlobalMessage.Tick.ball.rights ~= 1) then
        	return "GetGlobalMessage"
        end
        if (bufcnt(true,40)) then
            return "GetGlobalMessage"
        end
	end,
	Assister = task.TurnToPointV2("Assister", correctionPos(),param.rotVel), --param.rotVel
	Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
	Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
	Tier = task.defender_defence("Tier"),
	Defender = task.defender_defence("Defender"),
	Goalie = task.goalie("Goalie"),
	match = "{AKSTDG}"
},

name = "OurNormalPlay",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
