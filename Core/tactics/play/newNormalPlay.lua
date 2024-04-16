local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
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
-- 带球车初始化
dribbling_player_num = 1
-- 球权初始化
ballRights = -1
-- 射门坐标初始化
local shoot_pos = CGeoPoint:new_local(4500,0)
-- 守门员号码
local our_goalie_num = param.our_goalie_num
-- 后卫号码
local defend_num1 = param.defend_num1
local defend_num2 = param.defend_num2
-- 传球角度
local pass_pos = CGeoPoint:new_local(4500,-999)
-- getball参数
local playerVel = param.playerVel
local getballMode = param.getballMode
-- 带球速度
local dribblingVel = 2500
-- dribblingPos 带球目标坐标
local dribbling_target_pos = CGeoPoint:new_local(0,0)
local show_dribbling_pos = CGeoPoint:new_local(0,0)

local KickerRUNPos = CGeoPoint:new_local(0,0)
local SpecialRUNPos = CGeoPoint:new_local(0,0)

local canShoot = function(pos1,pos2)
    local pos_1 = CGeoPoint(pos1:x(),pos1:y())
    local pos_2 = CGeoPoint(pos2:x(),pos2:y())
    return Utils.isValidPass(vision,pos_1,pos_2,param.enemy_buffer)
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
        debugEngine:gui_debug_msg(CGeoPoint:new_local(-5700,num * 200),
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
        debugEngine:gui_debug_msg(CGeoPoint:new_local(-5700,num * -200), 
        tostring(i.num)         ..
        "  "                    .. 
        tostring(i.status),3)
    end
end

local runCount = 0
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
        param.shootPos = shoot_pos
    end


    runCount = runCount + 1
    if runCount > 60 then
        local KickerShootPos = Utils.PosGetShootPoint(vision, player.posX("Kicker"),player.posY("Kicker"))
        local SpecialShootPos = Utils.PosGetShootPoint(vision,player.posX("Special"),player.posY("Special"))

        if ball.posX() > -1000 then
            KickerRUNPos = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,CGeoPoint(1200,-2400),CGeoPoint(4200,0),300);
            SpecialRUNPos = Utils.GetAttackPos(vision, player.num("Special"),SpecialShootPos,CGeoPoint(1200,2400),CGeoPoint(4200,0),300);
        else
            KickerRUNPos = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,CGeoPoint(-500,2400),CGeoPoint(2200,0),300);
            SpecialRUNPos = Utils.GetAttackPos(vision, player.num("Special"),SpecialShootPos,CGeoPoint(-1900,0),CGeoPoint(1000,-2800),300);
        end
        -- if(canShoot(ball.pos(),player.pos("Kicker")) and canShoot(ball.pos(),KickerShootPos)) then
        --     KickerRUNPos = player.pos("Kicker")
        -- end
        -- if(canShoot(ball.pos(),player.pos("Special"))  and canShoot(ball.pos(),SpecialShootPos) ) then
        --     SpecialRUNPos = player.pos("Special")
        -- end
        runCount = 0
    end
    debugEngine:gui_debug_msg(CGeoPoint(0,3000),"ballVel:" .. ball.velMod())
    debugEngine:gui_debug_msg(CGeoPoint(0,2800),"InfraredCount:" .. player.infraredCount("Assister"))
    debugEngine:gui_debug_msg(CGeoPoint(0,2600),"Kick:" .. tostring(player.kickBall("Assister")))
    debugEngine:gui_debug_msg(CGeoPoint(0,2400),"DribblingPlayerNum:" .. dribbling_player_num .. "   DribblingStatus:" .. tostring(dribblingStatus))
    debugEngine:gui_debug_msg(CGeoPoint(0,2200),"ballRights:" .. ball_rights)
    debugEngine:gui_debug_msg(CGeoPoint(0,1800),"targetPos:" .. tostring(param.shootPos:x()) ..  "    " ..  tostring(param.shootPos:y()))
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
            resultState =  "dribbling"
        -- 如果是球在滚动过程、或在传球过程 [一接球、二跑位]
        else
            resultState =  "Getball"
        end
        debugEngine:gui_debug_msg(CGeoPoint(0,2000),"NextState:" .. resultState,3)
        return resultState
end

-- 解决 Getball 乱跳
local AssisterNumLast = 0
local NowAssisterNum = 0
local matchChangeCount = 0
local firstAssisterNum = 0
local Assisterkey = 0
local getBallRoleMatch = function(resState)
    NowAssisterNum = player.num("Assister")
    if Assisterkey == 0 then
        firstAssisterNum = NowAssisterNum
        Assisterkey = 1
    end
    if NowAssisterNum ~= AssisterNumLast then 
        matchChangeCount = matchChangeCount + 1
    end
    if matchChangeCount > 1 and firstAssisterNum ~=  NowAssisterNum then
        matchChangeCount = 0
        return resState
    end
    AssisterNumLast = NowAssisterNum
end
------------------------------------------------------------------------------------------------------------------------------------------------
local subScript = false

return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)

    end,
firstState = "Init",
["Init"] = {
    switch = function()
        if bufcnt(true,30) then 
            if not subScript then
                gSubPlay.new("ShootPoint", "shootPoint",{pos = function() return shoot_pos end})
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
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end ,closures_dir_ball("Special"),_,DSS_FLAG),
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
        return State
    end,
    Assister = gSubPlay.roleTask("ShootPoint", "Assister"),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
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
        if State ~= "Getball" then
            return State
        else
            State = getBallRoleMatch("GetballStatic")
            if State == "GetballStatic" then
                return State
            end
        end
    end,
    Assister = task.getball("Assister",playerVel,getballMode,ballPos()),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.goalie("Goalie"),
    match = "[AKS]{TDG}"
},

-- 接球（静态 保证脚本不会乱跳）
["GetballStatic"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        getState()
        if State ~= "Getball" then
            return State
        end

    end,
    Assister = task.getball("Assister",playerVel,getballMode,ballPos()),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.goalie("Goalie"),
    match = "{AKSTDG}"
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
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    -- Tier = task.defender_defence("Tier"),
    -- Defender = task.defender_defence("Defender"),
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
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    -- Tier = task.defender_defence("Tier"),
    -- Defender = task.defender_defence("Defender"),
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
