local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)

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
-- 角度误差常数
error_dir = 2
-- 带球车初始化
dribbling_player_num = 1
-- 球权初始化
ballRights = -1
-- 射门坐标初始化
shoot_pos = CGeoPoint:new_local(4500,0)
-- touch power
touchPower = 4000
-- 守门员号码
our_goalie_num = param.our_goalie_num
-- 后卫号码
local defend_num1 = param.defend_num1
local defend_num2 = param.defend_num2
-- 射门Kp
local shootKp = 1.5
-- Touch pos
local touchPos = CGeoPoint:new_local(0,0)
-- Touch 角度
local canTouchAngle = 60
-- 传球角度
local pass_pos = CGeoPoint:new_local(4500,-999)
-- getball参数
local playerVel = param.playerVel
local getballMode = param.getballMode

-- 带球速度
dribblingVel = 2000
-- dribblingPos 带球目标坐标
dribbling_target_pos = CGeoPoint:new_local(0,0)
show_dribbling_pos = CGeoPoint:new_local(0,0)

local canShoot = function(pos1,pos2)
    local pos_1 = CGeoPoint(pos1:x(),pos1:y())
    local pos_2 = CGeoPoint(pos2:x(),pos2:y())
    return Utils.isValidPass(vision,pos_1,pos_2,para.enemy_buffer)
end

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
local debugStatus = function()
    for num,i in pairs(GlobalMessage.attackPlayerRunPos) do
        debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,num * 200),
            tostring(GlobalMessage.attackPlayerRunPos[num].num)     ..
            " "                                                     ..
            "("                                                     .. 
            tostring(GlobalMessage.attackPlayerRunPos[num].pos:x()) .. 
            ","                                                     ..
            tostring(GlobalMessage.attackPlayerRunPos[num].pos:y()) ..
            ")"
        ,6)
    end
    for num,i in pairs(GlobalMessage.attackPlayerStatus) do 
        debugEngine:gui_debug_msg(CGeoPoint:new_local(-4400,num * -200), 
        tostring(i.num)         ..
        "  "                    .. 
        tostring(i.status),3)
    end
end
-- 此脚本的全局更新
local UpdataTickMessage = function (our_goalie_num,defend_num1,defend_num2)
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
        dribblingStatus = status.getPlayerStatus(dribbling_player_num)  -- 获取带球机器人状态
        shoot_pos = dribblingStatus == "Shoot" and shoot_pos or pass_pos
        status.getPlayerRunPos()    -- 获取跑位点
        touchPos = Utils.GetTouchPos(vision,CGeoPoint:new_local(player.posX(dribbling_player_num),player.posY(dribbling_player_num)),canTouchAngle)
    end
    debugEngine:gui_debug_msg(CGeoPoint(0,3000),"ballVel:" .. ball.velMod())
    debugEngine:gui_debug_msg(CGeoPoint(0,2800),"InfraredCount:" .. player.infraredCount("Assister"))
    debugEngine:gui_debug_msg(CGeoPoint(0,2600),"Kick:" .. tostring(player.kickBall("Assister")))
    debugEngine:gui_debug_msg(CGeoPoint(0,2400),"DribblingPlayerNum:" .. dribbling_player_num .. "   DribblingStatus:" .. tostring(dribblingStatus))
    debugEngine:gui_debug_msg(CGeoPoint(0,2200),"ballRights:" .. ball_rights)
    show_dribbling_pos = Utils.GetShowDribblingPos(vision,CGeoPoint(player.posX("Assister"),player.posY("Assister")),dribbling_target_pos);
    debugStatus()
end
local getState = function ()
        local resultState = "GetGlobalMessage"
        if task.ball_rights == 1 then   -- 我方球权的情况 获取进攻状态
            -- 防止为定义状态转跳
            if dribblingStatus == "NOTHING"  or dribblingStatus == "Run" or  dribblingStatus == "Getball" then
                UpdataTickMessage(defend_num1,defend_num2)
            else
                -- 如果状态是射门或者传球、 那么就返回ShootPoint
                if (dribblingStatus == "passToPlayer" or dribblingStatus == "Shoot") then
                    shoot_pos = dribblingStatus == "Shoot" and shoot_pos or pass_pos
                    resultState =  "ShootPoint"
                else
                    -- 否则一定是带球状态
                    resultState =  "dribbling"
                end
            end
        -- 如果球权是敌方的 [一抢球、二盯防]
        elseif ball_rights == -1 then
            resultState =  "defendNormalState"
        -- 如果是顶牛状态 [一带球、二跑位]
        elseif ball_rights == 2 then
            resultState =  "Getball"
        -- 如果是球在滚动过程、或在传球过程 [一接球、二跑位]
        else
            resultState =  "Getball"
        end
        debugEngine:gui_debug_msg(CGeoPoint(0,2000),"NextState:" .. resultState,3)
        return resultState
end

local subScript = false

return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
        start_pos = args.pos or CGeoPoint(0,0)
        dist = args.dist or 1000
        subScript = true
        PLAY_NAME = name
    end,
firstState = "Init",
["Init"] = {
    switch = function()
        if bufcnt(true,30) then 
            if not subScript then
                gSubPlay.new("ShootPoint", "shootPoint")
            end
                return "GetGlobalMessage"
        end
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
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        getState()
        return State
        
    end,
    Assister = task.getball("Assister",playerVel,getballMode,ballPos()),
    Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.goalie("Goalie"),
    match = "{AKSTDG}"
},


-- 射球
["ShootPoint"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        getState()
        -- return State
    end,
    Assister = gSubPlay.roleTask("ShootPoint", "Assister"),
    Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.goalie("Goalie"),
    match = "[A][KS]{TDG}"
},


-- 接球
["Getball"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        getState()
        return State
    end,
    Assister = task.getball("Assister",playerVel,getballMode,ballPos()),
    Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.goalie("Goalie"),
    match = "(AKS){TDG}"
},



-- 带球
["dribbling"] = {
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

-- 防守 盯防
["defendNormalState"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        getState()
        return State
    end,
    Assister = task.getball("Assister",playerVel,getballMode,ballPos()),
    Kicker = task.goCmuRush(runPos("Kicker",true),closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(runPos("Special"),closures_dir_ball("Special"),_,DSS_FLAG),
    Tier = task.defender_defence("Tier"),
    Defender = task.defender_defence("Defender"),
    Goalie = task.goalie("Goalie"),
    match = "(AKS){TDG}"
},
name = "newNormalPlay",
applicable ={
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}
