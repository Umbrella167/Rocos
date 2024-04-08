

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

dribbling_player_num = 1
ballRights = -1
shoot_pos = CGeoPoint:new_local(4500,-999)
pass_player_num = 0
function UpdataTickMessage(defend_num1,defend_num2)
	GlobalMessage.Tick = Utils.UpdataTickMessage(vision,defend_num1,defend_num2)
	dribbling_player_num = GlobalMessage.Tick.our.dribbling_num
	ball_rights = GlobalMessage.Tick.ball.rights
	if ball_rights == 1 then
		pass_player_num = GlobalMessage.Tick.task[dribbling_player_num].max_confidence_pass_num
		shoot_pos = GlobalMessage.Tick.task[dribbling_player_num].shoot_pos
		shoot_pos = CGeoPoint(shoot_pos:x(),shoot_pos:y())
	end
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
	Goalie = task.stop(),
	match = "[AKS]{TDG}"
},

["GetGlobalMessage"] = {
	switch = function()
		UpdataTickMessage(1,2) 	  -- 更新帧信息
		status.getGlobalStatus(0)  -- 获取全局状态，进攻状态为传统


		if task.ball_rights == 1 then	-- 我方球权的情况 获取进攻状态
		UpdataTickMessage(1,2)

			--dribblingStatus -> [shoot,dribbling,XXpassToPlayerXX]

			status.getPlayerRunPos()	-- 获取跑位点

			dribblingStatus = status.getPlayerStatus(dribbling_player_num)	-- 获取带球机器人状态
			debugEngine:gui_debug_msg(shoot_pos,pass_player_num)
			-- return dribblingStatus

		elseif ball_rights == -1 then   	-- 敌方球权情况，一个抢球，其余防守
			-- return "defendState"
		else 								-- 顶牛 或 为定义情况 一个抢球，其余跑位
			-- return "getballState"
		end
		debugStatus()
	end,
	Assister = task.stop(),--task.goCmuRush(closures_point(ball.pos()),closures_dir_ball("Assister"),_,flag.dribbling),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.goalie(),
	match = "[AKS]{TDG}"
},

["Shoot"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(task.shoot_pos,dribblingStatus)
	end,
	Assister = task.ShootdotV2(shootPos(),0.2,8,kick.flat),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "[AKS]{TDG}"
},

["passToPlayer"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(passPos,dribblingStatus)
	end,
	Assister = task.ShootdotV2(passPos(),0.2,8,kick.flat),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "[AKS]{TDG}"
},


name = "mytest",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
