local debugStatus = function()
        for num,i in pairs(GlobalMessage.attackPlayerRunPos) do
                debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,num * 200),
                        tostring(GlobalMessage.attackPlayerRunPos[num].num)     ..
                        " "                                                                                             ..
                        "("                                                                                             .. 
                        tostring(GlobalMessage.attackPlayerRunPos[num].pos:x()) .. 
                        ","                                                                                                 ..
                        tostring(GlobalMessage.attackPlayerRunPos[num].pos:y()) ..
                        ")"
                ,6)
        end
        for num,i in pairs(GlobalMessage.attackPlayerStatus) do 
                debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,num * -200), 
                tostring(i.num)                 ..
                "  "                                    .. 
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
                dribblingStatus = status.getPlayerStatus(dribbling_player_num)  -- 获取带球机器人状态
                status.getPlayerRunPos()        -- 获取跑位点
                touchPos = Utils.GetTouchPos(vision,CGeoPoint:new_local(player.posX(dribbling_player_num),player.posY(dribbling_player_num)),canTouchAngle)
        end
        debugStatus()
end


local waitPos = CGeoPoint:new_local(3300,-1400)

local leaderPos = function()
	local ballPos = ball.pos()
	local targetDir = (ballPos - waitPos):dir()
	local target = ballPos + Utils.Polar2Vector(350,targetDir)
	return target
end
local leaderDir = function()
	local ballPos = ball.pos()
	local targetDir = (waitPos - ballPos):dir()
	return targetDir
end
local leaderFlag = flag.dodge_ball
gPlayTable.CreatePlay{
firstState = "get",
["get"] = {
  switch = function()
    UpdataTickMessage(defend_num1,defend_num2)

    if bufcnt(true,80) then 
        return "pass"
    end

  end,
  Assister = task.goCmuRush(leaderPos,leaderDir,_,leaderFlag),
  Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker")),
  Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.goalie(),
  match = "[A][KS]{TDG}"
},
["pass"] = {
  switch = function()
  	if player.kickBall("Assister") then
  		return "exit"
  	end
  end,
  Assister   = task.touchKick(runPos("Kicker",true),false,param.powerShoot,kick.flat),
  Kicker  = task.goCmuRush(waitPos),
  Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.goalie(),
  match = "{AKSTDG}"
},
name = "Ref_CenterKickV1",
applicable = {
  exp = "a",
  a   = true
},
attribute = "attack",
timeout = 99999
}