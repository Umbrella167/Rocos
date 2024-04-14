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

runPosKicker = CGeoPoint(0,0)
runPosSpecial = CGeoPoint(0,0)
runPosAssister = CGeoPoint(0,0)
shootPosKicker = CGeoPoint(0,0)
shootPosAssister = CGeoPoint(0,0)
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
local leaderFlag = flag.dodge_ball
gPlayTable.CreatePlay{
firstState = "get",
["get"] = {
  switch = function()
    runPosSpecial = Utils.GetAttackPos(vision,player.num("Special"),CGeoPoint(0,0),CGeoPoint(-3200,1500),CGeoPoint(-200,-1200),380)
    runPosKicker = Utils.GetAttackPos(vision,player.num("Kicker"),runPosSpecial,CGeoPoint(-300,-700),CGeoPoint(2500,-2200),400)
    return "run"
  end,
  Assister = task.Shootdot("Assister",playerPos("Special"), shootKp, 10, kick.flat),
  Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker")),
  Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.goalie(),
  match = "[A][KS]{TDG}"
},

["run"] = {
  switch = function()
        if(player.kickBall("Assister")) then
            return "exit"
        end
  end,
  Assister = task.Shootdot("Assister",playerPos("Special"), shootKp, 10, kick.flat),
  Special = task.goCmuRush(runPos_Special(0),closures_dir_ball("Special")),
  Kicker = task.goCmuRush(runPos_Kicker(0),closures_dir_ball("Kicker")),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.goalie(),
  match = "[A][SK]{TDG}"
},

name = "Ref_BackKickV1",
applicable = {
  exp = "a",
  a   = true
},
attribute = "attack",
timeout = 99999
}